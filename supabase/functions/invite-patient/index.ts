// invite-patient/index.ts
// Edge Function — invita a un paciente por email usando Supabase Auth Admin.
//
// Recibe:
//   { paciente_id: string, nombre: string, email: string }
//
// Logica de decision (3 casos):
//   CASO A — El usuario YA existe en auth y YA confirmo su cuenta
//            → Genera un link de recovery y lo envia por mail.
//              Util para cuando el paciente olvido su contrasena.
//
//   CASO B — El usuario existe pero NUNCA confirmo (cuenta fantasma)
//            → Elimina la cuenta vieja y lo re-invita desde cero.
//              Util cuando la invitacion anterior expiro.
//
//   CASO C — El usuario NO existe en auth
//            → Lo invita directamente (envia mail de bienvenida con link).
//
// Respuesta exitosa:
//   { success: true, existing_confirmed: boolean, user_id?: string }
//
// En todos los casos vincula auth_user_id en la tabla pacientes y crea el
// perfil en la tabla perfiles con rol = "paciente".

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
    const body = await req.json();
    const { paciente_id, nombre, email } = body;

    if (!email || !nombre || !paciente_id) {
      console.warn("[invite-patient] Body incompleto:", {
        paciente_id,
        nombre,
        email,
      });
      return jsonError(
        { error: "Faltan datos obligatorios: paciente_id, nombre, email" },
        400,
      );
    }

    const emailLower = email.toLowerCase().trim();

    // URL base del sitio — usada para redirigir al paciente despues del login
    const siteUrl = Deno.env.get("SITE_URL") ?? "http://localhost:5173";
    const redirectTo = `${siteUrl}/set-password`;

    console.log("[invite-patient] Procesando invitacion para:", emailLower);

    // ── 2. Inicializar cliente admin ──────────────────────────────────────────
    // Se usa service_role para operar sobre auth sin restricciones de RLS
    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // ── 3. Buscar si ya existe un usuario con ese email en auth ───────────────
    const { data: listData, error: listErr } = await admin.auth.admin.listUsers(
      { perPage: 1000 },
    );
    if (listErr) {
      console.error("[invite-patient] Error al listar usuarios:", listErr.message);
      return jsonError({ error: listErr.message });
    }

    const existingUser = listData.users.find(
      (u: any) => u.email === emailLower,
    );

    // ── Helper: vincula el auth_user_id al paciente y crea su perfil ──────────
    async function vincularPaciente(userId: string) {
      console.log("[invite-patient] Vinculando paciente:", paciente_id, "→ user:", userId);

      // Guarda el auth_user_id en la tabla pacientes para poder hacer joins
      const { error: updateErr } = await admin
        .from("pacientes")
        .update({ auth_user_id: userId })
        .eq("id", paciente_id);

      if (updateErr) {
        console.warn("[invite-patient] Error al actualizar paciente:", updateErr.message);
      }

      // Crea o actualiza el perfil con rol = paciente
      const { error: upsertErr } = await admin
        .from("perfiles")
        .upsert({ id: userId, rol: "paciente", nombre }, { onConflict: "id" });

      if (upsertErr) {
        console.warn("[invite-patient] Error al upsert perfil:", upsertErr.message);
      }
    }

    // ── CASO A: usuario existe y ya confirmo su cuenta ────────────────────────
    // Le mandamos un link de "restablecer contrasena" para que pueda ingresar
    if (existingUser?.confirmed_at) {
      console.log(
        "[invite-patient] CASO A — Usuario confirmado:",
        existingUser.id,
        "— enviando link de recovery",
      );

      await vincularPaciente(existingUser.id);

      const { error: linkErr } = await admin.auth.admin.generateLink({
        type: "recovery",
        email: emailLower,
        options: { redirectTo },
      });

      if (linkErr) {
        // El link fallo pero el paciente igual quedo vinculado
        console.warn("[invite-patient] Error al generar link de recovery:", linkErr.message);
        return jsonOk({
          success: true,
          existing_confirmed: true,
          warning: linkErr.message,
        });
      }

      console.log("[invite-patient] CASO A OK — Link de recovery enviado");
      return jsonOk({ success: true, existing_confirmed: true });
    }

    // ── CASO B: usuario existe pero NUNCA confirmo (cuenta fantasma) ──────────
    // Borramos la cuenta vieja para poder re-invitar con un mail fresco
    if (existingUser && !existingUser.confirmed_at) {
      console.log(
        "[invite-patient] CASO B — Usuario sin confirmar:",
        existingUser.id,
        "— eliminando para re-invitar",
      );

      const { error: deleteErr } = await admin.auth.admin.deleteUser(
        existingUser.id,
      );

      if (deleteErr) {
        console.warn("[invite-patient] Error al eliminar usuario fantasma:", deleteErr.message);
        // Continuamos igual — intentamos invitar aunque falle el delete
      } else {
        console.log("[invite-patient] Usuario fantasma eliminado. Re-invitando...");
      }
    }

    // ── CASO C: usuario nuevo (o recien eliminado en CASO B) ─────────────────
    // Envia el mail de invitacion con link de configuracion de contrasena
    console.log("[invite-patient] CASO C — Invitando nuevo usuario:", emailLower);

    const { data: inviteData, error: inviteErr } =
      await admin.auth.admin.inviteUserByEmail(emailLower, {
        data: { nombre, paciente_id, rol: "paciente" },
        redirectTo,
      });

    if (inviteErr) {
      console.error("[invite-patient] Error al invitar usuario:", inviteErr.message);
      return jsonError({ error: inviteErr.message });
    }

    const newUserId = inviteData.user?.id;
    console.log("[invite-patient] CASO C OK — Invitacion enviada. user_id:", newUserId);

    // Vincular solo si obtenemos el user_id
    if (newUserId) {
      await vincularPaciente(newUserId);
    }

    return jsonOk({
      success: true,
      existing_confirmed: false,
      user_id: newUserId,
    });
  } catch (err) {
    // Error inesperado — lo logueamos completo para debug
    console.error("[invite-patient] Excepcion inesperada:", err);
    return jsonError({ error: String(err) });
  }
});
