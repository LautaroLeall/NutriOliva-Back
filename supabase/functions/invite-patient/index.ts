// invite-patient/index.ts
// Edge Function de Supabase — envia una invitacion al paciente recien creado
// usando la API Admin de Supabase Auth para generar un link de magic link.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  // Preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { paciente_id, nombre, email } = await req.json()

    if (!email || !nombre || !paciente_id) {
      return new Response(
        JSON.stringify({ error: 'Faltan datos requeridos: paciente_id, nombre, email' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Crear cliente Admin con service_role (variables de entorno de Supabase)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // Invitar al usuario: Supabase crea la cuenta y envia el mail de invitacion
    const { data, error } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
      data: {
        nombre,
        paciente_id,
        rol: 'paciente',
      },
      redirectTo: `${Deno.env.get('SITE_URL') ?? 'http://localhost:5173'}/login`,
    })

    if (error) {
      console.error('[invite-patient] Error al invitar:', error)
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('[invite-patient] Invitacion enviada a:', email, '| user_id:', data.user?.id)

    return new Response(
      JSON.stringify({ success: true, user_id: data.user?.id }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('[invite-patient] Excepcion:', err)
    return new Response(
      JSON.stringify({ error: 'Error interno del servidor.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
