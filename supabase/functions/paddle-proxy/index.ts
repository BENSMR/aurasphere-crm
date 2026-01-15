// Paddle API Proxy
// File: supabase/functions/paddle-proxy/index.ts
// Handles all Paddle API calls securely with keys in Supabase Secrets

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const PADDLE_API_KEY = Deno.env.get("PADDLE_API_KEY");
const baseUrl = "https://api.paddle.com/v1";

interface PaddleProxyRequest {
  action: string;
  [key: string]: any;
}

serve(async (req: Request) => {
  console.log("💳 Paddle Proxy - Request received");

  if (!PADDLE_API_KEY) {
    console.error("❌ PADDLE_API_KEY not configured in Secrets");
    return new Response(
      JSON.stringify({
        success: false,
        error: "Paddle API key not configured",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  try {
    const body = (await req.json()) as PaddleProxyRequest;
    const { action, ...params } = body;

    let response;

    switch (action) {
      case "create_customer":
        response = await fetch(`${baseUrl}/customers`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${PADDLE_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            email: params.email,
            name: params.name,
            country_code: params.country_code || "US",
          }),
        });
        const customerData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            customer_id: customerData.data?.id,
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
            Authorization: `Bearer ${PADDLE_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            customer_id: params.customer_id,
            items: [
              {
                price_id: params.price_id,
              },
            ],
            billing_cycle: params.billing_cycle || {
              interval: "month",
              frequency: 1,
            },
          }),
        });
        const subData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: subData.data,
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
              Authorization: `Bearer ${PADDLE_API_KEY}`,
            },
          }
        );
        const getSubData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: getSubData.data,
            error: !response.ok ? getSubData.error?.message : null,
          }),
          {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          }
        );

      case "cancel_subscription":
        response = await fetch(
          `${baseUrl}/subscriptions/${params.subscription_id}/cancel`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${PADDLE_API_KEY}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({}),
          }
        );
        const cancelData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: cancelData.data,
            error: !response.ok ? cancelData.error?.message : null,
          }),
          {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          }
        );

      case "update_subscription":
        response = await fetch(
          `${baseUrl}/subscriptions/${params.subscription_id}`,
          {
            method: "PATCH",
            headers: {
              Authorization: `Bearer ${PADDLE_API_KEY}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              items: [
                {
                  price_id: params.new_price_id,
                },
              ],
            }),
          }
        );
        const updateData = await response.json();
        return new Response(
          JSON.stringify({
            success: response.ok,
            subscription: updateData.data,
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
    console.error("❌ Paddle Proxy Error:", error);
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
