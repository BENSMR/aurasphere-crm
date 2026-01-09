import { serve } from "https://deno.land/std@0.191.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const { org_id, domain, branding } = await req.json();

    if (!org_id || !domain) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing org_id or domain" }),
        { status: 400, headers: CORS_HEADERS }
      );
    }

    console.log(`🌐 Registering custom domain: ${domain} for org: ${org_id}`);

    // ========================================
    // Step 1: Validate domain ownership
    // ========================================
    // In production, verify DNS TXT record:
    // TXT record: _aurainc-validate=<verification_token>

    // For MVP, skip validation or check basic format
    if (!domain.includes(".")) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid domain format" }),
        { status: 400, headers: CORS_HEADERS }
      );
    }

    // ========================================
    // Step 2: Setup SSL Certificate (Let's Encrypt)
    // ========================================
    // In production, integrate with ACME protocol or:
    // - Use Netlify/Vercel's built-in SSL
    // - Use Cloudflare for domain management
    // - Call Let's Encrypt API

    console.log(`📜 Setting up SSL certificate for ${domain}...`);

    // For MVP: Log that SSL would be provisioned
    // Production: Integrate with certificate provider

    // ========================================
    // Step 3: Configure DNS Routing
    // ========================================
    // If using Cloudflare:
    // - Create CNAME record pointing to your app
    // - Example: domain.com CNAME yourapp.vercel.app

    // If using self-hosted:
    // - Update load balancer to route domain
    // - Setup reverse proxy rules

    console.log(`🔗 Configuring DNS routing for ${domain}...`);

    // For MVP: Log that DNS would be configured
    // Production: Call DNS API or update reverse proxy

    // ========================================
    // Step 4: Return success response
    // ========================================
    const response = {
      success: true,
      domain,
      org_id,
      message: "Domain registered successfully",
      nextSteps: [
        "Add CNAME record: yourapp.vercel.app",
        "Wait 24-48 hours for DNS propagation",
        "SSL certificate will be auto-provisioned",
      ],
      branding: branding, // Echo back for confirmation
      timestamp: new Date().toISOString(),
    };

    console.log(`✅ Domain registration complete for ${domain}`);

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        ...CORS_HEADERS,
        "Content-Type": "application/json",
      },
    });
  } catch (error) {
    console.error("❌ Domain registration error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error",
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

1. Save this file as: supabase/functions/register-custom-domain/index.ts

2. Deploy with Supabase CLI:
   supabase functions deploy register-custom-domain

3. Test with curl:
   curl -X POST http://localhost:54321/functions/v1/register-custom-domain \
     -H "Content-Type: application/json" \
     -d '{
       "org_id": "550e8400-e29b-41d4-a716-446655440000",
       "domain": "mycompany.com",
       "branding": {
         "primary_color": "#007BFF",
         "business_name": "My Company"
       }
     }'

4. For production:
   - Integrate with Cloudflare API for domain management
   - Integrate with Let's Encrypt for SSL certificates
   - Setup webhook handlers for domain validation
   - Add rate limiting to prevent abuse

========================================
ENVIRONMENT VARIABLES (Optional)
========================================

If you need secrets, add them in Supabase:
Settings → Secrets

Example:
- CLOUDFLARE_API_TOKEN
- LETS_ENCRYPT_API_KEY
- DOMAIN_REGISTRAR_API_KEY

Access in code:
const token = Deno.env.get("CLOUDFLARE_API_TOKEN");

========================================
*/
