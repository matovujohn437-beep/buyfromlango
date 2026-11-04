import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-api-version, x-requested-with",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

const invalidCredentials = () =>
  Response.json(
    { error: "Phone number or password is incorrect." },
    { status: 401, headers: corsHeaders },
  )

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }
  if (request.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: corsHeaders,
    })
  }

  const url = Deno.env.get("SUPABASE_URL")
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
  const publicKey =
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
    Deno.env.get("SUPABASE_ANON_KEY")
  if (!url || !serviceRoleKey || !publicKey) {
    console.error("Phone login function is missing Supabase environment settings.")
    return new Response("Phone sign-in is unavailable.", {
      status: 503,
      headers: corsHeaders,
    })
  }

  let body: unknown
  try {
    body = await request.json()
  } catch {
    return invalidCredentials()
  }
  if (
    typeof body !== "object" ||
    body === null ||
    !("phone" in body) ||
    !("password" in body) ||
    typeof body.phone !== "string" ||
    typeof body.password !== "string" ||
    !/^\+256[0-9]{9}$/.test(body.phone) ||
    body.password.length === 0
  ) {
    return invalidCredentials()
  }

  const admin = createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const auth = createClient(url, publicKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  try {
    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("id")
      .eq("phone", body.phone)
      .maybeSingle()
    if (profileError) {
      console.error("Phone login profile lookup failed.", profileError)
      return new Response("Phone sign-in is temporarily unavailable.", {
        status: 503,
        headers: corsHeaders,
      })
    }

    if (!profile) {
      await auth.auth.signInWithPassword({
        email: "phone-login-invalid-user@buyfromlango.invalid",
        password: body.password,
      })
      return invalidCredentials()
    }

    const { data: userResult, error: userError } =
      await admin.auth.admin.getUserById(profile.id)
    if (userError || !userResult.user?.email) {
      return invalidCredentials()
    }

    const { data: signIn, error: signInError } =
      await auth.auth.signInWithPassword({
        email: userResult.user.email,
        password: body.password,
      })
    if (signInError || !signIn.session) return invalidCredentials()

    return Response.json(
      { refresh_token: signIn.session.refresh_token },
      { headers: corsHeaders },
    )
  } catch (error) {
    console.error(
      "Phone login request failed.",
      error instanceof Error ? error.message : "Unknown error",
    )
    return new Response("Phone sign-in is temporarily unavailable.", {
      status: 503,
      headers: corsHeaders,
    })
  }
})
