// Auditoria automatizada de Row Level Security (RLS), hardening de funciones SECURITY DEFINER
// y aislamiento multi-tenant en las migraciones de NutriOliva.

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("..", import.meta.url));
const MIG_DIR = path.join(ROOT, "supabase", "migrations");

const allSql = fs
  .readdirSync(MIG_DIR)
  .filter((f) => f.endsWith(".sql"))
  .sort()
  .map((f) => fs.readFileSync(path.join(MIG_DIR, f), "utf8"))
  .join("\n\n");

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

console.log("\n[1] Row Level Security (RLS) activo en las 10 tablas");
const TABLES = [
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

for (const table of TABLES) {
  check(`RLS habilitado en '${table}'`, () => {
    const re = new RegExp(
      `ALTER\\s+TABLE\\s+(?:public\\.)?${table}\\s+ENABLE\\s+ROW\\s+LEVEL\\s+SECURITY`,
      "i"
    );
    assert.ok(re.test(allSql), `Falta ENABLE ROW LEVEL SECURITY en ${table}`);
  });
}

console.log("\n[2] Hardening de funciones SECURITY DEFINER y vistas (Migraciones 005, 009, 011, 014)");
check("Funciones helper fijan SET search_path = ''", () => {
  assert.ok(
    /SET\s+search_path\s*=\s*''/i.test(allSql),
    "Falta SET search_path = '' en funciones SECURITY DEFINER"
  );
});

check("Revocacion de ejecucion publica (REVOKE EXECUTE ... FROM anon, public)", () => {
  assert.ok(
    /REVOKE\s+EXECUTE\s+ON\s+FUNCTION\s+public\.get_user_rol\(\)\s+FROM\s+anon,\s*public/i.test(
      allSql
    )
  );
  assert.ok(
    /REVOKE\s+EXECUTE\s+ON\s+FUNCTION\s+public\.handle_new_user\(\)\s+FROM\s+anon,\s*authenticated,\s*public/i.test(
      allSql
    )
  );
});

check("Vistas administrativas usan security_invoker = true", () => {
  const matches = allSql.match(/security_invoker\s*=\s*true/gi) || [];
  assert.ok(
    matches.length >= 3,
    "Las vistas deben declarar WITH (security_invoker = true)"
  );
});

console.log("\n[3] Politicas de aislamiento por rol y Storage privado");
const REQUIRED_POLICIES = [
  "planes_suscripcion_select",
  "planes_suscripcion_update_admin",
  "superadmin_select_pacientes",
  "paciente_select_su_nutricionista_perfil",
  "datos_clinicos_select_paciente_auth",
  "superadmin_select_registros_comida",
  "paciente sube foto comida",
  "nutricionista ve fotos comida pacientes",
];

for (const pol of REQUIRED_POLICIES) {
  check(`Politica RLS '${pol}' presente`, () => {
    assert.ok(allSql.includes(`"${pol}"`), `Falta politica "${pol}"`);
  });
}

console.log(
  `\n====== RESULTADO SEGURIDAD & RLS: ${pass} OK | ${fail} FALLAS ======\n`
);
process.exit(fail ? 1 : 0);
