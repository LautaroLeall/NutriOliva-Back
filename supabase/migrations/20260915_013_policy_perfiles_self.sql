-- =============================================================
-- NutriOliva — Migration 013: Policy RLS para que cada usuario vea su propio perfil
-- =============================================================
-- El error 401 en perfiles se produce porque useAuth.jsx hace:
--   supabase.from('perfiles').select('rol, nombre').eq('id', userId)
-- pero no existe una policy que permita a CUALQUIER usuario autenticado
-- leer su PROPIA fila en perfiles (incluido el superadmin).
-- =============================================================

-- Eliminar si ya existe (para poder recrear sin error)
DROP POLICY IF EXISTS "usuario ve su propio perfil" ON public.perfiles;

-- Crear la policy: cada usuario autenticado puede ver su propia fila
CREATE POLICY "usuario ve su propio perfil"
  ON public.perfiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- =============================================================
-- Verificar que la policy se creo correctamente
-- =============================================================
SELECT policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'perfiles'
ORDER BY policyname;
