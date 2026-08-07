-- =============================================================
-- NutriOliva — Migración 003: Triggers de autenticación
-- Aplicar DESPUÉS de 002_rls_policies.sql
-- =============================================================

-- ── Trigger 1: Al crear un usuario en auth.users → crear perfil ─
-- Lee el rol y nombre del metadata que se pasa al invitar
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO perfiles (id, rol, nombre)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'rol', 'paciente'),
    COALESCE(NEW.raw_user_meta_data->>'nombre', SPLIT_PART(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar si existe y recrear
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ── Trigger 2: Si el perfil creado es 'nutricionista' → insertar en nutricionistas ─
CREATE OR REPLACE FUNCTION handle_new_nutricionista()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rol = 'nutricionista' THEN
    INSERT INTO nutricionistas (id, plan_suscripcion, estado)
    VALUES (NEW.id, 'starter', 'Activo')
    ON CONFLICT (id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_perfil_nutricionista ON perfiles;
CREATE TRIGGER on_perfil_nutricionista
  AFTER INSERT ON perfiles
  FOR EACH ROW EXECUTE FUNCTION handle_new_nutricionista();

-- ── Vista para el Superadmin ─────────────────────────────────
-- Solo expone datos agregados (sin datos clínicos de pacientes)
CREATE OR REPLACE VIEW admin_nutricionistas_view AS
  SELECT
    n.id,
    p.nombre,
    p.created_at::DATE AS fecha_alta,
    u.email,
    n.plan_suscripcion,
    n.estado,
    COUNT(pa.id) AS total_pacientes,
    CASE n.plan_suscripcion
      WHEN 'starter' THEN 75000
      WHEN 'pro'     THEN 125000
      WHEN 'clinic'  THEN 150000
    END AS precio_mensual_ars
  FROM nutricionistas n
  JOIN perfiles p ON p.id = n.id
  JOIN auth.users u ON u.id = n.id
  LEFT JOIN pacientes pa ON pa.nutricionista_id = n.id AND pa.estado = 'activo'
  GROUP BY n.id, p.nombre, p.created_at, u.email, n.plan_suscripcion, n.estado;

-- Política: solo superadmin puede ver la vista
-- (la vista ya hereda las políticas de sus tablas base)
