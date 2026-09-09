// estimate-calories/index.ts
// Edge Function — estima las calorias de una comida descrita en texto libre.
//
// Recibe:
//   { descripcion: string, paciente_id?: string }
//
// Logica de decision (2 pasos en cascada):
//   PASO 1 — Busca en el catalogo_alimentos del nutricionista del paciente.
//            Si hay coincidencia por nombre (busqueda multi-palabra case-insensitive)
//            devuelve las calorias del catalogo directamente.
//            Es la fuente mas confiable porque la cargo el propio nutricionista.
//
//   PASO 2 — Si no hay match en el catalogo, llama a Claude Haiku (Anthropic).
//            El modelo esta instruido como nutricionista experto en comida argentina
//            y latinoamericana. Devuelve un entero entre 0 y 5000 o null.
//            Si ANTHROPIC_API_KEY no esta configurada, devuelve sin_datos (sin error).
//
// Respuesta exitosa:
//   { calorias: number | null, fuente: "catalogo" | "ia" | "sin_datos" | "error_ia" }
//
// Si calorias es null, el paciente debe ingresar el valor manualmente.
// La funcion NUNCA devuelve un error que rompa la UI — siempre 200.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── CORS — necesario para llamadas desde el navegador ─────────────────────────
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── Respuestas helper ─────────────────────────────────────────────────────────
function jsonOk(body: unknown) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonError(body: unknown, status = 500) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ── Handler principal ─────────────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  // Preflight CORS — el navegador lo envia antes de cada POST
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Validar body ───────────────────────────────────────────────────────
    const { descripcion, paciente_id } = await req.json();

    if (!descripcion || typeof descripcion !== "string") {
      console.warn("[estimate-calories] Campo descripcion ausente o invalido");
      return jsonError({ error: "Se requiere el campo descripcion." }, 400);
    }

    const desc = descripcion.trim();

    // Descripcion muy corta — no tiene sentido estimar
    if (desc.length < 2) {
      console.log("[estimate-calories] Descripcion demasiado corta:", desc);
      return jsonOk({ calorias: null, fuente: "sin_datos" });
    }

    console.log(
      "[estimate-calories] Estimando calorias para:",
      desc,
      "| paciente:",
      paciente_id,
    );

    // ── 2. Inicializar cliente admin ──────────────────────────────────────────
    // Se usa service_role para poder leer el catalogo sin restricciones de RLS
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // ── PASO 1: Buscar en el catalogo del nutricionista del paciente ──────────
    // Solo se ejecuta si tenemos paciente_id para saber a que nutricionista pertenece
    let caloriasDelCatalogo: number | null = null;

    if (paciente_id) {
      // Obtener el nutricionista_id del paciente
      const { data: paciente, error: pacienteErr } = await supabaseAdmin
        .from("pacientes")
        .select("nutricionista_id")
        .eq("id", paciente_id)
        .single();

      if (pacienteErr) {
        console.warn(
          "[estimate-calories] Error al buscar paciente:",
          pacienteErr.message,
        );
      }

      if (paciente?.nutricionista_id) {
        // Separar la descripcion en palabras de 2+ caracteres para busqueda multi-termino
        // Ejemplo: "milanesa con pure" → ["milanesa", "con", "pure"]
        const palabras = desc.split(/\s+/).filter((p: string) => p.length >= 2);

        console.log(
          "[estimate-calories] Buscando en catalogo con palabras:",
          palabras.slice(0, 3),
        );

        // Encadenar filtros ilike por cada palabra (hasta 3 palabras para no sobre-filtrar)
        let query = supabaseAdmin
          .from("catalogo_alimentos")
          .select("nombre, calorias_por_unidad")
          .eq("nutricionista_id", paciente.nutricionista_id)
          .not("calorias_por_unidad", "is", null)
          .limit(5);

        for (const palabra of palabras.slice(0, 3)) {
          query = query.ilike("nombre", `%${palabra}%`);
        }

        const { data: resultados, error: catalogoErr } = await query;

        if (catalogoErr) {
          console.warn(
            "[estimate-calories] Error al buscar en catalogo:",
            catalogoErr.message,
          );
        }

        if (resultados && resultados.length > 0) {
          caloriasDelCatalogo = Math.round(resultados[0].calorias_por_unidad);
          console.log(
            "[estimate-calories] PASO 1 OK — Match en catalogo:",
            resultados[0].nombre,
            "→",
            caloriasDelCatalogo,
            "kcal",
          );
        } else {
          console.log(
            "[estimate-calories] PASO 1 — Sin match en catalogo. Pasando a IA...",
          );
        }
      }
    }

    // Devolver resultado del catalogo si hubo match (fuente mas confiable)
    if (caloriasDelCatalogo !== null) {
      return jsonOk({ calorias: caloriasDelCatalogo, fuente: "catalogo" });
    }

    // ── PASO 2: Estimar con Claude Haiku si no hay match en el catalogo ───────
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");

    if (!anthropicKey) {
      // La key no esta configurada — devolvemos sin_datos sin romper la UI
      console.warn(
        "[estimate-calories] ANTHROPIC_API_KEY no configurada. Devolviendo sin_datos.",
      );
      return jsonOk({ calorias: null, fuente: "sin_datos" });
    }

    // Prompt especializado en comida argentina y latinoamericana
    // max_tokens: 20 — solo necesitamos un numero o "null"
    const prompt =
      `Sos un nutricionista experto en alimentos argentinos y latinoamericanos.\n` +
      `El paciente registro esta comida: "${desc}"\n` +
      `Estima las calorias totales de esa porcion tipica.\n` +
      `Devuelve SOLO un numero entero (sin texto, sin unidades, sin explicaciones).\n` +
      `Si la descripcion es muy vaga para estimar, devuelve exactamente: null\n\n` +
      `Ejemplos de respuestas correctas:\n` +
      `- "manzana" → 80\n` +
      `- "cafe con leche" → 120\n` +
      `- "milanesa con pure" → 550\n` +
      `- "locro" → 420\n` +
      `- "agua" → 0\n` +
      `- "algo rico" → null`;

    console.log("[estimate-calories] PASO 2 — Llamando a Claude Haiku...");

    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-haiku-20240307",
        max_tokens: 20,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    // Si Claude falla (error de red, key invalida, rate limit, etc.)
    if (!claudeRes.ok) {
      const claudeErrText = await claudeRes.text().catch(() => "sin detalle");
      console.error(
        "[estimate-calories] Error de Claude HTTP",
        claudeRes.status,
        ":",
        claudeErrText,
      );
      return jsonOk({ calorias: null, fuente: "error_ia" });
    }

    // Parsear la respuesta de Claude y extraer el numero
    const claudeData = await claudeRes.json();
    const rawText = claudeData?.content?.[0]?.text?.trim() ?? "";

    console.log(
      "[estimate-calories] PASO 2 — Respuesta raw de Claude:",
      rawText,
    );

    let calorias: number | null = null;

    if (rawText !== "null" && rawText !== "") {
      const parsed = parseInt(rawText, 10);

      // Validar que sea un numero razonable (0 - 5000 kcal)
      if (!isNaN(parsed) && parsed >= 0 && parsed <= 5000) {
        calorias = parsed;
        console.log(
          "[estimate-calories] PASO 2 OK — Calorias estimadas por IA:",
          calorias,
          "kcal",
        );
      } else {
        console.warn(
          "[estimate-calories] PASO 2 — Valor fuera de rango o no numerico:",
          rawText,
        );
      }
    } else {
      console.log(
        "[estimate-calories] PASO 2 — Claude no pudo estimar (devolvio null)",
      );
    }

    return jsonOk({ calorias, fuente: "ia" });
  } catch (err) {
    // Error inesperado — lo logueamos completo para debug
    console.error("[estimate-calories] Excepcion inesperada:", err);
    return jsonError({ error: String(err) });
  }
});
