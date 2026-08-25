-- ============================================================
-- Storage 001 — Buckets privados para fotos de comidas y actividad
-- NutriOliva — 2026
-- Ejecutar en Supabase Dashboard → SQL Editor
-- ============================================================

-- ── Crear buckets PRIVADOS ──────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('fotos-comidas',   'fotos-comidas',   FALSE, 5242880,  -- 5 MB máx
    ARRAY['image/jpeg','image/png','image/webp','image/heic']),
  ('fotos-actividad', 'fotos-actividad', FALSE, 5242880,
    ARRAY['image/jpeg','image/png','image/webp','image/heic'])
ON CONFLICT (id) DO NOTHING;

-- ── Políticas de fotos-comidas ──────────────────────────────────────────────

-- Paciente puede subir sus propias fotos (ruta: pacienteId/timestamp.ext)
DROP POLICY IF EXISTS "paciente sube foto comida" ON storage.objects;
CREATE POLICY "paciente sube foto comida"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'fotos-comidas'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

-- Paciente puede ver sus propias fotos
DROP POLICY IF EXISTS "paciente ve sus fotos comida" ON storage.objects;
CREATE POLICY "paciente ve sus fotos comida"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'fotos-comidas'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

-- Nutricionista puede ver fotos de sus pacientes
DROP POLICY IF EXISTS "nutricionista ve fotos comida pacientes" ON storage.objects;
CREATE POLICY "nutricionista ve fotos comida pacientes"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'fotos-comidas'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

-- Paciente puede eliminar sus propias fotos
DROP POLICY IF EXISTS "paciente elimina foto comida" ON storage.objects;
CREATE POLICY "paciente elimina foto comida"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'fotos-comidas'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

-- ── Políticas de fotos-actividad ────────────────────────────────────────────

DROP POLICY IF EXISTS "paciente sube foto actividad" ON storage.objects;
CREATE POLICY "paciente sube foto actividad"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'fotos-actividad'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "paciente ve sus fotos actividad" ON storage.objects;
CREATE POLICY "paciente ve sus fotos actividad"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'fotos-actividad'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "nutricionista ve fotos actividad pacientes" ON storage.objects;
CREATE POLICY "nutricionista ve fotos actividad pacientes"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'fotos-actividad'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE nutricionista_id = get_nutricionista_id()
    )
  );

DROP POLICY IF EXISTS "paciente elimina foto actividad" ON storage.objects;
CREATE POLICY "paciente elimina foto actividad"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'fotos-actividad'
    AND (storage.foldername(name))[1] IN (
      SELECT id::TEXT FROM pacientes WHERE auth_user_id = auth.uid()
    )
  );

-- ── Nota importante sobre URLs firmadas ────────────────────────────────────
-- Los buckets son PRIVADOS. Para mostrar imágenes usar siempre:
--   supabase.storage.from('fotos-comidas').createSignedUrl(path, 3600)
-- El cliente React genera las URLs firmadas con la sesión autenticada del usuario.
-- Duración recomendada: 3600 segundos (1 hora). Renovar al montar el componente.
