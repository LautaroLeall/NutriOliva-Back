// Auditoria automatizada de las 4 Edge Functions y supabase/config.toml de NutriOliva.

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("..", import.meta.url));
const FN_DIR = path.join(ROOT, "supabase", "functions");
const CFG_PATH = path.join(ROOT, "supabase", "config.toml");

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

const createNutriSrc = fs.readFileSync(
  path.join(FN_DIR, "create-nutricionista", "index.ts"),
  "utf8"
);
const invitePatientSrc = fs.readFileSync(
  path.join(FN_DIR, "invite-patient", "index.ts"),
  "utf8"
);
const estimateCalSrc = fs.readFileSync(
  path.join(FN_DIR, "estimate-calories", "index.ts"),
  "utf8"
);
const parsePdfSrc = fs.readFileSync(
  path.join(FN_DIR, "parse-pdf", "index.ts"),
  "utf8"
);
const cfgSrc = fs.readFileSync(CFG_PATH, "utf8");

console.log("\n[1] Auditoria de las 4 Edge Functions");

check(
  "create-nutricionista valida rol 'superadmin' y planes permitidos ('starter', 'pro', 'clinic')",
  () => {
    assert.ok(createNutriSrc.includes('perfilData.rol !== "superadmin"'));
    assert.ok(createNutriSrc.includes('["starter", "pro", "clinic"]'));
    assert.ok(createNutriSrc.includes("admin.auth.admin.createUser"));
  }
);

check(
  "invite-patient usa SITE_URL con redireccion a /set-password y contempla los 3 casos de cuenta",
  () => {
    assert.ok(invitePatientSrc.includes('Deno.env.get("SITE_URL")'));
    assert.ok(invitePatientSrc.includes("/set-password"));
    assert.ok(invitePatientSrc.includes("inviteUserByEmail"));
    assert.ok(invitePatientSrc.includes('type: "recovery"'));
  }
);

check(
  "estimate-calories busca primero en catalogo_alimentos y luego en Claude Haiku (claude-3-haiku-20240307)",
  () => {
    assert.ok(estimateCalSrc.includes('.from("catalogo_alimentos")'));
    assert.ok(estimateCalSrc.includes('Deno.env.get("ANTHROPIC_API_KEY")'));
    assert.ok(estimateCalSrc.includes("claude-3-haiku-20240307"));
  }
);

check(
  "parse-pdf soporta los 7 tiempos de comida validos del esquema SQL",
  () => {
    for (const tipo of [
      "desayuno",
      "colacion",
      "almuerzo",
      "merienda",
      "cena",
      "colacion_nocturna",
      "snack",
    ]) {
      assert.ok(
        parsePdfSrc.includes(`"${tipo}"`),
        `Falta tipo_comida ${tipo} en parse-pdf`
      );
    }
    assert.ok(parsePdfSrc.includes('Deno.env.get("ANTHROPIC_API_KEY")'));
  }
);

check("Ninguna Edge Function contiene claves o secretos embebidos", () => {
  for (const [name, src] of [
    ["create-nutricionista", createNutriSrc],
    ["invite-patient", invitePatientSrc],
    ["estimate-calories", estimateCalSrc],
    ["parse-pdf", parsePdfSrc],
  ]) {
    assert.ok(
      !/sk-ant-[a-zA-Z0-9_-]{10,}/.test(src),
      `API key de Anthropic embebida en ${name}`
    );
    assert.ok(
      !/sb_secret_[a-zA-Z0-9_-]{10,}/.test(src),
      `Clave secreta de Supabase embebida en ${name}`
    );
    assert.ok(!/eyJhbGciOi/.test(src), `JWT embebido en ${name}`);
  }
});

console.log("\n[2] Configuracion declarativa supabase/config.toml");
check(
  "config.toml define site_url de produccion, redirect a /set-password y las 4 Edge Functions",
  () => {
    assert.ok(cfgSrc.includes("https://nutri-oliva.vercel.app"));
    assert.ok(cfgSrc.includes("https://nutri-oliva.vercel.app/set-password"));
    assert.ok(cfgSrc.includes("[functions.create-nutricionista]"));
    assert.ok(cfgSrc.includes("[functions.invite-patient]"));
    assert.ok(cfgSrc.includes("[functions.estimate-calories]"));
    assert.ok(cfgSrc.includes("[functions.parse-pdf]"));
  }
);

console.log(
  `\n====== RESULTADO EDGE FUNCTIONS & CONFIG: ${pass} OK | ${fail} FALLAS ======\n`
);
process.exit(fail ? 1 : 0);
