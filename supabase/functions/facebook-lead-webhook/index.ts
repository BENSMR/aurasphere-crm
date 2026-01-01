import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as crypto from "https://deno.land/std@0.208.0/crypto/mod.ts";

// Initialize Supabase
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Facebook Configuration
const FACEBOOK_APP_SECRET = Deno.env.get("FACEBOOK_APP_SECRET")!;
const FACEBOOK_ACCESS_TOKEN = Deno.env.get("FACEBOOK_ACCESS_TOKEN")!;
const FACEBOOK_API_VERSION = "v18.0";

interface FacebookLead {
  id: string;
  field_data: Array<{
    name: string;
    values: string[];
  }>;
  created_time: string;
  ad_id?: string;
  adset_id?: string;
  campaign_id?: string;
  form_id?: string;
}

interface WebhookPayload {
  object: string;
  entry: Array<{
    id: string;
    time: number;
    messaging?: any[];
    changes?: Array<{
      value: {
        form_id: string;
        lead_id: string;
        leadgen_export_id?: string;
        created_time: number;
        ad_id?: string;
        adset_id?: string;
        campaign_id?: string;
      };
      field: string;
    }>;
  }>;
}

/**
 * ✅ Verify Facebook webhook signature
 * This prevents unauthorized requests
 */
function verifyWebhookSignature(
  payload: string,
  signature: string
): boolean {
  const hash = crypto.subtle.digestSync(
    "SHA256",
    new TextEncoder().encode(payload + FACEBOOK_APP_SECRET)
  );
  const hex = Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  const expectedSignature = "sha256=" + hex;
  return expectedSignature === signature;
}

/**
 * ✅ Fetch lead details from Facebook Graph API
 */
async function fetchLeadDetails(leadId: string): Promise<FacebookLead | null> {
  const url = `https://graph.facebook.com/${FACEBOOK_API_VERSION}/${leadId}?access_token=${FACEBOOK_ACCESS_TOKEN}`;

  const response = await fetch(url);
  if (!response.ok) {
    console.error(
      `❌ Failed to fetch lead ${leadId}:`,
      await response.text()
    );
    return null;
  }

  return response.json();
}

/**
 * ✅ Extract field values from Facebook lead
 */
function extractLeadData(lead: FacebookLead) {
  const data: Record<string, string> = {};

  for (const field of lead.field_data || []) {
    const [firstValue] = field.values;
    data[field.name] = firstValue || "";
  }

  return {
    email: data["email"] || "",
    phone: data["phone_number"] || "",
    firstName: data["first_name"] || "",
    lastName: data["last_name"] || "",
    fullName: data["full_name"] || `${data["first_name"]} ${data["last_name"]}`,
    createdTime: lead.created_time,
  };
}

/**
 * ✅ Insert or update client in Supabase
 */
async function insertOrUpdateClient(leadData: any, orgId: string) {
  // Check if client already exists by email
  const { data: existing, error: selectError } = await supabase
    .from("clients")
    .select("id")
    .eq("email", leadData.email)
    .eq("organization_id", orgId)
    .single();

  if (selectError && selectError.code !== "PGRST116") {
    console.error("❌ Error checking existing client:", selectError);
    return null;
  }

  if (existing) {
    // Update existing client
    const { data, error } = await supabase
      .from("clients")
      .update({
        phone: leadData.phone || null,
        name: leadData.fullName,
        updated_at: new Date().toISOString(),
      })
      .eq("id", existing.id)
      .select()
      .single();

    if (error) {
      console.error("❌ Failed to update client:", error);
      return null;
    }
    console.log("✅ Updated existing client:", data.id);
    return data;
  } else {
    // Create new client
    const { data, error } = await supabase
      .from("clients")
      .insert({
        organization_id: orgId,
        email: leadData.email,
        phone: leadData.phone || null,
        name: leadData.fullName,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        source: "facebook_lead_ads", // Track source
      })
      .select()
      .single();

    if (error) {
      console.error("❌ Failed to create client:", error);
      return null;
    }
    console.log("✅ Created new client:", data.id);
    return data;
  }
}

/**
 * ✅ Main webhook handler
 */
serve(async (req: Request) => {
  // Handle webhook verification (GET request from Facebook)
  if (req.method === "GET") {
    const url = new URL(req.url);
    const mode = url.searchParams.get("hub.mode");
    const challenge = url.searchParams.get("hub.challenge");
    const verifyToken = url.searchParams.get("hub.verify_token");

    // Use WHATSAPP_WEBHOOK_VERIFY_TOKEN from env (same as WhatsApp setup)
    const expectedToken = Deno.env.get("WHATSAPP_WEBHOOK_VERIFY_TOKEN");

    if (mode === "subscribe" && verifyToken === expectedToken) {
      console.log("✅ Webhook verified");
      return new Response(challenge, { status: 200 });
    } else {
      console.error("❌ Webhook verification failed");
      return new Response("Forbidden", { status: 403 });
    }
  }

  // Handle webhook events (POST request from Facebook)
  if (req.method === "POST") {
    const signature = req.headers.get("x-hub-signature-256") || "";
    const body = await req.text();

    // Verify signature
    if (!verifyWebhookSignature(body, signature)) {
      console.error("❌ Invalid webhook signature");
      return new Response("Unauthorized", { status: 401 });
    }

    const payload: WebhookPayload = JSON.parse(body);

    console.log("📨 Received webhook payload:", JSON.stringify(payload, null, 2));

    if (payload.object !== "page") {
      console.warn("⚠️ Webhook object is not 'page':", payload.object);
      return new Response("OK", { status: 200 });
    }

    // Process each entry
    for (const entry of payload.entry) {
      for (const change of entry.changes || []) {
        if (change.field === "leadgen") {
          const leadId = change.value.lead_id;
          const formId = change.value.form_id;

          console.log(
            `📝 Processing lead: ${leadId} from form: ${formId}`
          );

          try {
            // Fetch lead details from Facebook
            const lead = await fetchLeadDetails(leadId);
            if (!lead) {
              console.warn(`⚠️ Could not fetch lead details for ${leadId}`);
              continue;
            }

            // Extract data
            const leadData = extractLeadData(lead);
            console.log("📋 Extracted lead data:", leadData);

            // Get organization ID (you can store form_id → org_id mapping)
            // For now, we'll use a hardcoded org_id or get it from form metadata
            // In production, you'd query a form_config table
            const orgId = Deno.env.get("DEFAULT_ORG_ID") || "default-org";

            // Insert/update client
            const client = await insertOrUpdateClient(leadData, orgId);

            if (client) {
              console.log(
                `✅ Lead ${leadId} successfully processed as client:`,
                client.id
              );
            }
          } catch (error) {
            console.error(`❌ Error processing lead ${leadId}:`, error);
            continue;
          }
        }
      }
    }

    return new Response("OK", { status: 200 });
  }

  return new Response("Method not allowed", { status: 405 });
});
