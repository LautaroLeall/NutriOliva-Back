-- =============================================================
-- NutriOliva — Migración 009: Datos clínicos ampliados
-- + Fix CHECK constraint de comidas_plan
-- =============================================================

-- ── 1. Ampliar tabla datos_clinicos ──────────────────────────
ALTER TABLE datos_clinicos
  ADD COLUMN IF NOT EXISTS porcentaje_grasa  NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS masa_muscular_kg  NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS cintura_cm        NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS patologias        TEXT,
  ADD COLUMN IF NOT EXISTS alergias          TEXT,
  ADD COLUMN IF NOT EXISTS medicacion        TEXT,
  ADD COLUMN IF NOT EXISTS nivel_actividad   TEXT;

-- Validar nivel_actividad con CHECK en columna existente
ALTER TABLE datos_clinicos
  DROP CONSTRAINT IF EXISTS datos_clinicos_nivel_actividad_check;

ALTER TABLE datos_clinicos
  ADD CONSTRAINT datos_clinicos_nivel_actividad_check
  CHECK (nivel_actividad IN ('sedentario','leve','moderado','activo','muy_activo'));

-- Ampliar objetivo con más opciones
ALTER TABLE datos_clinicos
  DROP CONSTRAINT IF EXISTS datos_clinicos_objetivo_check;

ALTER TABLE datos_clinicos
  ADD CONSTRAINT datos_clinicos_objetivo_check
  CHECK (objetivo IN (
    'bajar',
    'bajar_fuerza',
    'mantener',
    'subir',
    'subir_fuerza',
    'rendimiento_deportivo',
    'recomposicion'
  ));

-- ── 2. Vista: último dato clínico por paciente (con IMC) ─────
-- security_invoker=true → la vista respeta las RLS del usuario consultante,
-- no las del creador. Requerido por el linter de seguridad de Supabase.
DROP VIEW IF EXISTS ultimo_dato_clinico;

CREATE VIEW ultimo_dato_clinico
  WITH (security_invoker = true)
AS
SELECT DISTINCT ON (paciente_id)
  id,
  paciente_id,
  peso,
  altura,
  edad,
  sexo,
  objetivo,
  nivel_actividad,
  porcentaje_grasa,
  masa_muscular_kg,
  cintura_cm,
  patologias,
  alergias,
  medicacion,
  observaciones,
  fecha_registro,
  created_at,
  CASE
    WHEN peso IS NOT NULL AND altura IS NOT NULL AND altura > 0
    THEN ROUND(peso / ((altura / 100.0) ^ 2), 2)
    ELSE NULL
  END AS imc
FROM datos_clinicos
ORDER BY paciente_id, fecha_registro DESC, created_at DESC;

-- ── 3. Fix CHECK constraint de comidas_plan ───────────────────
-- El CHECK original solo tenía: desayuno, almuerzo, merienda, cena, snack
-- Necesita incluir: colacion y colacion_nocturna (ya se usan en el frontend)

-- Primero eliminar el constraint existente
ALTER TABLE comidas_plan
  DROP CONSTRAINT IF EXISTS comidas_plan_tipo_comida_check;

-- Recrear con todos los tipos soportados
ALTER TABLE comidas_plan
  ADD CONSTRAINT comidas_plan_tipo_comida_check
  CHECK (tipo_comida IN (
    'desayuno',
    'colacion',
    'almuerzo',
    'merienda',
    'cena',
    'snack',
    'colacion_nocturna'
  ));

-- ── 4. RLS para datos_clinicos ────────────────────────────────
ALTER TABLE datos_clinicos ENABLE ROW LEVEL SECURITY;

-- El nutricionista puede ver y modificar los datos clínicos de sus pacientes
DROP POLICY IF EXISTS "nutricionista_ve_datos_clinicos" ON datos_clinicos;
CREATE POLICY "nutricionista_ve_datos_clinicos" ON datos_clinicos
  FOR ALL
  TO authenticated
  USING (
    paciente_id IN (
      SELECT id FROM pacientes
      WHERE nutricionista_id = auth.uid()
    )
  );

-- El paciente puede ver sus propios datos clínicos
DROP POLICY IF EXISTS "paciente_ve_sus_datos_clinicos" ON datos_clinicos;
CREATE POLICY "paciente_ve_sus_datos_clinicos" ON datos_clinicos
  FOR SELECT
  TO authenticated
  USING (
    paciente_id IN (
      SELECT id FROM pacientes
      WHERE perfil_id = auth.uid()
    )
  );

-- ── 5. Índice para performance ────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_datos_clinicos_paciente_fecha
  ON datos_clinicos(paciente_id, fecha_registro DESC);
