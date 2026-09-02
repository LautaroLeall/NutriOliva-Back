-- =============================================================
-- NutriOliva — Migración 012: Trigger para vincular auth_user_id
-- al paciente cuando acepta la invitacion y define su contraseña.
-- =============================================================

-- Trigger: cuando un usuario de tipo 'paciente' actualiza su
-- contraseña por primera vez (confirmed_at pasa de NULL a valor),
-- busca el registro de paciente con ese email y vincula el auth_user_id.

CREATE OR REPLACE FUNCTION handle_patient_confirmed()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo actuar cuando confirmed_at pasa de NULL a un valor
  IF OLD.confirmed_at IS NULL AND NEW.confirmed_at IS NOT NULL THEN
    UPDATE pacientes
    SET auth_user_id = NEW.id
    WHERE email = NEW.email
      AND auth_user_id IS NULL;

    -- Asegurar que el perfil tiene rol = 'paciente'
    UPDATE perfiles
    SET rol = 'paciente'
    WHERE id = NEW.id
      AND rol IS DISTINCT FROM 'paciente';

    RAISE LOG '[handle_patient_confirmed] Paciente confirmado: % (%)', NEW.email, NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

DROP TRIGGER IF EXISTS on_patient_confirmed ON auth.users;
CREATE TRIGGER on_patient_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_patient_confirmed();
