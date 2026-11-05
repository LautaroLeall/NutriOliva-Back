-- =============================================================================
-- 20261105_016_superadmin_ia_metrics.sql
-- Permite al Super Admin consultar registros_comida para contabilizar el uso
-- y gasto estimado de IA por nutricionista y por paciente en el panel /admin.
-- =============================================================================

DROP POLICY IF EXISTS "superadmin_select_registros_comida" ON public.registros_comida;
CREATE POLICY "superadmin_select_registros_comida"
  ON public.registros_comida
  FOR SELECT
  TO authenticated
  USING (public.get_user_rol() = 'superadmin');
