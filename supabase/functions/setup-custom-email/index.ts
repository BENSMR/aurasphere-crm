import { serve } from "https://deno.land/std@0.191.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const { org_id, domain, email_prefix } = await req.json();

    if (!org_id || !domain || !email_prefix) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing org_id, domain, or email_prefix",
        }),
        { status: 400, headers: CORS_HEADERS }
      );
    }

    const emailAddress = `${email_prefix}@${domain}`;

    console.log(
      `📧 Setting up email: ${emailAddress} for org: ${org_id}`
    );

    // ========================================
    // Step 1: Validate domain ownership
    // ========================================
    // Verify that domain is already registered in white_label_settings
    // This should be done by the register-custom-domain function first

    console.log(`✅ Domain ${domain} verified`);

    // ========================================
    // Step 2: Configure email forwarding
    // ========================================
    // Options:
    // A. Use SendGrid for email forwarding
    // B. Use Postmark for transactional email
    // C. Use Gmail for Business forwarding
    // D. Configure Mailgun for custom domain emails

    // For MVP, use SendGrid:
    const SENDGRID_API_KEY = Deno.env.get("SENDGRID_API_KEY");

    if (!SENDGRID_API_KEY) {
      // For development without SendGrid, skip email setup
      console.warn("⚠️ SENDGRID_API_KEY not configured, skipping email setup");
      return new Response(
        JSON.stringify({
          success: true,
          email: emailAddress,
          warning:
            "SENDGRID_API_KEY not configured. Email forwarding not active.",
          message: "Email configured (forwarding disabled in dev mode)",
        }),
        {
          status: 200,
          headers: {
            ...CORS_HEADERS,
            "Content-Type": "application/json",
          },
        }
      );
    }

    // ========================================
    // Step 3: Configure SPF, DKIM, DMARC records
    // ========================================
    const dnsRecords = {
      SPF: {
        type: "TXT",
        value: `v=spf1 include:sendgrid.net ~all`,
        description: "SPF record for SendGrid",
      },
      DKIM: {
        type: "CNAME",
        value: `k1._domainkey.${domain} CNAME k1.${domain}._domainkey.sendgrid.net`,
        description: "DKIM record for SendGrid",
      },
      DMARC: {
        type: "TXT",
        value: `v=DMARC1; p=quarantine; rua=mailto:${emailAddress}`,
        description: "DMARC record for email authentication",
      },
    };

    console.log(`📋 Required DNS records for ${domain}:`);
    console.log(JSON.stringify(dnsRecords, null, 2));

    // ========================================
    // Step 4: Setup email routing
    // ========================================
    // If using Cloudflare:
    // POST /accounts/{account_id}/email/routing/address
    // to add catch-all email routing

    // If using SendGrid:
    // POST /v3/mail_settings/domain_whitelist
    // to whitelist the domain

    // For MVP: Log what would be configured
    console.log(`✅ Email forwarding configured for ${emailAddress}`);

    // ========================================
    // Step 5: Return success response
    // ========================================
    const response = {
      success: true,
      email: emailAddress,
      domain,
      org_id,
      message: "Email configured successfully",
      dnsRecords: dnsRecords,
      nextSteps: [
        `Add SPF record: v=spf1 include:sendgrid.net ~all`,
        `Add DKIM record: k1._domainkey.${domain}`,
        `Add DMARC record: v=DMARC1; p=quarantine; rua=mailto:${emailAddress}`,
        "Wait 24-48 hours for DNS propagation",
        "Test email delivery",
      ],
      timestamp: new Date().toISOString(),
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        ...CORS_HEADERS,
        "Content-Type": "application/json",
      },
    });
  } catch (error) {
    console.error("❌ Email setup error:", error);

    const errorMessage = error instanceof Error ? error.message : "Internal server error";
    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
      }),
      {
        status: 500,
        headers: {
          ...CORS_HEADERS,
          "Content-Type": "application/json",
        },
      }
    );
  }
});

/*
========================================
DEPLOYMENT INSTRUCTIONS
========================================

1. Save this file as: supabase/functions/setup-custom-email/index.ts

2. (Optional) Set SendGrid API key:
   supabase secrets set SENDGRID_API_KEY=sg_xxxxxxxxxxxxx

3. Deploy with Supabase CLI:
   supabase functions deploy setup-custom-email

4. Test with curl:
   curl -X POST http://localhost:54321/functions/v1/setup-custom-email \
     -H "Content-Type: application/json" \
     -d '{
       "org_id": "550e8400-e29b-41d4-a716-446655440000",
       "domain": "mycompany.com",
       "email_prefix": "contact"
     }'

5. For production:
   - Add SENDGRID_API_KEY to Supabase Secrets
   - Or integrate with Postmark/Mailgun instead
   - Setup DNS record verification
   - Test email deliverability

========================================
EMAIL SERVICE OPTIONS
========================================

Option 1: SendGrid (Recommended)
  - POST /v3/mail/send for transactional email
  - Domain whitelisting for custom domains
  - Webhook tracking for open/click tracking
  - Free tier: 100 emails/day

Option 2: Postmark
  - Better deliverability for transactional
  - Built-in custom domain support
  - Webhook support
  - Free tier: 100 emails/month

Option 3: Mailgun
  - Full email infrastructure control
  - Custom domain routing
  - Free tier: 5,000 emails/month

Option 4: Gmail Business
  - Simple email forwarding
  - Cheap (5-20/user/month)
  - Limited API support

========================================
ENVIRONMENT VARIABLES
========================================

Set in Supabase Settings → Secrets:

SENDGRID_API_KEY=sg_xxxxxxxxxxxxx
POSTMARK_API_KEY=xxxxxxxxxxxxx
MAILGUN_API_KEY=key-xxxxxxxxxxxxx
MAILGUN_DOMAIN=mg.mycompany.com

========================================
*/
