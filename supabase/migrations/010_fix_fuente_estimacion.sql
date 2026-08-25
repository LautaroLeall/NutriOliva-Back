-- Migración 010: fix CHECK constraint fuente_estimacion en registros_comida
-- El frontend envía 'plan' cuando la comida se carga desde el plan activo,
-- pero la BD solo aceptaba ('catalogo', 'ia', 'manual').

ALTER TABLE registros_comida
  DROP CONSTRAINT IF EXISTS registros_comida_fuente_estimacion_check;

ALTER TABLE registros_comida
  ADD CONSTRAINT registros_comida_fuente_estimacion_check
    CHECK (fuente_estimacion IN ('catalogo', 'plan', 'manual', 'ia'));
