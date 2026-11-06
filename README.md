# NutriOliva — Backend, Base de Datos & Edge Functions

Repositorio oficial de base de datos PostgreSQL, esquema multi-tenant, politicas Row Level Security (RLS), almacenamiento privado de imagenes y Edge Functions en Deno/TypeScript sobre **Supabase**.

---

## 1. Informacion del Proyecto Supabase

| Propiedad          | Detalle                                    |
| ------------------ | ------------------------------------------ |
| Proyecto           | `NutriOliva-BaseDatos`                     |
| Project Ref        | `cvrgckctgtgcpdtjzxjp`                     |
| URL del Proyecto   | `https://cvrgckctgtgcpdtjzxjp.supabase.co` |
| Region             | South America (Sao Paulo)                  |
| Motor IA           | Anthropic (`claude-3-haiku-20240307`)      |
| Repositorio GitHub | `NutriOliva-Back`                          |

---

## 2. Estructura del Repositorio

```text
Backend/
├── README.md
└── supabase/
    ├── functions/                                     # 4 Supabase Edge Functions (Deno / TypeScript)
    │   ├── deno.json                                  # Configuracion del runtime Deno
    │   ├── create-nutricionista/index.ts              # Alta segura de nutricionistas (solo superadmin)
    │   ├── invite-patient/index.ts                    # Invitacion, re-invitacion o recovery de pacientes
    │   ├── estimate-calories/index.ts                 # Estimacion calorica en cascada (Catalogo -> IA)
    │   └── parse-pdf/index.ts                         # Extraccion estructurada de planes desde texto libre con IA
    └── migrations/                                    # 17 migraciones SQL evolutivas + Storage
        ├── 001_schema_base.sql                        # 9 tablas nucleo e indices de performance
        ├── 002_rls_policies.sql                       # Politicas RLS base y funciones helper por rol
        ├── 003_triggers.sql                           # Triggers de creacion automatica de perfiles y nutricionistas
        ├── 004_seed_catalogo.sql                      # Seed inicial de 35 alimentos base globales
        ├── 005_fix_admin_view.sql                     # Columna email en perfiles y vista admin con security_invoker
        ├── 006_patient_auth_link.sql                  # Columna auth_user_id en pacientes y politicas RLS del paciente
        ├── 007_catalogo_enriquecido.sql               # Metadatos clinicos y 80 preparaciones completas globales
        ├── 008_catalogo_ampliado_profesional.sql      # +90 preparaciones clinicas adicionales (>205 items globales)
        ├── 009_datos_clinicos_ampliados.sql           # Composicion corporal, anamnesis, 7 objetivos, 7 comidas y vista IMC
        ├── 010_fix_fuente_estimacion.sql              # Habilita 'plan' en registros_comida.fuente_estimacion
        ├── 011_security_hardening.sql                 # Hardening SECURITY DEFINER (search_path = '' y REVOKE public)
        ├── 012_trigger_patient_confirmed.sql          # Trigger on_patient_confirmed para vincular auth_user_id al activar cuenta
        ├── 20260915_013_policy_perfiles_self.sql      # Garantiza lectura del propio registro en perfiles
        ├── 20261105_014_admin_planes_y_pacientes.sql  # Tabla planes_suscripcion, cupo_extra y vista admin dinamica
        ├── 20261105_015_paciente_ver_nutricionista.sql# Lectura del perfil del nutricionista asignado desde la vista paciente
        ├── 20261105_016_superadmin_ia_metrics.sql     # Lectura de registros_comida para metricas de uso/costo IA en /admin
        └── storage_001_buckets_fotos.sql              # Buckets privados fotos-comidas y fotos-actividad (5 MB max)
```

---

## 3. Modelo de Datos Completo

### 3.1 Tablas Relacionales (10 tablas en `public`)

| Tabla                     | Proposito Principal                                                                            | Columnas y Reglas Clave                                                                                                                                                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`perfiles`**            | Identidad extendida vinculada `1:1` a `auth.users`.                                            | `id`, `rol` (`superadmin`, `nutricionista`, `paciente`), `nombre`, `email`, `created_at`.                                                                                                                                  |
| **`planes_suscripcion`**  | Catalogo comercial editable por el Super Admin.                                                | `id` (`starter`, `pro`, `clinic`), `nombre`, `precio_mensual_ars`, `cupo_pacientes`, `descripcion`, `updated_at`.                                                                                                          |
| **`nutricionistas`**      | Estado comercial y capacidad de cada profesional.                                              | `id` (FK `perfiles`), `plan_suscripcion`, `estado` (`Activo`, `Pago pendiente`, `Inactivo`), `cupo_extra`, `created_at`.                                                                                                   |
| **`pacientes`**           | Nomina de pacientes por nutricionista y vinculo Auth.                                          | `id`, `nutricionista_id`, `perfil_id`, `auth_user_id`, `nombre`, `email`, `telefono`, `fecha_nacimiento`, `estado` (`activo`, `inactivo`).                                                                                 |
| **`datos_clinicos`**      | Historial antropometrico y clinico acumulativo (no destructivo).                               | `peso`, `altura`, `edad`, `sexo`, `objetivo` (7 opciones), `nivel_actividad` (5 niveles), `porcentaje_grasa`, `masa_muscular_kg`, `cintura_cm`, `patologias`, `alergias`, `medicacion`, `observaciones`, `fecha_registro`. |
| **`planes`**              | Cabecera de planes alimenticios versionados por paciente.                                      | `paciente_id`, `calorias_objetivo`, `version`, `estado` (`borrador`, `activo`, `archivado`), `notas`.                                                                                                                      |
| **`comidas_plan`**        | Detalle de comidas e ingesta objetivo dentro de un plan.                                       | `plan_id`, `tipo_comida` (`desayuno`, `colacion`, `almuerzo`, `merienda`, `cena`, `colacion_nocturna`, `snack`), `descripcion`, `calorias_aprox`, `proteinas_g`, `carbos_g`, `grasas_g`, `orden`.                          |
| **`catalogo_alimentos`**  | Base nutricional global (`nutricionista_id IS NULL`, +205 items) y propia de cada consultorio. | `nombre`, `calorias_por_unidad`, `unidad`, `proteinas_g`, `carbos_g`, `grasas_g`, `tipo_comida`, `objetivo_ideal`, `perfil_paciente`, `descripcion_completa`, `es_comida_completa`.                                        |
| **`registros_comida`**    | Diario de ingestas registradas por el paciente.                                                | `paciente_id`, `fecha`, `hora`, `descripcion`, `foto_url`, `calorias_estimadas`, `fuente_estimacion` (`plan`, `catalogo`, `ia`, `manual`).                                                                                 |
| **`registros_actividad`** | Diario de actividad fisica y gasto calorico del paciente.                                      | `paciente_id`, `fecha`, `hora`, `tipo`, `duracion_min`, `intensidad` (`baja`, `media`, `alta`), `calorias_gastadas`.                                                                                                       |

### 3.2 Vistas SQL (`security_invoker = true`)

- **`admin_nutricionistas_view`**: Consolida datos comerciales para `/admin` sin exponer `auth.users`. Calcula en tiempo real `total_pacientes` (activos), `total_pacientes_historico`, `cupo_extra`, `cupo_maximo` y `precio_mensual_ars` cruzando `nutricionistas`, `perfiles`, `pacientes` y `planes_suscripcion`.
- **`ultimo_dato_clinico`**: Obtiene mediante `DISTINCT ON (paciente_id)` la medicion mas reciente de cada paciente junto con el calculo automatico de `imc`.

### 3.3 Triggers Automaticos

- **`on_auth_user_created` (`handle_new_user`)**: Crea automaticamente el registro en `perfiles` al registrarse un usuario en `auth.users`.
- **`on_perfil_nutricionista` (`handle_new_nutricionista`)**: Inicializa la fila en `nutricionistas` con plan `starter` y estado `Activo` cuando el perfil tiene `rol = 'nutricionista'`.
- **`on_patient_confirmed` (`handle_patient_confirmed`)**: Vincula automaticamente `pacientes.auth_user_id` y asegura `perfiles.rol = 'paciente'` cuando el paciente confirma su contraseña por primera vez.

### 3.4 Supabase Storage (Buckets Privados)

- **`fotos-comidas`** y **`fotos-actividad`**:
  - Privados (`public = false`), limite de **5 MB** por archivo, formatos permitidos `image/jpeg`, `image/png`, `image/webp`, `image/heic`.
  - Aislamiento por prefijo de carpeta `<paciente_id>/<timestamp>.<ext>`.
  - El frontend accede exclusivamente mediante URLs firmadas temporales (`createSignedUrl(path, 3600)`).

---

## 4. Seguridad y Row Level Security (RLS)

Todas las tablas y buckets tienen **RLS habilitado** y las funciones auxiliares (`get_user_rol()`, `get_nutricionista_id()`, `get_paciente_id()`) estan endurecidas con `SECURITY DEFINER`, `SET search_path = ''` y permisos `EXECUTE` revocados para `anon` y `public`.

1. **Nutricionista**: Solo lee y modifica sus propios pacientes, planes, datos clinicos y alimentos personalizados, ademas de visualizar los registros diarios y fotos de su cartera.
2. **Paciente**: Solo accede a su propio registro de paciente (`auth_user_id = auth.uid()`), su historial clinico, su plan activo, el perfil basico de su nutricionista asignado (`nombre`, `email`) y administra sus propios registros diarios y fotos.
3. **Superadministrador**: Gestiona `nutricionistas`, `planes_suscripcion`, cupos de `pacientes` y audita el volumen/costo de llamadas a IA en `registros_comida`. **No tiene acceso** a `datos_clinicos` ni `planes` por privacidad medica.

---

## 5. Edge Functions (`supabase/functions`)

| Funcion                    | Metodo | Rol Requerido                 | Descripcion                                                                                                                                                                                                                                           |
| -------------------------- | ------ | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`create-nutricionista`** | `POST` | `superadmin` (JWT verificado) | Crea usuario en Supabase Auth (`email_confirm: true`), asigna `rol = 'nutricionista'` en `perfiles` y registra su suscripcion inicial en `nutricionistas`.                                                                                            |
| **`invite-patient`**       | `POST` | `nutricionista`               | Gestiona 3 escenarios: **Caso A** (usuario confirmado -> envia link de recovery a `/set-password`), **Caso B** (cuenta sin confirmar -> limpia cuenta fantasma y re-invita), **Caso C** (usuario nuevo -> envia invitacion y vincula `auth_user_id`). |
| **`estimate-calories`**    | `POST` | Autenticado                   | **Paso 1**: busca coincidencia multi-palabra en el catalogo del nutricionista. **Paso 2**: si no hay match, estima calorias de la porcion con `claude-3-haiku-20240307` (`fuente: "ia"`). Nunca rompe la UI (fallback seguro a carga manual).         |
| **`parse-pdf`**            | `POST` | `nutricionista`               | Recibe el texto de un plan alimenticio y utiliza `claude-3-haiku-20240307` para estructurar todas las comidas en JSON con los 7 tiempos de comida validos, calorias y macronutrientes.                                                                |

---

## 6. Aplicacion de Migraciones y Despliegue

### 6.1 Mediante Supabase CLI (Recomendado)

```bash
# 1. Iniciar sesion en Supabase CLI
npx supabase login

# 2. Vincular con el proyecto remoto
npx supabase link --project-ref cvrgckctgtgcpdtjzxjp

# 3. Aplicar todas las migraciones pendientes en orden
npx supabase db push
```

### 6.2 Orden Manual en SQL Editor (Instalacion desde Cero)

Si se inicializa un entorno nuevo manualmente desde el SQL Editor de Supabase, ejecutar en este orden exacto:

```text
01. 001_schema_base.sql
02. 002_rls_policies.sql
03. 003_triggers.sql
04. 004_seed_catalogo.sql
05. 005_fix_admin_view.sql
06. 006_patient_auth_link.sql
07. 007_catalogo_enriquecido.sql
08. 008_catalogo_ampliado_profesional.sql
09. 009_datos_clinicos_ampliados.sql
10. 010_fix_fuente_estimacion.sql
11. 011_security_hardening.sql
12. 012_trigger_patient_confirmed.sql
13. 20260915_013_policy_perfiles_self.sql
14. 20261105_014_admin_planes_y_pacientes.sql
15. 20261105_015_paciente_ver_nutricionista.sql
16. 20261105_016_superadmin_ia_metrics.sql
17. storage_001_buckets_fotos.sql
```

### 6.3 Configuracion de Secretos y Despliegue de Edge Functions

```bash
# Configurar variables de entorno secretas en Supabase
npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-tu_api_key_aqui
npx supabase secrets set SITE_URL=https://tu-dominio-produccion.com

# Desplegar las 4 Edge Functions
npx supabase functions deploy create-nutricionista
npx supabase functions deploy invite-patient
npx supabase functions deploy estimate-calories
npx supabase functions deploy parse-pdf
```

> **Nota sobre Supabase Auth Redirect URLs**: Asegurarse de incluir `http://localhost:5173/set-password` (desarrollo) y `https://tu-dominio-produccion.com/set-password` (produccion) dentro de **Authentication -> URL Configuration -> Redirect URLs** en el Dashboard de Supabase.
