// Stripe API Proxy
// File: supabase/functions/stripe-proxy/index.ts
// Handles all Stripe API calls securely with keys in Supabase Secrets

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const baseUrl = "https://api.stripe.com/v1";

interface StripeProxyRequest {
  action: string;
  [key: string]: any;
}

serve(async (req: Request) => {
  console.log("💳 Stripe Proxy - Request received");

  if (!STRIPE_SECRET_KEY) {
    console.error("❌ STRIPE_SECRET_KEY not configured in Secrets");
    return new Response(
      JSON.stringify({
        success: false,
        error: "Stripe API key not configured",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  try {
    const body = (await req.json()) as StripeProxyRequest;
    const { action, ...params } = body;

    let response;

    switch (action) {
      case "create_customer":
        response = await fetch(`${baseUrl}/customers`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            email: params.email,
            name: params.name,
            "metadata[user_type]": params.metadata?.user_type || "crm_user",
          }).toString(),
        });
        const customerData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            customer_id: customerData.id,
            error: !response.ok ? customerData.error?.message : null,
          }),
          {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          }
        );

      case "create_subscription":
        response = await fetch(`${baseUrl}/subscriptions`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            customer: params.customer_id,
            "items[0][price]": params.price_id,
            payment_behavior: params.payment_behavior || "default_incomplete",
            "payment_settings[save_default_payment_method]": "on_subscription",
            "expand[]": "latest_invoice.payment_intent",
          }).toString(),
        });
        const subData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: subData,
            error: !response.ok ? subData.error?.message : null,
          }),
          {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          }
        );

      case "get_subscription":
        response = await fetch(
          `${baseUrl}/subscriptions/${params.subscription_id}`,
          {
            method: "GET",
            headers: {
              Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
            },
          }
        );
        const getSubData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: getSubData,
            error: !response.ok ? getSubData.error?.message : null,
          }),
          {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          }
        );

      case "cancel_subscription":
        response = await fetch(
          `${baseUrl}/subscriptions/${params.subscription_id}`,
          {
            method: "DELETE",
            headers: {
              Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
            },
          }
        );
        const cancelData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: cancelData,
            error: !response.ok ? cancelData.error?.message : null,
          }),
          {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          }
        );

      case "update_subscription":
        // Get current subscription first
        const currentResponse = await fetch(
          `${baseUrl}/subscriptions/${params.subscription_id}`,
          {
            method: "GET",
            headers: {
              Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
            },
          }
        );
        const currentSub = await currentResponse.json();
        const itemId = currentSub.items.data[0].id;

        // Update the subscription item
        response = await fetch(`${baseUrl}/subscription_items/${itemId}`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            price: params.new_price_id,
            proration_behavior: params.proration_behavior || "create_prorations",
          }).toString(),
        });
        const updateData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: updateData,
            error: !response.ok ? updateData.error?.message : null,
          }),
          {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          }
        );

      default:
        return new Response(
          JSON.stringify({ success: false, error: `Unknown action: ${action}` }),
          {
            status: 400,
            headers: { "Content-Type": "application/json" },
          }
        );
    }
  } catch (error) {
    console.error("❌ Stripe Proxy Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
