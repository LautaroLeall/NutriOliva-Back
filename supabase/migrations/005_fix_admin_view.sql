-- =============================================================
-- NutriOliva — Migración 005: Fix vista superadmin
-- Corrige los dos warnings de seguridad de admin_nutricionistas_view:
--   1. "Exposed Auth Users" — eliminar JOIN con auth.users
--   2. "Security Definer View" — agregar security_invoker = true
-- =============================================================

-- ── Paso 1: Agregar columna email a perfiles ─────────────────
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS email TEXT;

-- ── Paso 2: Actualizar el trigger para guardar el email ──────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO perfiles (id, rol, nombre, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'rol', 'paciente'),
    COALESCE(NEW.raw_user_meta_data->>'nombre', SPLIT_PART(NEW.email, '@', 1)),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Paso 3: Eliminar la vista problemática ───────────────────
DROP VIEW IF EXISTS admin_nutricionistas_view;

-- ── Paso 4: Recrear la vista SIN auth.users y con security_invoker ──
-- security_invoker = true → la vista respeta el RLS del usuario que consulta
CREATE VIEW admin_nutricionistas_view
WITH (security_invoker = true)
AS
  SELECT
    n.id,
    p.nombre,
    p.email,
    p.created_at::DATE       AS fecha_alta,
    n.plan_suscripcion,
    n.estado,
    COUNT(pa.id)             AS total_pacientes,
    CASE n.plan_suscripcion
      WHEN 'starter' THEN 75000
      WHEN 'pro'     THEN 125000
      WHEN 'clinic'  THEN 150000
    END                      AS precio_mensual_ars
  FROM nutricionistas n
  JOIN perfiles p ON p.id = n.id
  LEFT JOIN pacientes pa
    ON pa.nutricionista_id = n.id
   AND pa.estado = 'activo'
  GROUP BY n.id, p.nombre, p.email, p.created_at, n.plan_suscripcion, n.estado;

-- ── Paso 5: Revocar acceso anónimo a la vista ────────────────
REVOKE ALL ON admin_nutricionistas_view FROM anon, authenticated;
GRANT SELECT ON admin_nutricionistas_view TO authenticated;
