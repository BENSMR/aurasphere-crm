# 🔐 SUPABASE API KEYS IN SECRETS - COMPLETE SETUP

**Purpose**: Store all API keys securely in Supabase Secrets  
**Your Supabase Project**: `fppmvibvpxrkwmymszhd`  
**URL**: `https://fppmvibvpxrkwmymszhd.supabase.co`

---

## 🎯 QUICK START

### **Your Project Details**
```
Supabase URL:  https://fppmvibvpxrkwmymszhd.supabase.co
Project ID:    fppmvibvpxrkwmymszhd
Already Setup: ✅ Supabase initialized
```

---

## 📋 API KEYS YOU NEED TO ADD

| Service | Key Name | Where to Get | Status |
|---------|----------|--------------|--------|
| **Stripe** | `STRIPE_SECRET_KEY` | stripe.com/developers | ⏳ Add |
| **Stripe** | `STRIPE_PUBLIC_KEY` | stripe.com/developers | ⏳ Add |
| **Resend** | `RESEND_API_KEY` | resend.com | ⏳ Add |
| **Groq** | `GROQ_API_KEY` | groq.com | ⏳ Add |
| **Twilio** | `TWILIO_ACCOUNT_SID` | twilio.com | ⏳ Optional |
| **Twilio** | `TWILIO_AUTH_TOKEN` | twilio.com | ⏳ Optional |
| **OCR** | `OCR_API_KEY` | ocr.space | ⏳ Optional |

---

## 🚀 3-STEP SETUP PROCESS

### **STEP 1: Get Your API Keys** (10 minutes)

#### **Stripe Keys** (Payment Processing)
```
1. Go to: https://dashboard.stripe.com
2. Login with your account
3. Click: Developers (top right)
4. Click: API Keys
5. Copy BOTH:
   - Publishable Key (pk_live_...)  → STRIPE_PUBLIC_KEY
   - Secret Key (sk_live_...)       → STRIPE_SECRET_KEY

   (Use pk_test_ and sk_test_ for development)
```

#### **Resend Key** (Email Service)
```
1. Go to: https://resend.com
2. Login with your account
3. Click: API Keys (left sidebar)
4. Copy your API Key (re_...)
5. Note: RESEND_API_KEY
```

#### **Groq Key** (AI/LLM)
```
1. Go to: https://console.groq.com
2. Login with your account
3. Click: API Keys (top right)
4. Create/copy API Key (gsk_...)
5. Note: GROQ_API_KEY
```

#### **Twilio (Optional - WhatsApp)**
```
1. Go to: https://www.twilio.com
2. Login with your account
3. Navigate: Account Settings → API Keys & Tokens
4. Copy:
   - Account SID      → TWILIO_ACCOUNT_SID
   - Auth Token       → TWILIO_AUTH_TOKEN
```

---

### **STEP 2: Add Secrets to Supabase**

#### **Method A: Web Dashboard (Easiest)**

```
1. Go to: https://app.supabase.com
2. Select your project: "aura-crm"
3. Click: Settings (bottom left)
4. Click: Secrets tab (top menu)
5. Click: "Add secret" button

For EACH secret, fill in:
   Name:  STRIPE_SECRET_KEY
   Value: sk_live_actual_key_here
   Click: Save

Repeat for all keys above
```

**Important**: After adding each secret, you'll see:
```
✅ Secret added successfully
(The value is now encrypted and hidden)
```

#### **Method B: CLI (For CI/CD)**

```bash
# 1. Install Supabase CLI
npm install -g supabase

# 2. Login
supabase login
# (Opens browser to authenticate)

# 3. Add each secret
supabase secrets set STRIPE_SECRET_KEY sk_live_xxx...
supabase secrets set STRIPE_PUBLIC_KEY pk_live_xxx...
supabase secrets set RESEND_API_KEY re_xxx...
supabase secrets set GROQ_API_KEY gsk_xxx...
supabase secrets set TWILIO_ACCOUNT_SID ACxxx...
supabase secrets set TWILIO_AUTH_TOKEN xxx...
supabase secrets set OCR_API_KEY xxx...

# 4. Verify all secrets added
supabase secrets list
```

**Expected Output:**
```
Name                  Type    Created At
STRIPE_SECRET_KEY     api     2024-01-05T...
STRIPE_PUBLIC_KEY     api     2024-01-05T...
RESEND_API_KEY        api     2024-01-05T...
GROQ_API_KEY          api     2024-01-05T...
...
```

---

### **STEP 3: Verify Secrets Work**

#### **In Supabase Dashboard:**
1. Project Settings → Secrets
2. You should see all secrets listed
3. Values are hidden (✅ secure)

#### **Via CLI:**
```bash
supabase secrets list
# Should show all your secrets
```

#### **Test in Edge Function:**
File: `supabase/functions/test-secrets/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // Test accessing secrets
  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY")
  const resendKey = Deno.env.get("RESEND_API_KEY")
  const groqKey = Deno.env.get("GROQ_API_KEY")

  return new Response(JSON.stringify({
    stripe: stripeKey ? "✅ Configured" : "❌ Missing",
    resend: resendKey ? "✅ Configured" : "❌ Missing",
    groq: groqKey ? "✅ Configured" : "❌ Missing",
  }))
})
```

**Deploy and test:**
```bash
# Deploy function
supabase functions deploy test-secrets

# Call the function
curl https://your-project.supabase.co/functions/v1/test-secrets

# You should get:
# {"stripe":"✅ Configured","resend":"✅ Configured","groq":"✅ Configured"}
```

---

## 🔧 USE SECRETS IN YOUR EDGE FUNCTIONS

### **Example 1: Stripe Payment**

File: `supabase/functions/create-payment-intent/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from "https://esm.sh/stripe@13.0.0"

serve(async (req) => {
  try {
    // Get secret from Supabase
    const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY")
    
    if (!stripeSecret) {
      return new Response(
        JSON.stringify({ error: "Stripe key not configured" }),
        { status: 500 }
      )
    }

    // Initialize Stripe
    const stripe = new Stripe(stripeSecret)

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: 2000, // $20.00 in cents
      currency: "usd",
    })

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
```

### **Example 2: Send Email with Resend**

File: `supabase/functions/send-invoice-email/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY")
    
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ error: "Resend key not configured" }),
        { status: 500 }
      )
    }

    const { email, invoiceId, amount } = await req.json()

    // Send email via Resend
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "invoices@yourdomain.com",
        to: email,
        subject: `Invoice #${invoiceId}`,
        html: `
          <h2>Invoice #${invoiceId}</h2>
          <p>Amount: $${amount}</p>
          <p>Thank you for your business!</p>
        `,
      }),
    })

    const data = await response.json()
    return new Response(JSON.stringify(data))
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
```

### **Example 3: AI Chat with Groq**

File: `supabase/functions/ai-chat/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const groqApiKey = Deno.env.get("GROQ_API_KEY")
    
    if (!groqApiKey) {
      return new Response(
        JSON.stringify({ error: "Groq key not configured" }),
        { status: 500 }
      )
    }

    const { message } = await req.json()

    // Call Groq API
    const response = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${groqApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "mixtral-8x7b-32768",
          messages: [{ role: "user", content: message }],
          max_tokens: 1024,
        }),
      }
    )

    const data = await response.json()
    return new Response(JSON.stringify(data))
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
```

---

## 🔐 SECURITY CHECKLIST

After setting up secrets:

- [x] Secrets stored in Supabase (encrypted)
- [ ] API keys NOT in `.env` file
- [ ] API keys NOT in source code
- [ ] API keys NOT committed to Git
- [ ] Edge Functions access secrets via `Deno.env.get()`
- [ ] `.env` file in `.gitignore` (to prevent accidents)
- [ ] Different keys for dev and production
- [ ] Keys tested and working

---

## 🔄 KEY ROTATION (Every 3 months)

When you need to change a key:

```bash
# 1. Generate new key in third-party service
#    (e.g., Stripe, Resend, Groq)

# 2. Update Supabase secret
supabase secrets set STRIPE_SECRET_KEY sk_live_NEW_KEY...

# 3. Test that everything still works
#    (Call Edge Functions, verify no errors)

# 4. Delete old key in third-party service
#    (After 24-48 hours to ensure stability)

# 5. Verify in logs that new key is being used
supabase functions logs create-payment-intent
```

---

## 🚀 DEPLOYMENT WITH SECRETS

### **Deploy Edge Functions with Secrets**

```bash
# 1. Make sure secrets are set
supabase secrets list

# 2. Deploy function
supabase functions deploy create-payment-intent

# 3. Deploy to production
supabase deploy --linked --password YOUR_DATABASE_PASSWORD

# 4. Verify in cloud dashboard
#    https://app.supabase.com → Project → Edge Functions
```

### **Verify Secrets in Production**

```bash
# Check Edge Function logs
supabase functions logs create-payment-intent --follow

# Look for success messages like:
# Payment intent created: pi_1234567890
# Email sent successfully: email_1234567890
```

---

## 📞 TROUBLESHOOTING

### **Problem: "Key not configured" error**

**Solution:**
```bash
# 1. Verify secret was added
supabase secrets list

# 2. If missing, add it
supabase secrets set STRIPE_SECRET_KEY sk_live_xxx...

# 3. Redeploy function
supabase functions deploy function-name

# 4. Test again
```

### **Problem: Function can't access secret**

**Solution:**
```bash
# Make sure Edge Function uses correct name:
const key = Deno.env.get("STRIPE_SECRET_KEY")
// Note: Must match EXACTLY (case-sensitive)

# Common mistakes:
❌ Deno.env.get("stripe_secret_key")  (lowercase)
❌ Deno.env.get("STRIPE_KEY")         (wrong name)
✅ Deno.env.get("STRIPE_SECRET_KEY")  (correct)
```

### **Problem: Different keys needed for dev/prod**

**Solution:**
```bash
# Supabase automatically manages this:

# Development (local)
supabase start
# Uses secrets from local file

# Production (cloud)
supabase deploy --linked
# Uses secrets from Supabase dashboard

# You can have different secrets per environment
# Set them separately for dev and prod
```

---

## ✅ FINAL CHECKLIST

When complete, check:

- [ ] All API keys collected from services
- [ ] All secrets added to Supabase
- [ ] Secrets visible in Dashboard
- [ ] Edge Functions can access secrets
- [ ] Stripe payments work
- [ ] Resend emails send
- [ ] Groq AI responds
- [ ] Twilio/WhatsApp works (if enabled)
- [ ] No hardcoded keys in code
- [ ] No keys in `.env` file (except URLs)
- [ ] `.env` in `.gitignore`
- [ ] Tests pass
- [ ] Ready for production

---

## 🎊 YOU'RE SECURE!

When complete:
- ✅ All API keys encrypted in Supabase
- ✅ Keys only accessible in Edge Functions
- ✅ No keys exposed to frontend
- ✅ Easy to rotate keys
- ✅ Audit trail available
- ✅ Production-ready security

**Your app is now production-secure!** 🔐

---

## 🔗 QUICK LINKS

| Service | Get Key | Add to Supabase |
|---------|---------|-----------------|
| Stripe | https://dashboard.stripe.com/apikeys | STRIPE_SECRET_KEY, STRIPE_PUBLIC_KEY |
| Resend | https://resend.com/api-keys | RESEND_API_KEY |
| Groq | https://console.groq.com/keys | GROQ_API_KEY |
| Twilio | https://www.twilio.com/console/account/keys | TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN |

**Dashboard**: https://app.supabase.com/project/fppmvibvpxrkwmymszhd/settings/secrets
