// Verifica que no existan caracteres con doble codificacion UTF-8 (mojibake) en Backend/supabase.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("../supabase", import.meta.url));
const MOJIBAKE_RE =
  /Ã[¡©­³º±¼ÁÉÍÓÚÑ€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ]|Â[·¡¿°ªº]|â€|â†|âœ|â˜|ï¸|ðŸ|\uFFFD/;

let bad = 0;
let checked = 0;

function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name.startsWith(".")) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (/\.(sql|ts|toml|json)$/i.test(e.name)) {
      checked++;
      const lines = fs.readFileSync(p, "utf8").split(/\r?\n/);
      lines.forEach((l, i) => {
        if (MOJIBAKE_RE.test(l)) {
          bad++;
          console.log(
            `  [FALLA] Mojibake en ${path.relative(ROOT, p)}:${i + 1}: ${l
              .trim()
              .slice(0, 100)}`
          );
        }
      });
    }
  }
}

walk(ROOT);
console.log(
  bad
    ? `\n[FALLA] ${bad} lineas con codificacion rota en Backend`
    : `[OK] Codificacion UTF-8 de Backend verificada en ${checked} archivos (0 errores)`
);
process.exit(bad ? 1 : 0);
