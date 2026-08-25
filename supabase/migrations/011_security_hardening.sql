-- =============================================================
-- NutriOliva — Migracion 011: Hardening de seguridad
-- Resuelve todos los warnings del linter de Supabase:
--   - function_search_path_mutable                        (5 funciones)
--   - anon_security_definer_function_executable           (5 funciones)
--   - authenticated_security_definer_function_executable  (5 funciones)
-- =============================================================

-- ── 1. Funciones helper internas ─────────────────────────────
-- get_user_rol, get_nutricionista_id, get_paciente_id
-- Usadas internamente por las politicas RLS (no via REST API).
-- Fix:
--   a) SET search_path = '' → evita inyeccion de search_path
--   b) REVOKE EXECUTE FROM anon, public → no accesibles via /rest/v1/rpc
--   c) Nombres completamente calificados (public.tabla)
-- Mantienen SECURITY DEFINER porque las politicas RLS las necesitan.

CREATE OR REPLACE FUNCTION public.get_user_rol()
RETURNS TEXT
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT rol FROM public.perfiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_nutricionista_id()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT id FROM public.nutricionistas WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.get_paciente_id()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT id FROM public.pacientes WHERE perfil_id = auth.uid();
$$;

-- Revocar acceso REST directo (solo llamadas internas de RLS)
REVOKE EXECUTE ON FUNCTION public.get_user_rol()         FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_nutricionista_id() FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_paciente_id()      FROM anon, public;

-- Las politicas RLS las necesitan como authenticated
GRANT EXECUTE ON FUNCTION public.get_user_rol()         TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_nutricionista_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_paciente_id()      TO authenticated;

-- ── 2. Funciones de trigger ───────────────────────────────────
-- handle_new_user y handle_new_nutricionista son funciones de trigger.
-- Solo deben ser llamadas por el motor de triggers, NUNCA via REST.
-- Fix:
--   a) SET search_path = '' + nombres calificados
--   b) REVOKE EXECUTE FROM anon, authenticated, public

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.perfiles (id, rol, nombre)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'rol', 'paciente'),
    COALESCE(NEW.raw_user_meta_data->>'nombre', SPLIT_PART(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_nutricionista()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.rol = 'nutricionista' THEN
    INSERT INTO public.nutricionistas (id, plan_suscripcion, estado)
    VALUES (NEW.id, 'starter', 'Activo')
    ON CONFLICT (id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

-- Revocar acceso REST (funciones de trigger, no llamar directamente)
REVOKE EXECUTE ON FUNCTION public.handle_new_user()          FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.handle_new_nutricionista() FROM anon, authenticated, public;

-- ── 3. NOTA: Leaked Password Protection ──────────────────────
-- Se activa desde el Dashboard de Supabase:
-- Auth > Settings > Password Security > Enable Leaked Password Protection
-- No requiere SQL.
