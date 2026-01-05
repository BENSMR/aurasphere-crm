# 🔌 SUPABASE INTEGRATION CHECKLIST

**Your Project**: `fppmvibvpxrkwmymszhd`  
**Status**: Setting up production secrets  
**Time**: 15 minutes

---

## ✅ CHECKLIST: API KEYS & SECRETS

### **Phase 1: Collect Keys** (5 minutes)

| Service | Status | Key Name | Notes |
|---------|--------|----------|-------|
| **Stripe** | ⏳ | `STRIPE_PUBLIC_KEY` | Get from stripe.com/apikeys (pk_live_...) |
| **Stripe** | ⏳ | `STRIPE_SECRET_KEY` | Get from stripe.com/apikeys (sk_live_...) |
| **Resend** | ⏳ | `RESEND_API_KEY` | Get from resend.com (re_...) |
| **Groq** | ⏳ | `GROQ_API_KEY` | Get from groq.com (gsk_...) |
| **Twilio** | ⏳ Optional | `TWILIO_ACCOUNT_SID` | Get from twilio.com (AC...) |
| **Twilio** | ⏳ Optional | `TWILIO_AUTH_TOKEN` | Get from twilio.com |
| **OCR** | ⏳ Optional | `OCR_API_KEY` | Get from ocr.space |

---

### **Phase 2: Add to Supabase** (5 minutes)

**Go to**: https://app.supabase.com/project/fppmvibvpxrkwmymszhd/settings/secrets

For each key:
```
1. Click: "+ Add secret"
2. Name: (e.g., STRIPE_PUBLIC_KEY)
3. Value: (paste the actual key)
4. Click: Save
5. Result: ✅ Secret added successfully
```

| Secret | Added | Verified |
|--------|-------|----------|
| STRIPE_PUBLIC_KEY | ☐ | ☐ |
| STRIPE_SECRET_KEY | ☐ | ☐ |
| RESEND_API_KEY | ☐ | ☐ |
| GROQ_API_KEY | ☐ | ☐ |
| TWILIO_ACCOUNT_SID | ☐ | ☐ |
| TWILIO_AUTH_TOKEN | ☐ | ☐ |
| OCR_API_KEY | ☐ | ☐ |

---

### **Phase 3: Verify in Supabase** (5 minutes)

**Check Dashboard:**
```
✓ All secrets visible in:
  Settings → Secrets tab
  
✓ Secrets are hidden/encrypted
  (values show as ••••••)
  
✓ Each shows:
  - Name
  - Type (api)
  - Created date
  - Delete option
```

**Checklist:**
- [ ] Can see STRIPE_PUBLIC_KEY in dashboard
- [ ] Can see STRIPE_SECRET_KEY in dashboard
- [ ] Can see RESEND_API_KEY in dashboard
- [ ] Can see GROQ_API_KEY in dashboard
- [ ] All values are hidden (shows as bullets)
- [ ] Can delete each secret if needed

---

## 🔧 INTEGRATION SETUP

### **Stripe Integration**

**File**: `supabase/functions/stripe-webhook/index.ts`

```typescript
// ✅ Uses STRIPE_SECRET_KEY from secrets
const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY")
const stripe = new Stripe(stripeSecret)
```

**Checklist:**
- [ ] Stripe keys added to Supabase Secrets
- [ ] Webhook endpoint configured in Stripe dashboard
- [ ] Edge Function uses `Deno.env.get("STRIPE_SECRET_KEY")`
- [ ] Tested with test transaction

---

### **Resend Email Integration**

**File**: `supabase/functions/send-invoice-email/index.ts`

```typescript
// ✅ Uses RESEND_API_KEY from secrets
const resendApiKey = Deno.env.get("RESEND_API_KEY")
// Call: fetch("https://api.resend.com/emails", { Authorization: Bearer ${resendApiKey} })
```

**Checklist:**
- [ ] Resend API key added to Supabase Secrets
- [ ] Domain verified in Resend dashboard
- [ ] Edge Function uses `Deno.env.get("RESEND_API_KEY")`
- [ ] Tested with test email

---

### **Groq AI Integration**

**File**: `supabase/functions/ai-chat/index.ts`

```typescript
// ✅ Uses GROQ_API_KEY from secrets
const groqApiKey = Deno.env.get("GROQ_API_KEY")
// Call: fetch("https://api.groq.com/openai/v1/chat/completions", { Authorization: Bearer ${groqApiKey} })
```

**Checklist:**
- [ ] Groq API key added to Supabase Secrets
- [ ] Edge Function uses `Deno.env.get("GROQ_API_KEY")`
- [ ] Tested with sample prompt
- [ ] Response time acceptable (< 2 seconds)

---

### **Twilio WhatsApp Integration** (Optional)

**File**: `supabase/functions/send-whatsapp/index.ts`

```typescript
// ✅ Uses TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN from secrets
const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID")
const authToken = Deno.env.get("TWILIO_AUTH_TOKEN")
// Create Twilio client and send message
```

**Checklist:**
- [ ] Twilio Account SID added to Supabase Secrets
- [ ] Twilio Auth Token added to Supabase Secrets
- [ ] WhatsApp sandbox setup in Twilio
- [ ] Edge Function uses secrets
- [ ] Tested with test message

---

## 🚀 DEPLOYMENT STEPS

### **1. Deploy Edge Functions**

```bash
# List functions
supabase functions list

# Deploy specific function
supabase functions deploy stripe-webhook
supabase functions deploy send-invoice-email
supabase functions deploy ai-chat
supabase functions deploy send-whatsapp
supabase functions deploy verify-secrets

# Or deploy all
supabase deploy --linked
```

### **2. Verify Functions Have Access to Secrets**

```bash
# Call verify-secrets function
curl https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/verify-secrets

# Expected response:
{
  "summary": {
    "status": "✅ ALL SECRETS CONFIGURED",
    "configured": 4
  }
}
```

### **3. Test Each Integration**

**Test Stripe:**
```bash
curl -X POST https://your-domain/api/create-payment \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000}'
# Should return: {"clientSecret": "pi_..."}
```

**Test Resend:**
```bash
curl -X POST https://your-domain/api/send-email \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "subject": "Test"}'
# Should return: {"id": "email_..."}
```

**Test Groq:**
```bash
curl -X POST https://your-domain/api/ai-chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, what is 2+2?"}'
# Should return: {"message": "2+2 equals 4"}
```

---

## ✅ FINAL VERIFICATION

### **Security Check**
- [ ] No API keys in source code
- [ ] No API keys in `.env` file (only URLs)
- [ ] All secrets in Supabase Secrets
- [ ] `.env` in `.gitignore`
- [ ] No secrets committed to Git

### **Functionality Check**
- [ ] Stripe payments work
- [ ] Resend emails send
- [ ] Groq AI responds
- [ ] Twilio messages send (if enabled)
- [ ] No "key not found" errors in logs

### **Production Check**
- [ ] Using live keys (not test keys)
- [ ] Edge Functions deployed
- [ ] Webhook endpoints configured
- [ ] Monitoring/logging active
- [ ] Ready for users

---

## 📊 STATUS TRACKING

| Component | Status | Notes |
|-----------|--------|-------|
| **Supabase Project** | ✅ Ready | fppmvibvpxrkwmymszhd |
| **Secrets Storage** | ⏳ In Progress | Adding keys now |
| **Stripe Integration** | ⏳ Ready | Just need keys |
| **Resend Integration** | ⏳ Ready | Just need keys |
| **Groq Integration** | ⏳ Ready | Just need keys |
| **Twilio Integration** | ⏳ Optional | For WhatsApp |
| **Edge Functions** | ✅ Built | Ready to deploy |
| **Production Deploy** | ⏳ Pending | After secrets setup |

---

## 🎯 NEXT STEPS

1. ✅ **Collect API Keys** (5 min)
   - Stripe: pk_live_ and sk_live_
   - Resend: re_
   - Groq: gsk_
   - Twilio (optional): Account SID + Token

2. ✅ **Add to Supabase Secrets** (5 min)
   - Go to: https://app.supabase.com/.../secrets
   - Click: "+ Add secret"
   - Add each key

3. ✅ **Verify in Dashboard** (5 min)
   - Check all secrets listed
   - Check all values hidden
   - Run verify-secrets function

4. ⏳ **Deploy Edge Functions** (5 min)
   - `supabase deploy --linked`
   - Verify no errors

5. ⏳ **Test All Integrations** (10 min)
   - Payment → Create payment intent
   - Email → Send test invoice
   - AI → Test chat
   - WhatsApp → Send test message

6. ⏳ **Deploy to Production** (15 min)
   - Firebase/Vercel/Netlify
   - Monitor for errors
   - Go live! 🎉

---

## 📞 HELP

**Quick Setup**: [QUICK_SETUP_SUPABASE_SECRETS.md](QUICK_SETUP_SUPABASE_SECRETS.md)

**Full Guide**: [SUPABASE_API_KEYS_SECRETS.md](SUPABASE_API_KEYS_SECRETS.md)

**Dashboard**: https://app.supabase.com/project/fppmvibvpxrkwmymszhd/settings/secrets

---

**Start now!** → [QUICK_SETUP_SUPABASE_SECRETS.md](QUICK_SETUP_SUPABASE_SECRETS.md)

Your API keys will be secure in Supabase. 🔐
