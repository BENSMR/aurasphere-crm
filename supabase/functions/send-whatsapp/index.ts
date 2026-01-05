import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WhatsAppRequest {
  to: string
  message: string
  org_id: string
  client_id?: string
  idempotency_key: string
  timestamp: string
}

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify authentication
    const authHeader = req.headers.get('authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    
    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: { headers: { Authorization: `Bearer ${token}` } },
      }
    )

    // Verify user is authenticated
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body: WhatsAppRequest = await req.json()

    // ✅ VALIDATION
    if (!body.to || !body.message || !body.org_id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: to, message, org_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate phone number format (E.164)
    if (!/^\+[1-9]\d{1,14}$/.test(body.to)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid phone number. Use E.164 format: +country_code + number' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate message length
    if (body.message.length === 0 || body.message.length > 4096) {
      return new Response(
        JSON.stringify({ success: false, error: 'Message must be 1-4096 characters' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ✅ AUTHORIZATION: Verify user belongs to organization
    const { data: org, error: orgError } = await supabase
      .from('organizations')
      .select('id')
      .eq('id', body.org_id)
      .eq('owner_id', user.id)
      .maybeSingle()

    if (orgError || !org) {
      return new Response(
        JSON.stringify({ success: false, error: 'Organization not found or access denied' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ✅ IDEMPOTENCY: Check if message already sent
    const { data: existingMsg } = await supabase
      .from('whatsapp_messages')
      .select('id, status')
      .eq('idempotency_key', body.idempotency_key)
      .maybeSingle()

    if (existingMsg) {
      console.log('Idempotent message detected. Returning existing message ID:', existingMsg.id)
      return new Response(
        JSON.stringify({
          success: true,
          messageId: existingMsg.id,
          status: existingMsg.status,
          duplicate: true,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ✅ GET API KEY from Supabase Secrets (NOT from environment)
    const whatsappApiKey = Deno.env.get('WHATSAPP_API_KEY')
    const whatsappPhoneNumberId = Deno.env.get('WHATSAPP_PHONE_NUMBER_ID')

    if (!whatsappApiKey || !whatsappPhoneNumberId) {
      console.error('WhatsApp API credentials not configured')
      return new Response(
        JSON.stringify({ success: false, error: 'WhatsApp service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ✅ SEND MESSAGE VIA WHATSAPP API
    const whatsappResponse = await fetch(
      `https://graph.instagram.com/v18.0/${whatsappPhoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${whatsappApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to: body.to,
          type: 'text',
          text: {
            preview_url: false,
            body: body.message,
          },
        }),
      }
    )

    const whatsappData = await whatsappResponse.json()

    if (!whatsappResponse.ok) {
      console.error('WhatsApp API error:', whatsappData)
      return new Response(
        JSON.stringify({
          success: false,
          error: whatsappData.error?.message || 'Failed to send WhatsApp message',
        }),
        { status: whatsappResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ✅ STORE MESSAGE IN DATABASE
    const { data: insertedMsg, error: insertError } = await supabase
      .from('whatsapp_messages')
      .insert({
        org_id: body.org_id,
        user_id: user.id,
        phone_number: body.to,
        message_content: body.message,
        message_id: whatsappData.messages[0]?.id,
        contact_id: body.client_id,
        idempotency_key: body.idempotency_key,
        status: 'sent',
        created_at: body.timestamp,
      })
      .select('id')
      .single()

    if (insertError) {
      console.error('Database insert error:', insertError)
      // Don't fail the response - message was sent, just logging failed
    }

    // ✅ SUCCESS RESPONSE
    return new Response(
      JSON.stringify({
        success: true,
        messageId: insertedMsg?.id || whatsappData.messages[0]?.id,
        whatsappId: whatsappData.messages[0]?.id,
        status: 'sent',
        recipient: body.to,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
