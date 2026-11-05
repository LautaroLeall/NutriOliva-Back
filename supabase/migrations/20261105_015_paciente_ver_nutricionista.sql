-- =============================================================================
-- 20261105_015_paciente_ver_nutricionista.sql
-- Permite que un paciente autenticado pueda leer el perfil basico (id, nombre, email)
-- del nutricionista que lo atiende y sus propios datos clinicos por auth_user_id.
-- =============================================================================

-- 1. Permitir al paciente leer el perfil de su nutricionista asignado
DROP POLICY IF EXISTS "paciente_select_su_nutricionista_perfil" ON public.perfiles;
CREATE POLICY "paciente_select_su_nutricionista_perfil"
  ON public.perfiles
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT nutricionista_id
      FROM public.pacientes
      WHERE auth_user_id = auth.uid() OR perfil_id = auth.uid()
    )
  );

-- 2. Asegurar que datos_clinicos permita SELECT tanto por perfil_id como por auth_user_id
DROP POLICY IF EXISTS "datos_clinicos_select_paciente_auth" ON public.datos_clinicos;
CREATE POLICY "datos_clinicos_select_paciente_auth"
  ON public.datos_clinicos
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.pacientes p
      WHERE p.id = datos_clinicos.paciente_id
        AND (p.auth_user_id = auth.uid() OR p.perfil_id = auth.uid())
    )
  );
