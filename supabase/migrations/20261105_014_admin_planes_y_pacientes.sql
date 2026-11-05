-- =============================================================
-- NutriOliva — Migracion 014:
-- 1. Tabla planes_suscripcion editable por Super Admin (precios y cupos dinamicos)
-- 2. Columna cupo_extra en nutricionistas para ampliar cupo individual
-- 3. Policy RLS en pacientes para que superadmin pueda consultar y gestionar
--    el listado de pacientes y cupos (sin acceder a datos_clinicos)
-- 4. Recrear admin_nutricionistas_view vinculada a planes_suscripcion
-- =============================================================

-- 1. Crear tabla planes_suscripcion
CREATE TABLE IF NOT EXISTS public.planes_suscripcion (
  id                 TEXT PRIMARY KEY CHECK (id IN ('starter', 'pro', 'clinic')),
  nombre             TEXT NOT NULL,
  precio_mensual_ars INTEGER NOT NULL CHECK (precio_mensual_ars >= 0),
  cupo_pacientes     INTEGER NOT NULL CHECK (cupo_pacientes > 0),
  descripcion        TEXT,
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar valores iniciales si no existen
INSERT INTO public.planes_suscripcion (id, nombre, precio_mensual_ars, cupo_pacientes, descripcion)
VALUES
  ('starter', 'Starter', 75000,  15,   'Hasta 15 pacientes activos'),
  ('pro',     'Pro',     125000, 50,   'Hasta 50 pacientes activos'),
  ('clinic',  'Clinic',  150000, 9999, 'Pacientes ilimitados')
ON CONFLICT (id) DO NOTHING;

-- Activar RLS en planes_suscripcion
ALTER TABLE public.planes_suscripcion ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "planes_suscripcion_select" ON public.planes_suscripcion;
CREATE POLICY "planes_suscripcion_select"
  ON public.planes_suscripcion
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "planes_suscripcion_update_admin" ON public.planes_suscripcion;
CREATE POLICY "planes_suscripcion_update_admin"
  ON public.planes_suscripcion
  FOR UPDATE
  TO authenticated
  USING (public.get_user_rol() = 'superadmin')
  WITH CHECK (public.get_user_rol() = 'superadmin');

DROP POLICY IF EXISTS "planes_suscripcion_insert_admin" ON public.planes_suscripcion;
CREATE POLICY "planes_suscripcion_insert_admin"
  ON public.planes_suscripcion
  FOR INSERT
  TO authenticated
  WITH CHECK (public.get_user_rol() = 'superadmin');

-- 2. Agregar columna cupo_extra a nutricionistas (permite ajustar el cupo individual)
ALTER TABLE public.nutricionistas
  ADD COLUMN IF NOT EXISTS cupo_extra INTEGER NOT NULL DEFAULT 0;

-- 3. Permitir al superadmin leer y actualizar estado de pacientes (para conteo real y gestion de cupos)
-- Nota: datos_clinicos, planes y registros siguen 100% privados para nutricionista y paciente.
DROP POLICY IF EXISTS "superadmin_select_pacientes" ON public.pacientes;
CREATE POLICY "superadmin_select_pacientes"
  ON public.pacientes
  FOR SELECT
  TO authenticated
  USING (public.get_user_rol() = 'superadmin');

DROP POLICY IF EXISTS "superadmin_update_pacientes" ON public.pacientes;
CREATE POLICY "superadmin_update_pacientes"
  ON public.pacientes
  FOR UPDATE
  TO authenticated
  USING (public.get_user_rol() = 'superadmin')
  WITH CHECK (public.get_user_rol() = 'superadmin');

-- 4. Recrear vista admin_nutricionistas_view con precios y cupos dinamicos desde planes_suscripcion
DROP VIEW IF EXISTS public.admin_nutricionistas_view;

CREATE VIEW public.admin_nutricionistas_view
WITH (security_invoker = true)
AS
  SELECT
    n.id,
    p.nombre,
    p.email,
    p.created_at::DATE                                           AS fecha_alta,
    n.plan_suscripcion,
    n.estado,
    COUNT(pa.id) FILTER (WHERE pa.estado = 'activo')             AS total_pacientes,
    COALESCE(
      ps.precio_mensual_ars,
      CASE LOWER(n.plan_suscripcion)
        WHEN 'starter' THEN 75000
        WHEN 'pro'     THEN 125000
        WHEN 'clinic'  THEN 150000
        ELSE 75000
      END
    )                                                            AS precio_mensual_ars,
    COUNT(pa.id)                                                 AS total_pacientes_historico,
    COALESCE(n.cupo_extra, 0)                                    AS cupo_extra,
    COALESCE(ps.cupo_pacientes, 15) + COALESCE(n.cupo_extra, 0)  AS cupo_maximo
  FROM public.nutricionistas n
  JOIN public.perfiles p ON p.id = n.id
  LEFT JOIN public.planes_suscripcion ps ON ps.id = LOWER(n.plan_suscripcion)
  LEFT JOIN public.pacientes pa ON pa.nutricionista_id = n.id
  GROUP BY
    n.id,
    p.nombre,
    p.email,
    p.created_at,
    n.plan_suscripcion,
    n.estado,
    ps.precio_mensual_ars,
    ps.cupo_pacientes,
    n.cupo_extra;

REVOKE ALL ON public.admin_nutricionistas_view FROM anon, authenticated;
GRANT SELECT ON public.admin_nutricionistas_view TO authenticated;
