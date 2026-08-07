-- =============================================================
-- NutriOliva — Migración 006: auth_user_id en pacientes
-- Permite que el paciente encuentre su propio registro en la DB
-- usando su session.user.id de Supabase Auth.
-- =============================================================

-- ── Paso 1: Agregar la columna ───────────────────────────────
ALTER TABLE pacientes
  ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- ── Paso 2: Índice para búsqueda rápida ──────────────────────
CREATE INDEX IF NOT EXISTS idx_pacientes_auth_user_id
  ON pacientes (auth_user_id);

-- ── Paso 3: RLS pacientes ────────────────────────────────────
DROP POLICY IF EXISTS "paciente_can_read_own" ON pacientes;
CREATE POLICY "paciente_can_read_own"
  ON pacientes FOR SELECT
  USING (auth_user_id = auth.uid());

-- ── Paso 4: RLS registros_comida ─────────────────────────────
DROP POLICY IF EXISTS "paciente_insert_comida" ON registros_comida;
CREATE POLICY "paciente_insert_comida"
  ON registros_comida FOR INSERT
  WITH CHECK (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "paciente_read_comida" ON registros_comida;
CREATE POLICY "paciente_read_comida"
  ON registros_comida FOR SELECT
  USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "paciente_update_comida" ON registros_comida;
CREATE POLICY "paciente_update_comida"
  ON registros_comida FOR UPDATE
  USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "paciente_delete_comida" ON registros_comida;
CREATE POLICY "paciente_delete_comida"
  ON registros_comida FOR DELETE
  USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

-- ── Paso 5: RLS registros_actividad ──────────────────────────
DROP POLICY IF EXISTS "paciente_insert_actividad" ON registros_actividad;
CREATE POLICY "paciente_insert_actividad"
  ON registros_actividad FOR INSERT
  WITH CHECK (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "paciente_read_actividad" ON registros_actividad;
CREATE POLICY "paciente_read_actividad"
  ON registros_actividad FOR SELECT
  USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "paciente_delete_actividad" ON registros_actividad;
CREATE POLICY "paciente_delete_actividad"
  ON registros_actividad FOR DELETE
  USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

-- ── Paso 6: RLS planes y comidas_plan ────────────────────────
DROP POLICY IF EXISTS "paciente_read_plan" ON planes;
CREATE POLICY "paciente_read_plan"
  ON planes FOR SELECT
  USING (
    paciente_id IN (
      SELECT id FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "paciente_read_comidas_plan" ON comidas_plan;
CREATE POLICY "paciente_read_comidas_plan"
  ON comidas_plan FOR SELECT
  USING (
    plan_id IN (
      SELECT p.id FROM planes p
      JOIN pacientes pa ON pa.id = p.paciente_id
      WHERE pa.auth_user_id = auth.uid()
    )
  );
