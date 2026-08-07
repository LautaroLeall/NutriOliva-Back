-- =============================================================
-- NutriOliva — Migración 001: Schema base
-- Ejecutar en Supabase SQL Editor o via CLI
-- =============================================================

-- ── Tabla de perfiles (extiende auth.users) ────────────────
CREATE TABLE IF NOT EXISTS perfiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  rol         TEXT NOT NULL CHECK (rol IN ('superadmin', 'nutricionista', 'paciente')),
  nombre      TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tabla de nutricionistas ─────────────────────────────────
CREATE TABLE IF NOT EXISTS nutricionistas (
  id                UUID PRIMARY KEY REFERENCES perfiles(id) ON DELETE CASCADE,
  plan_suscripcion  TEXT NOT NULL
                    CHECK (plan_suscripcion IN ('starter', 'pro', 'clinic'))
                    DEFAULT 'starter',
  estado            TEXT NOT NULL
                    CHECK (estado IN ('Activo', 'Pago pendiente', 'Inactivo'))
                    DEFAULT 'Activo',
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── Tabla de pacientes ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS pacientes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nutricionista_id  UUID NOT NULL REFERENCES nutricionistas(id) ON DELETE CASCADE,
  perfil_id         UUID REFERENCES perfiles(id) ON DELETE SET NULL,
  nombre            TEXT NOT NULL,
  email             TEXT NOT NULL,
  telefono          TEXT,
  fecha_nacimiento  DATE,
  estado            TEXT NOT NULL
                    CHECK (estado IN ('activo', 'inactivo'))
                    DEFAULT 'activo',
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── Datos clínicos (historial acumulativo, no sobreescribir) ─
CREATE TABLE IF NOT EXISTS datos_clinicos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id     UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  peso            NUMERIC(5,2),
  altura          NUMERIC(5,2),
  edad            INTEGER,
  sexo            TEXT CHECK (sexo IN ('M', 'F', 'otro')),
  objetivo        TEXT CHECK (objetivo IN ('bajar', 'mantener', 'subir')),
  observaciones   TEXT,
  fecha_registro  DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Planes alimenticios (versionados por paciente) ──────────
CREATE TABLE IF NOT EXISTS planes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id       UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  calorias_objetivo INTEGER NOT NULL DEFAULT 2000,
  version           INTEGER NOT NULL DEFAULT 1,
  estado            TEXT NOT NULL
                    CHECK (estado IN ('borrador', 'activo', 'archivado'))
                    DEFAULT 'borrador',
  notas             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── Comidas dentro de un plan ───────────────────────────────
CREATE TABLE IF NOT EXISTS comidas_plan (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id         UUID NOT NULL REFERENCES planes(id) ON DELETE CASCADE,
  tipo_comida     TEXT NOT NULL
                  CHECK (tipo_comida IN ('desayuno','almuerzo','merienda','cena','snack')),
  descripcion     TEXT NOT NULL,
  calorias_aprox  INTEGER,
  proteinas_g     NUMERIC(6,2),
  carbos_g        NUMERIC(6,2),
  grasas_g        NUMERIC(6,2),
  orden           INTEGER DEFAULT 0
);

-- ── Catálogo de alimentos por nutricionista ─────────────────
-- nutricionista_id NULL = catálogo global compartido
CREATE TABLE IF NOT EXISTS catalogo_alimentos (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nutricionista_id    UUID REFERENCES nutricionistas(id) ON DELETE CASCADE,
  nombre              TEXT NOT NULL,
  calorias_por_unidad INTEGER NOT NULL,
  unidad              TEXT DEFAULT '100g',
  proteinas_g         NUMERIC(6,2),
  carbos_g            NUMERIC(6,2),
  grasas_g            NUMERIC(6,2)
);

-- ── Registros de comidas del paciente ───────────────────────
CREATE TABLE IF NOT EXISTS registros_comida (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id         UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  fecha               DATE NOT NULL DEFAULT CURRENT_DATE,
  hora                TIME NOT NULL DEFAULT CURRENT_TIME,
  descripcion         TEXT NOT NULL,
  foto_url            TEXT,
  calorias_estimadas  INTEGER,
  fuente_estimacion   TEXT CHECK (fuente_estimacion IN ('catalogo', 'ia', 'manual')),
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ── Registros de actividad física ───────────────────────────
CREATE TABLE IF NOT EXISTS registros_actividad (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paciente_id       UUID NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
  fecha             DATE NOT NULL DEFAULT CURRENT_DATE,
  hora              TIME NOT NULL DEFAULT CURRENT_TIME,
  tipo              TEXT NOT NULL,
  duracion_min      INTEGER NOT NULL,
  intensidad        TEXT CHECK (intensidad IN ('baja','media','alta')) DEFAULT 'media',
  calorias_gastadas INTEGER,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── Índices para performance ─────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pacientes_nutricionista
  ON pacientes(nutricionista_id);

CREATE INDEX IF NOT EXISTS idx_registros_comida_paciente_fecha
  ON registros_comida(paciente_id, fecha);

CREATE INDEX IF NOT EXISTS idx_registros_actividad_paciente_fecha
  ON registros_actividad(paciente_id, fecha);

CREATE INDEX IF NOT EXISTS idx_planes_paciente
  ON planes(paciente_id);

CREATE INDEX IF NOT EXISTS idx_comidas_plan_plan
  ON comidas_plan(plan_id);

CREATE INDEX IF NOT EXISTS idx_catalogo_nutricionista
  ON catalogo_alimentos(nutricionista_id);
