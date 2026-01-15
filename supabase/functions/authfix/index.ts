// supabase/functions/authfix/index.ts
// Secure auth proxy - keeps secrets server-side, prevents invalid api key errors
// Accepts user token via Authorization header for RLS enforcement

import { createClient } from 'npm:@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

console.log('🔐 AuthFix Edge Function initialized')
console.log(`📍 Supabase URL: ${SUPABASE_URL}`)

Deno.serve(async (req) => {
  try {
    // Extract user JWT from Authorization header
    const authHeader = req.headers.get('Authorization') || ''
    const userJwt = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null

    console.log(`🔍 Request: ${req.method} ${new URL(req.url).pathname}`)
    console.log(`🔐 Auth: ${userJwt ? 'User token provided (RLS will be enforced)' : 'No token (admin access)'}`)

    // Admin client - uses service role (keeps API key secure)
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

    // User-context client - only if token provided (RLS enforced)
    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: userJwt ? { headers: { Authorization: `Bearer ${userJwt}` } } : undefined,
    })

    // Use user context if available, otherwise fall back to admin
    const client = userJwt ? userClient : admin

    // Handle different routes
    const url = new URL(req.url)
    const path = url.pathname.replace('/functions/v1/authfix', '')

    // GET /authfix/cloud_expenses
    if (path === '/cloud_expenses' && req.method === 'GET') {
      const { data, error } = await client
        .from('cloud_expenses')
        .select('*')
        .limit(100)

      if (error) {
        console.error('❌ Query error:', error)
        return new Response(
          JSON.stringify({ error: error.message, code: error.code }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
      }

      console.log(`✅ Returned ${data?.length || 0} cloud expenses`)
      return new Response(JSON.stringify({ data }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // POST /authfix/signup - Create new user
    if (path === '/signup' && req.method === 'POST') {
      const body = await req.json()
      const { email, password } = body

      console.log(`📧 Signup attempt: ${email}`)

      const { data, error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: false,
      })

      if (error) {
        console.error('❌ Signup error:', error)
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
      }

      console.log(`✅ User created: ${data.user.id}`)
      return new Response(JSON.stringify({ user: data.user }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // POST /authfix/signin - Authenticate user
    if (path === '/signin' && req.method === 'POST') {
      const body = await req.json()
      const { email, password } = body

      console.log(`🔐 Sign in attempt: ${email}`)

      const { data, error } = await admin.auth.signInWithPassword(email, password)

      if (error) {
        console.error('❌ Sign in error:', error)
        return new Response(
          JSON.stringify({ error: error.message, code: error.code }),
          { status: 401, headers: { 'Content-Type': 'application/json' } }
        )
      }

      console.log(`✅ User authenticated: ${data.user.id}`)
      return new Response(JSON.stringify({ user: data.user, session: data.session }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Health check
    if (path === '/health' && req.method === 'GET') {
      return new Response(
        JSON.stringify({
          status: 'ok',
          supabaseUrl: SUPABASE_URL,
          timestamp: new Date().toISOString(),
        }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 404
    return new Response(
      JSON.stringify({ error: 'Not found', path }),
      { status: 404, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    console.error('❌ Function error:', e)
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
