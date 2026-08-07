# NutriOliva — Backend & Base de Datos

Repositorio de base de datos PostgreSQL, migraciones de datos, políticas de seguridad (RLS) y Edge Functions de Supabase.

## Descripcion General

El backend de NutriOliva está construido sobre la infraestructura de **Supabase**, aprovechando PostgreSQL como motor relacional, Supabase Auth para la gestión de identidades y Row Level Security (RLS) para garantizar el aislamiento estricto de datos entre nutricionistas y sus pacientes.

## Informacion del Proyecto Supabase

| Propiedad          | Detalle                                    |
| ------------------ | ------------------------------------------ |
| Proyecto           | NutriOliva-BaseDatos                       |
| URL del Proyecto   | `https://cvrgckctgtgcpdtjzxjp.supabase.co` |
| Region             | South America (São Paulo)                  |
| Repositorio GitHub | `NutriOliva-Back`                          |

## Estructura del Repositorio

```text
Backend/
└── supabase/
    ├── functions/               # Supabase Edge Functions (Deno / TypeScript)
    │   ├── estimate-calories/   # Estimacion de calorias e info nutricional
    │   ├── invite-patient/      # Envio de invitaciones por correo
    │   └── parse-pdf/           # Extraccion automatica de planes desde PDF
    └── migrations/              # Migraciones de estructura y seguridad SQL
        ├── 001_schema_base.sql         # Tablas principales e indices
        ├── 002_rls_policies.sql        # Politicas Row Level Security para aislamiento multi-tenant
        ├── 003_triggers.sql            # Triggers automaticos para usuarios y perfiles
        ├── 004_seed_catalogo.sql       # Catalogo base de alimentos y actividades
        ├── 005_fix_admin_view.sql      # Vistas administrativas y correccion de accesos
        └── 006_patient_auth_link.sql   # Vinculacion auth_user_id en pacientes y RLS de paciente
```

## Modelo de Datos y Tablas

- **`perfiles`**: Información de usuario extendida ligada a `auth.users` (rol: `superadmin`, `nutricionista`, `paciente`).
- **`pacientes`**: Registro clínico y datos personales gestionados por el nutricionista. Contiene la columna `auth_user_id` para permitir acceso al paciente.
- **`planes`**: Cabecera de planes alimenticios creados por el nutricionista con estado de versión (`activo`, `inactivo`).
- **`plan_comidas`**: Detalle de cada comida y macronutrientes incluidos dentro de un plan.
- **`catalogo_alimentos`**: Catálogo global y personalizado de alimentos con información nutricional por porción.
- **`registros`**: Entradas diarias del paciente (comidas consumidas y actividad física realizada).
- **`datos_clinicos`**: Mediciones antropométricas e historial clínico del paciente.

## Seguridad y Row Level Security (RLS)

Todas las tablas cuentan con **Row Level Security (RLS)** activado.

### Reglas Principales de Acceso:

1. **Nutricionistas**: Solo pueden consultar, insertar, modificar o eliminar registros pertenecientes a los pacientes vinculados a su ID (`nutricionista_id = auth.uid()`).
2. **Pacientes**: Solo pueden consultar sus propios datos clínicos, su plan activo y administrar sus registros diarios mediante la relación `auth_user_id = auth.uid()`.
3. **Catálogo de Alimentos**: Disponible para lectura por cualquier usuario autenticado (`auth.role() = 'authenticated'`).
4. **Superadministrador**: Acceso global de gestión mediante rol asignado en la tabla `perfiles`.

## Aplicacion de Migraciones

### Opcion 1 — SQL Editor de Supabase (Dashboard Web)

1. Ingresar a [Supabase Dashboard](https://supabase.com/dashboard).
2. Seleccionar el proyecto `NutriOliva-BaseDatos`.
3. Navegar a **SQL Editor**.
4. Ejecutar las migraciones estrictamente en el siguiente orden:

```text
1. 001_schema_base.sql
2. 002_rls_policies.sql
3. 003_triggers.sql
4. 004_seed_catalogo.sql
5. 005_fix_admin_view.sql
6. 006_patient_auth_link.sql
```

### Opcion 2 — Supabase CLI

1. Autenticarse en Supabase CLI:

```bash
npx supabase login
```

2. Vincular el proyecto local:

```bash
npx supabase link --project-ref cvrgckctgtgcpdtjzxjp
```

3. Aplicar las migraciones a la base de datos remota:

```bash
npx supabase db push
```

## Vinculacion de Pacientes con Supabase Auth

Para que un paciente pueda iniciar sesión en el frontend y visualizar su plan:

1. El usuario debe existir en `auth.users` (creado mediante registro o script de migración).
2. Se asigna la clave `auth_user_id` en la tabla `pacientes`:

```sql
UPDATE pacientes
SET auth_user_id = '<uuid-de-auth.users>'
WHERE email = 'correo.paciente@ejemplo.com';
```

## Configuración de Edge Functions y Secretos

Para desplegar y configurar las Edge Functions:

```bash
# Definicion de secretos
npx supabase secrets set ANTHROPIC_API_KEY=tu_api_key_aqui
npx supabase secrets set FRONTEND_URL=http://localhost:5173

# Despliegue de funciones
npx supabase functions deploy invite-patient
npx supabase functions deploy estimate-calories
npx supabase functions deploy parse-pdf
```
