import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { resend } from "npm:resend@3.2.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { to, subject, body, replyTo } = await req.json();

    // Validate input
    if (!to || !subject || !body) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: to, subject, body",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get API key from environment
    const apiKey = Deno.env.get("RESEND_API_KEY");
    if (!apiKey) {
      console.error("❌ RESEND_API_KEY not found in environment");
      return new Response(
        JSON.stringify({
          error: "Email service not configured",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Resend with the API key
    const client = new resend.Resend(apiKey);

    // Send email
    console.log(`📧 Sending email to ${to} with subject: ${subject}`);
    const result = await client.emails.send({
      from: "AuraSphere CRM <noreply@aurasphere.com>",
      to: to,
      subject: subject,
      html: body,
      replyTo: replyTo || "support@aurasphere.com",
    });

    if (result.error) {
      console.error("❌ Email sending failed:", result.error);
      return new Response(
        JSON.stringify({
          error: "Failed to send email",
          details: result.error,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log("✅ Email sent successfully:", result.data?.id);
    return new Response(
      JSON.stringify({
        success: true,
        message: "Email sent successfully",
        emailId: result.data?.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Email proxy error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
