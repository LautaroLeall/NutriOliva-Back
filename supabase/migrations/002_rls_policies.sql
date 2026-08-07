-- =============================================================
-- NutriOliva — Migración 002: Row Level Security
-- Aplicar DESPUÉS de 001_schema_base.sql
-- =============================================================

-- ── Activar RLS en todas las tablas ─────────────────────────
ALTER TABLE perfiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutricionistas       ENABLE ROW LEVEL SECURITY;
ALTER TABLE pacientes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE datos_clinicos       ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes               ENABLE ROW LEVEL SECURITY;
ALTER TABLE comidas_plan         ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalogo_alimentos   ENABLE ROW LEVEL SECURITY;
ALTER TABLE registros_comida     ENABLE ROW LEVEL SECURITY;
ALTER TABLE registros_actividad  ENABLE ROW LEVEL SECURITY;

-- ── Funciones helper (SECURITY DEFINER = sin RLS) ──────────

CREATE OR REPLACE FUNCTION get_user_rol()
RETURNS TEXT AS $$
  SELECT rol FROM perfiles WHERE id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_nutricionista_id()
RETURNS UUID AS $$
  SELECT id FROM nutricionistas WHERE id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_paciente_id()
RETURNS UUID AS $$
  SELECT id FROM pacientes WHERE perfil_id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ── PERFILES ────────────────────────────────────────────────
-- Cada usuario ve solo el suyo; superadmin ve todos
CREATE POLICY "perfiles_select" ON perfiles
  FOR SELECT USING (
    id = auth.uid()
    OR get_user_rol() = 'superadmin'
  );

CREATE POLICY "perfiles_insert" ON perfiles
  FOR INSERT WITH CHECK (
    id = auth.uid()
    OR get_user_rol() = 'superadmin'
  );

CREATE POLICY "perfiles_update" ON perfiles
  FOR UPDATE USING (
    id = auth.uid()
    OR get_user_rol() = 'superadmin'
  );

-- ── NUTRICIONISTAS ──────────────────────────────────────────
-- Superadmin ve y edita todos; nutricionista solo el suyo
CREATE POLICY "nutricionistas_select" ON nutricionistas
  FOR SELECT USING (
    id = auth.uid()
    OR get_user_rol() = 'superadmin'
  );

CREATE POLICY "nutricionistas_update" ON nutricionistas
  FOR UPDATE USING (
    get_user_rol() = 'superadmin'
  );

CREATE POLICY "nutricionistas_insert" ON nutricionistas
  FOR INSERT WITH CHECK (
    get_user_rol() = 'superadmin'
  );

-- ── PACIENTES ───────────────────────────────────────────────
-- Nutricionista: solo los suyos | Paciente: solo el suyo
-- Superadmin: SOLO cuenta — no ve datos clínicos
CREATE POLICY "pacientes_select" ON pacientes
  FOR SELECT USING (
    nutricionista_id = get_nutricionista_id()
    OR perfil_id = auth.uid()
  );

CREATE POLICY "pacientes_insert" ON pacientes
  FOR INSERT WITH CHECK (
    nutricionista_id = get_nutricionista_id()
  );

CREATE POLICY "pacientes_update" ON pacientes
  FOR UPDATE USING (
    nutricionista_id = get_nutricionista_id()
  );

CREATE POLICY "pacientes_delete" ON pacientes
  FOR DELETE USING (
    nutricionista_id = get_nutricionista_id()
  );

-- ── DATOS CLÍNICOS ──────────────────────────────────────────
-- Solo el nutricionista del paciente y el propio paciente
CREATE POLICY "datos_clinicos_select" ON datos_clinicos
  FOR SELECT USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
    OR paciente_id = get_paciente_id()
  );

CREATE POLICY "datos_clinicos_insert" ON datos_clinicos
  FOR INSERT WITH CHECK (
    paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

CREATE POLICY "datos_clinicos_update" ON datos_clinicos
  FOR UPDATE USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

-- ── PLANES ──────────────────────────────────────────────────
-- Nutricionista gestiona; paciente solo lee
CREATE POLICY "planes_select" ON planes
  FOR SELECT USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
    OR paciente_id = get_paciente_id()
  );

CREATE POLICY "planes_insert" ON planes
  FOR INSERT WITH CHECK (
    paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

CREATE POLICY "planes_update" ON planes
  FOR UPDATE USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

CREATE POLICY "planes_delete" ON planes
  FOR DELETE USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

-- ── COMIDAS DEL PLAN ────────────────────────────────────────
CREATE POLICY "comidas_plan_select" ON comidas_plan
  FOR SELECT USING (
    plan_id IN (
      SELECT p.id FROM planes p
      JOIN pacientes pa ON pa.id = p.paciente_id
      WHERE pa.nutricionista_id = get_nutricionista_id()
         OR pa.perfil_id = auth.uid()
    )
  );

CREATE POLICY "comidas_plan_insert" ON comidas_plan
  FOR INSERT WITH CHECK (
    plan_id IN (
      SELECT p.id FROM planes p
      JOIN pacientes pa ON pa.id = p.paciente_id
      WHERE pa.nutricionista_id = get_nutricionista_id()
    )
  );

CREATE POLICY "comidas_plan_update" ON comidas_plan
  FOR UPDATE USING (
    plan_id IN (
      SELECT p.id FROM planes p
      JOIN pacientes pa ON pa.id = p.paciente_id
      WHERE pa.nutricionista_id = get_nutricionista_id()
    )
  );

CREATE POLICY "comidas_plan_delete" ON comidas_plan
  FOR DELETE USING (
    plan_id IN (
      SELECT p.id FROM planes p
      JOIN pacientes pa ON pa.id = p.paciente_id
      WHERE pa.nutricionista_id = get_nutricionista_id()
    )
  );

-- ── CATÁLOGO DE ALIMENTOS ────────────────────────────────────
-- Global (nutricionista_id NULL) visible para todos los nutricionistas
-- El propio catálogo es gestionado solo por su nutricionista
CREATE POLICY "catalogo_select" ON catalogo_alimentos
  FOR SELECT USING (
    nutricionista_id IS NULL
    OR nutricionista_id = get_nutricionista_id()
  );

CREATE POLICY "catalogo_insert" ON catalogo_alimentos
  FOR INSERT WITH CHECK (
    nutricionista_id = get_nutricionista_id()
  );

CREATE POLICY "catalogo_update" ON catalogo_alimentos
  FOR UPDATE USING (
    nutricionista_id = get_nutricionista_id()
  );

CREATE POLICY "catalogo_delete" ON catalogo_alimentos
  FOR DELETE USING (
    nutricionista_id = get_nutricionista_id()
  );

-- ── REGISTROS DE COMIDA ──────────────────────────────────────
-- Paciente: CRUD propio | Nutricionista: solo lectura de sus pacientes
CREATE POLICY "reg_comida_select" ON registros_comida
  FOR SELECT USING (
    paciente_id = get_paciente_id()
    OR paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

CREATE POLICY "reg_comida_insert" ON registros_comida
  FOR INSERT WITH CHECK (
    paciente_id = get_paciente_id()
  );

CREATE POLICY "reg_comida_update" ON registros_comida
  FOR UPDATE USING (
    paciente_id = get_paciente_id()
  );

CREATE POLICY "reg_comida_delete" ON registros_comida
  FOR DELETE USING (
    paciente_id = get_paciente_id()
  );

-- ── REGISTROS DE ACTIVIDAD ───────────────────────────────────
CREATE POLICY "reg_actividad_select" ON registros_actividad
  FOR SELECT USING (
    paciente_id = get_paciente_id()
    OR paciente_id IN (
      SELECT id FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

CREATE POLICY "reg_actividad_insert" ON registros_actividad
  FOR INSERT WITH CHECK (
    paciente_id = get_paciente_id()
  );

CREATE POLICY "reg_actividad_update" ON registros_actividad
  FOR UPDATE USING (
    paciente_id = get_paciente_id()
  );

CREATE POLICY "reg_actividad_delete" ON registros_actividad
  FOR DELETE USING (
    paciente_id = get_paciente_id()
  );
