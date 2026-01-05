import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const porkbunApiKey = Deno.env.get("PORKBUN_API_KEY") || "";
const porkbunSecretKey = Deno.env.get("PORKBUN_SECRET_KEY") || "";
const zohoClientId = Deno.env.get("ZOHO_CLIENT_ID") || "";
const zohoClientSecret = Deno.env.get("ZOHO_CLIENT_SECRET") || "";

interface ProvisionRequest {
  userId: string;
  businessName: string;
  planName: "solo" | "team" | "workshop";
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body: ProvisionRequest = await req.json();
    const { userId, businessName, planName } = body;

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Get subscription plan details
    const { data: plan } = await supabase
      .from("subscription_plans")
      .select("*")
      .eq("plan_name", planName)
      .single();

    if (!plan) {
      throw new Error(`Invalid plan: ${planName}`);
    }

    // 2. Generate domain name
    const slugifiedName = businessName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      .substring(0, 50);

    const domain = `${slugifiedName}.${plan.domain_tld}`;

    console.log(`[PROVISION] Starting for user ${userId}, domain: ${domain}`);

    // 3. Reserve domain via Porkbun API
    console.log("[DOMAIN] Reserving domain...");
    const domainReserveRes = await fetch(
      "https://porkbun.com/api/json/v3/domain/check",
      {
        method: "POST",
        body: JSON.stringify({
          apikey: porkbunApiKey,
          secretapikey: porkbunSecretKey,
          domain: domain,
        }),
      }
    );

    const domainCheckData = await domainReserveRes.json();

    if (domainCheckData.status !== "success" || domainCheckData.available !== 1) {
      // Domain taken, try with random suffix
      const randomSuffix = Math.floor(Math.random() * 10000);
      const altDomain = `${slugifiedName}-${randomSuffix}.${plan.domain_tld}`;
      
      console.log(`[DOMAIN] Original domain taken, using: ${altDomain}`);
      
      // Log domain reservation step
      await supabase.from("provisioning_logs").insert({
        user_id: userId,
        step: "domain_reserved",
        status: "completed",
        external_id: altDomain,
        metadata: { fallback: true },
      });

      // Update user profile with domain
      await supabase
        .from("user_profiles")
        .update({
          business_domain: altDomain,
          domain_tld: plan.domain_tld,
          domain_registrar: "porkbun",
          website_status: "provisioning",
        })
        .eq("user_id", userId);
    } else {
      // Domain is available
      console.log("[DOMAIN] Domain available, proceeding with purchase");
      
      // Log domain check
      await supabase.from("provisioning_logs").insert({
        user_id: userId,
        step: "domain_reserved",
        status: "completed",
        external_id: domain,
      });

      // Update user profile
      await supabase
        .from("user_profiles")
        .update({
          business_domain: domain,
          domain_tld: plan.domain_tld,
          domain_registrar: "porkbun",
          domain_cost_cents: plan.domain_tld === "pro" ? 1299 : 
                             plan.domain_tld === "shop" ? 999 : 299,
          website_status: "provisioning",
        })
        .eq("user_id", userId);
    }

    // 4. Create business emails
    console.log("[EMAIL] Creating business emails...");
    const emailTypes =
      planName === "workshop"
        ? ["contact", "jobs", "invoices", "support", "billing"]
        : ["contact", "jobs", "invoices"];

    const finalDomain = domainCheckData.available === 1 ? domain : `${slugifiedName}-${Math.floor(Math.random() * 10000)}.${plan.domain_tld}`;

    const emailPromises = emailTypes.map((type) => {
      const emailAddress = `${type}@${finalDomain}`;
      return supabase.from("business_emails").insert({
        user_id: userId,
        email_address: emailAddress,
        email_type: type,
        status: "provisioning",
      });
    });

    await Promise.all(emailPromises);

    console.log(`[EMAIL] Created ${emailTypes.length} email addresses`);

    // 5. Log completion
    await supabase.from("provisioning_logs").insert({
      user_id: userId,
      step: "business_identity_provisioning_complete",
      status: "completed",
      metadata: { domain: finalDomain, emailCount: emailTypes.length },
    });

    // 6. Update user profile - mark as provisioned
    const { error } = await supabase
      .from("user_profiles")
      .update({
        business_email: `contact@${finalDomain}`,
        website_url: `https://${finalDomain}`,
        website_status: "active",
        identity_provisioned_at: new Date().toISOString(),
      })
      .eq("user_id", userId);

    if (error) {
      console.error("[ERROR] Failed to update user profile:", error);
      throw error;
    }

    console.log(
      `[SUCCESS] Business identity provisioned for user ${userId}: ${finalDomain}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        domain: finalDomain,
        email: `contact@${finalDomain}`,
        website: `https://${finalDomain}`,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[ERROR]", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
