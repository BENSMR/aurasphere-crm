// Test Supabase Secrets Connection
// File: supabase/functions/verify-secrets/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  console.log("🔐 Verifying Supabase Secrets...")

  const secrets = {
    STRIPE_SECRET_KEY: {
      name: "Stripe Secret Key",
      value: Deno.env.get("STRIPE_SECRET_KEY"),
      expected_prefix: "sk_",
      optional: false,
    },
    STRIPE_PUBLIC_KEY: {
      name: "Stripe Public Key",
      value: Deno.env.get("STRIPE_PUBLIC_KEY"),
      expected_prefix: "pk_",
      optional: false,
    },
    RESEND_API_KEY: {
      name: "Resend API Key",
      value: Deno.env.get("RESEND_API_KEY"),
      expected_prefix: "re_",
      optional: false,
    },
    GROQ_API_KEY: {
      name: "Groq API Key",
      value: Deno.env.get("GROQ_API_KEY"),
      expected_prefix: "gsk_",
      optional: false,
    },
    TWILIO_ACCOUNT_SID: {
      name: "Twilio Account SID",
      value: Deno.env.get("TWILIO_ACCOUNT_SID"),
      expected_prefix: "AC",
      optional: true,
    },
    TWILIO_AUTH_TOKEN: {
      name: "Twilio Auth Token",
      value: Deno.env.get("TWILIO_AUTH_TOKEN"),
      expected_prefix: "",
      optional: true,
    },
    OCR_API_KEY: {
      name: "OCR API Key",
      value: Deno.env.get("OCR_API_KEY"),
      expected_prefix: "",
      optional: true,
    },
  }

  const results = {
    timestamp: new Date().toISOString(),
    project_url: "https://fppmvibvpxrkwmymszhd.supabase.co",
    secrets: {} as Record<string, any>,
    summary: {
      total: 0,
      configured: 0,
      missing: 0,
      invalid: 0,
    },
  }

  // Check each secret
  for (const [key, secret] of Object.entries(secrets)) {
    results.summary.total++

    if (!secret.value) {
      if (secret.optional) {
        results.secrets[key] = {
          name: secret.name,
          status: "⚠️ OPTIONAL (not configured)",
          configured: false,
          error: "Missing (but optional)",
        }
      } else {
        results.summary.missing++
        results.secrets[key] = {
          name: secret.name,
          status: "❌ MISSING",
          configured: false,
          error: "Key not found in Supabase Secrets",
          hint: `Add to Supabase: Settings → Secrets → Add "${key}"`,
        }
      }
      continue
    }

    results.summary.configured++

    // Validate format
    if (
      secret.expected_prefix &&
      !secret.value.startsWith(secret.expected_prefix)
    ) {
      results.summary.invalid++
      results.secrets[key] = {
        name: secret.name,
        status: "⚠️ INVALID FORMAT",
        configured: true,
        error: `Expected to start with "${secret.expected_prefix}"`,
        value_start: secret.value.substring(0, 10) + "***",
      }
    } else {
      results.secrets[key] = {
        name: secret.name,
        status: "✅ CONFIGURED",
        configured: true,
        value_preview: secret.value.substring(0, 20) + "***",
        length: secret.value.length,
      }
    }
  }

  // Overall status
  if (results.summary.missing === 0 && results.summary.invalid === 0) {
    results.summary.status = "✅ ALL SECRETS CONFIGURED"
  } else if (results.summary.missing > 0) {
    results.summary.status =
      "❌ MISSING SECRETS - Please add them to Supabase"
  } else {
    results.summary.status = "⚠️ SOME SECRETS INVALID - Check format"
  }

  // Log results
  console.log(JSON.stringify(results, null, 2))

  return new Response(JSON.stringify(results), {
    headers: { "Content-Type": "application/json" },
  })
})
