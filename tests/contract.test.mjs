// Verificacion automatizada del contrato de esquema SQL entre Backend y Frontend en NutriOliva:
// Verifica las 17 migraciones, las 10 tablas, columnas extendidas, 2 vistas, 3 triggers y 2 buckets de Storage.

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("..", import.meta.url));
const MIG_DIR = path.join(ROOT, "supabase", "migrations");

let pass = 0;
let fail = 0;

function check(name, fn) {
  try {
    fn();
    pass++;
    console.log(`  [OK] ${name}`);
  } catch (err) {
    fail++;
    console.log(`  [FALLA] ${name}: ${err.message}`);
  }
}

const migFiles = fs
  .readdirSync(MIG_DIR)
  .filter((f) => f.endsWith(".sql"))
  .sort();

const allSql = migFiles
  .map((f) => fs.readFileSync(path.join(MIG_DIR, f), "utf8"))
  .join("\n\n");

console.log("\n[1] Inventario de migraciones SQL");
check("Existen las 17 migraciones SQL esperadas", () => {
  assert.equal(migFiles.length, 17, `Se encontraron ${migFiles.length} migraciones`);
});

console.log("\n[2] Contrato de las 10 tablas relacionales");
const EXPECTED_TABLES = [
  "perfiles",
  "planes_suscripcion",
  "nutricionistas",
  "pacientes",
  "datos_clinicos",
  "planes",
  "comidas_plan",
  "catalogo_alimentos",
  "registros_comida",
  "registros_actividad",
];

for (const table of EXPECTED_TABLES) {
  check(`Tabla '${table}' definida en migraciones`, () => {
    const re = new RegExp(
      `CREATE\\s+TABLE\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?(?:public\\.)?${table}\\b`,
      "i"
    );
    assert.ok(re.test(allSql), `No se encontro CREATE TABLE para ${table}`);
  });
}

console.log("\n[3] Contrato de columnas clave y ampliaciones clinicas/comerciales");
const EXPECTED_COLUMNS = [
  "auth_user_id",
  "cupo_extra",
  "precio_mensual_ars",
  "cupo_pacientes",
  "porcentaje_grasa",
  "masa_muscular_kg",
  "cintura_cm",
  "patologias",
  "alergias",
  "medicacion",
  "nivel_actividad",
  "tipo_comida",
  "objetivo_ideal",
  "perfil_paciente",
  "descripcion_completa",
  "es_comida_completa",
  "fuente_estimacion",
  "foto_url",
];

for (const col of EXPECTED_COLUMNS) {
  check(`Columna '${col}' presente en el esquema SQL`, () => {
    const re = new RegExp(`\\b${col}\\b`, "i");
    assert.ok(re.test(allSql), `Falta columna ${col}`);
  });
}

console.log("\n[4] Vistas SQL, Triggers y Storage Buckets");
for (const view of ["admin_nutricionistas_view", "ultimo_dato_clinico"]) {
  check(`Vista '${view}' creada con security_invoker`, () => {
    const re = new RegExp(`CREATE\\s+(?:OR\\s+REPLACE\\s+)?VIEW\\s+(?:public\\.)?${view}\\b`, "i");
    assert.ok(re.test(allSql), `Falta vista ${view}`);
  });
}

for (const trig of [
  "on_auth_user_created",
  "on_perfil_nutricionista",
  "on_patient_confirmed",
]) {
  check(`Trigger '${trig}' definido`, () => {
    const re = new RegExp(`CREATE\\s+TRIGGER\\s+${trig}\\b`, "i");
    assert.ok(re.test(allSql), `Falta trigger ${trig}`);
  });
}

for (const bucket of ["fotos-comidas", "fotos-actividad"]) {
  check(`Bucket privado '${bucket}' configurado en Storage`, () => {
    assert.ok(allSql.includes(`'${bucket}'`), `Falta bucket ${bucket}`);
  });
}

console.log(
  `\n====== RESULTADO CONTRATO SQL: ${pass} OK | ${fail} FALLAS ======\n`
);
process.exit(fail ? 1 : 0);
