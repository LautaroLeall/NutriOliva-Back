// parse-pdf/index.ts
// Edge Function — extrae el plan alimenticio de un TEXTO libre y lo estructura via Claude Haiku.
//
// Recibe:
//   { texto: string }  — Texto del plan (pegado desde Word, email, etc.)
//
// Devuelve:
//   { comidas: [{ tipo_comida, descripcion, calorias_aprox, proteinas_g, carbos_g, grasas_g }] }

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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

const TIPOS_VALIDOS = [
  "desayuno", "colacion", "almuerzo", "merienda",
  "cena", "colacion_nocturna", "snack",
];

Deno.serve(async (req: Request) => {
  // Preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Leer body como texto crudo primero para diagnosticar ──────────────────
    const rawBody = await req.text();
    console.log("[parse-pdf] method:", req.method);
    console.log("[parse-pdf] content-type:", req.headers.get("content-type"));
    console.log("[parse-pdf] raw body length:", rawBody.length);
    console.log("[parse-pdf] raw body (primeros 200 chars):", rawBody.slice(0, 200));

    // ── Parsear el JSON manualmente desde el texto crudo ──────────────────────
    let body: any = {};
    if (rawBody) {
      try {
        body = JSON.parse(rawBody);
      } catch (parseErr) {
        console.error("[parse-pdf] Error al parsear JSON del body:", parseErr);
        return jsonError({ error: "Body malformado — no es JSON valido." }, 400);
      }
    }

    // Aceptar "texto" o "texto_plan" como campo (compatibilidad)
    const texto: string = body?.texto ?? body?.texto_plan ?? "";

    console.log("[parse-pdf] campo 'texto' encontrado:", !!body?.texto);
    console.log("[parse-pdf] campo 'texto_plan' encontrado:", !!body?.texto_plan);
    console.log("[parse-pdf] claves del body:", Object.keys(body).join(", "));
    console.log("[parse-pdf] texto length:", texto.length);

    // ── Validar contenido ─────────────────────────────────────────────────────
    if (!texto || texto.trim().length < 5) {
      console.warn("[parse-pdf] Texto ausente o demasiado corto:", texto.length);
      return jsonError(
        { error: "Ingresa el texto del plan antes de analizar." },
        400,
      );
    }

    const textoLimpio = texto.trim();

    if (textoLimpio.length > 20000) {
      return jsonError(
        { error: "El texto es demasiado largo. Pega solo el contenido del plan (maximo ~5 paginas)." },
        400,
      );
    }

    console.log("[parse-pdf] Analizando texto de", textoLimpio.length, "caracteres...");

    // ── Verificar clave de Anthropic ──────────────────────────────────────────
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      console.error("[parse-pdf] ANTHROPIC_API_KEY no configurada");
      return jsonError({ error: "Servicio de IA no configurado." }, 500);
    }

    // ── Llamar a Claude Haiku ─────────────────────────────────────────────────
    const prompt =
      `Sos un asistente especializado en nutricion clinica argentina.\n` +
      `Se te proporciona el texto de un plan alimenticio.\n\n` +
      `Tu tarea: extraer TODAS las comidas y estructurarlas en JSON.\n\n` +
      `Reglas estrictas:\n` +
      `- Devuelve SOLO el JSON, sin texto adicional, sin markdown, sin bloques de codigo.\n` +
      `- El JSON es un array de objetos con EXACTAMENTE esta estructura:\n` +
      `  [{"tipo_comida":"desayuno","descripcion":"descripcion completa","calorias_aprox":320,"proteinas_g":18,"carbos_g":38,"grasas_g":8}]\n\n` +
      `- tipo_comida debe ser uno de: desayuno, colacion, almuerzo, merienda, cena, colacion_nocturna, snack\n` +
      `- Si no podes determinar el tipo, usar "colacion"\n` +
      `- calorias_aprox, proteinas_g, carbos_g, grasas_g: numero o null si no se especifica\n` +
      `- Inferi calorias si no estan explicitas basandote en nutricion argentina tipica\n` +
      `- Si hay comidas para varios dias, incluilas todas (sin duplicar las identicas)\n` +
      `- Si el texto no contiene un plan alimenticio, devolver: []\n\n` +
      `Texto del plan:\n---\n${textoLimpio}\n---`;

    console.log("[parse-pdf] Llamando a Claude Haiku...");

    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-3-haiku-20240307",
        max_tokens: 2048,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!claudeRes.ok) {
      const errText = await claudeRes.text().catch(() => "sin detalle");
      console.error("[parse-pdf] Error de Claude HTTP", claudeRes.status, ":", errText);

      // Exponer el error real de Claude para poder diagnosticarlo
      let mensajeUsuario = "Error al analizar el texto.";
      try {
        const errJson = JSON.parse(errText);
        const tipo = errJson?.error?.type ?? "";
        const msg  = errJson?.error?.message ?? "";
        console.error("[parse-pdf] Claude error type:", tipo, "| message:", msg);

        if (claudeRes.status === 401) {
          mensajeUsuario = "API key de IA invalida o revocada. Contacta al administrador.";
        } else if (claudeRes.status === 429) {
          mensajeUsuario = "Limite de solicitudes de IA alcanzado. Intenta en unos segundos.";
        } else if (claudeRes.status === 400) {
          mensajeUsuario = `Error en la solicitud a la IA: ${msg}`;
        }
      } catch { /* ignorar si no es JSON */ }

      return jsonError({ error: mensajeUsuario, detalle: `Claude HTTP ${claudeRes.status}` }, 500);
    }

    const claudeData = await claudeRes.json();
    const rawText = claudeData?.content?.[0]?.text?.trim() ?? "";

    console.log("[parse-pdf] Respuesta Claude (primeros 400 chars):", rawText.slice(0, 400));

    if (!rawText) {
      return jsonOk({ comidas: [], advertencia: "Claude no devolvio contenido." });
    }

    // ── Extraer el JSON de la respuesta ───────────────────────────────────────
    let comidas: any[] = [];

    try {
      const match = rawText.match(/\[[\s\S]*\]/);
      if (!match) {
        console.warn("[parse-pdf] No se encontro array JSON en la respuesta");
        return jsonOk({
          comidas: [],
          advertencia: "No se encontraron comidas en el texto. Verifica que sea un plan alimenticio.",
        });
      }

      const parsed = JSON.parse(match[0]);
      if (!Array.isArray(parsed)) {
        return jsonOk({ comidas: [], advertencia: "Formato inesperado." });
      }

      comidas = parsed
        .filter((c: any) => c && typeof c.descripcion === "string" && c.descripcion.trim())
        .map((c: any) => ({
          tipo_comida: TIPOS_VALIDOS.includes(c.tipo_comida) ? c.tipo_comida : "colacion",
          descripcion: String(c.descripcion).trim().slice(0, 300),
          calorias_aprox: Number.isFinite(c.calorias_aprox) && c.calorias_aprox > 0
            ? Math.round(c.calorias_aprox) : null,
          proteinas_g: Number.isFinite(c.proteinas_g) && c.proteinas_g > 0
            ? Math.round(c.proteinas_g * 10) / 10 : null,
          carbos_g: Number.isFinite(c.carbos_g) && c.carbos_g > 0
            ? Math.round(c.carbos_g * 10) / 10 : null,
          grasas_g: Number.isFinite(c.grasas_g) && c.grasas_g > 0
            ? Math.round(c.grasas_g * 10) / 10 : null,
        }));

      console.log("[parse-pdf] OK —", comidas.length, "comidas extraidas");
    } catch (parseErr) {
      console.error("[parse-pdf] Error al parsear JSON de Claude:", parseErr);
      return jsonOk({ comidas: [], advertencia: "No se pudo interpretar la respuesta de la IA." });
    }

    return jsonOk({ comidas });

  } catch (err) {
    console.error("[parse-pdf] Excepcion inesperada:", err);
    return jsonError({ error: String(err) });
  }
});
