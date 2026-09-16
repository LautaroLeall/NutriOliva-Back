// create-nutricionista/index.ts
// Edge Function — crea un nuevo nutricionista en el sistema.
// Solo puede ser llamada por el superadmin (verificacion por rol via JWT).
//
// Recibe:
//   { nombre: string, email: string, password: string, plan: string }
//
// Logica simplificada gracias a los triggers del proyecto:
//   1. Verifica que el llamante es superadmin
//   2. Crea el usuario en auth con user_metadata = { rol: 'nutricionista', nombre }
//   3. El trigger handle_new_user() crea automaticamente la fila en perfiles
//   4. El trigger handle_new_nutricionista() crea automaticamente la fila en nutricionistas
//   5. Si el plan no es 'starter', se actualiza manualmente en nutricionistas
//
// SEGURIDAD: usa SUPABASE_SERVICE_ROLE_KEY server-side — nunca expuesto al cliente.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── CORS ──────────────────────────────────────────────────────────────────────
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
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

// Decodifica el payload del JWT para obtener el sub (uid)
// La verificacion real la hizo el gateway de Supabase
function getUidFromJwt(jwt: string): string {
  try {
    const [, payload] = jwt.split(".");
    const padded = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padding = (4 - (padded.length % 4)) % 4;
    const decoded = JSON.parse(atob(padded + "=".repeat(padding)));
    return decoded.sub ?? "";
  } catch {
    return "";
  }
}

// ── Handler principal ─────────────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  // Preflight CORS — debe ser lo primero
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }

  try {
    // ── 1. Inicializar cliente admin ───────────────────────────────────────────
    const supabaseUrl    = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // ── 2. Verificar que el llamante es superadmin ────────────────────────────
    // Decodificamos el JWT del usuario para obtener su ID
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();

    if (!jwt) {
      return jsonError({ error: "No autorizado." }, 401);
    }

    const callerId = getUidFromJwt(jwt);
    if (!callerId) {
      return jsonError({ error: "Token invalido." }, 401);
    }

    console.log("[create-nutricionista] Verificando rol del llamante:", callerId);

    // Consultar el rol usando admin client (bypasea RLS)
    const { data: perfilData, error: perfilErr } = await admin
      .from("perfiles")
      .select("rol")
      .eq("id", callerId)
      .single();

    if (perfilErr || !perfilData) {
      console.error("[create-nutricionista] Error al obtener perfil:", perfilErr?.message);
      return jsonError({ error: "No se pudo verificar tu identidad." }, 403);
    }

    if (perfilData.rol !== "superadmin") {
      console.warn("[create-nutricionista] Acceso denegado — rol:", perfilData.rol);
      return jsonError({ error: "Solo el superadmin puede crear nutricionistas." }, 403);
    }

    // ── 3. Leer y validar el body ─────────────────────────────────────────────
    const body = await req.json();
    const { nombre, email, password, plan } = body;

    if (!nombre?.trim()) return jsonError({ error: "El nombre es obligatorio." }, 400);
    if (!email?.trim() || !email.includes("@")) return jsonError({ error: "El email es invalido." }, 400);
    if (!password || password.length < 6) return jsonError({ error: "La contrasena debe tener al menos 6 caracteres." }, 400);

    const planValido  = ["starter", "pro", "clinic"].includes(plan) ? plan : "starter";
    const emailNorm   = email.trim().toLowerCase();
    const nombreNorm  = nombre.trim();

    console.log("[create-nutricionista] Creando:", emailNorm, "| plan:", planValido);

    // ── 4. Crear el usuario en Supabase Auth ──────────────────────────────────
    // IMPORTANTE: user_metadata debe tener { rol: 'nutricionista', nombre }
    // El trigger handle_new_user() lee estos valores para crear la fila en perfiles
    // El trigger handle_new_nutricionista() crea la fila en nutricionistas automaticamente
    const { data: authUser, error: authErr } = await admin.auth.admin.createUser({
      email: emailNorm,
      password,
      email_confirm: true, // confirmar email automaticamente — no necesita verificar
      user_metadata: {
        rol: "nutricionista",  // el trigger usa este campo
        nombre: nombreNorm,    // el trigger usa este campo
      },
    });

    if (authErr) {
      console.error("[create-nutricionista] Error al crear auth user:", authErr.message);

      if (
        authErr.message.includes("already registered") ||
        authErr.message.includes("already been registered") ||
        authErr.message.includes("duplicate") ||
        authErr.message.includes("already exists")
      ) {
        return jsonError({ error: "Ya existe una cuenta con ese email." }, 409);
      }
      return jsonError({ error: authErr.message }, 500);
    }

    const userId = authUser.user?.id;
    if (!userId) {
      console.error("[create-nutricionista] Auth user creado pero sin ID");
      return jsonError({ error: "Error interno al crear el usuario." }, 500);
    }

    console.log("[create-nutricionista] Auth user creado:", userId);

    // ── 5. Corregir perfil: agregar email y asegurar rol correcto ────────────
    // El trigger handle_new_user crea la fila en perfiles, pero:
    //   - No incluye el email (solo id, rol, nombre)
    //   - Si raw_user_meta_data->>'rol' no llega correctamente, defaultea a 'paciente'
    // Por eso forzamos el rol y email con un UPDATE explicito.
    const { error: updatePerfilErr } = await admin
      .from("perfiles")
      .update({ email: emailNorm, rol: "nutricionista" })
      .eq("id", userId);

    if (updatePerfilErr) {
      console.warn("[create-nutricionista] No se pudo actualizar perfil:", updatePerfilErr.message);
    } else {
      console.log("[create-nutricionista] Perfil actualizado — rol: nutricionista");
    }

    // ── 6. Garantizar fila en nutricionistas ──────────────────────────────────
    // El trigger handle_new_nutricionista solo dispara si el INSERT en perfiles
    // tenia rol='nutricionista'. Como el trigger de auth puede crear perfiles con
    // rol='paciente' inicialmente, hacemos un UPSERT directo para garantizarlo.
    const { error: nutriErr } = await admin
      .from("nutricionistas")
      .upsert({ id: userId, plan_suscripcion: planValido, estado: "activo" });

    if (nutriErr) {
      console.warn("[create-nutricionista] No se pudo upsert nutricionista:", nutriErr.message);
    } else {
      console.log("[create-nutricionista] Nutricionista registrado con plan:", planValido);
    }

    console.log("[create-nutricionista] Nutricionista creado exitosamente:", userId);

    return jsonOk({
      id: userId,
      nombre: nombreNorm,
      email: emailNorm,
      plan: planValido,
    });

  } catch (err) {
    console.error("[create-nutricionista] Excepcion inesperada:", err);
    return jsonError({ error: String(err) });
  }
});
