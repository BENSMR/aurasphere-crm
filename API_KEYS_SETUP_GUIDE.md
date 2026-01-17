# 🔑 API Keys & Secrets Configuration Guide
**AuraSphere CRM - Production Setup**  
**Date**: January 16, 2026  
**Status**: Ready for Configuration

---

## 📋 Overview

This guide walks through obtaining and configuring all API keys for production Edge Functions. All external APIs are accessed **only through Supabase Edge Functions** - no keys are exposed to the frontend.

### Required Integrations

| Service | Purpose | Urgency | Status |
|---------|---------|---------|--------|
| **Groq** | AI Agent (LLM) | 🔴 CRITICAL | ⏳ TO-DO |
| **Resend** | Email delivery | 🔴 CRITICAL | ⏳ TO-DO |
| **Stripe** | Payment processing | 🔴 CRITICAL | ⏳ TO-DO |
| **Paddle** | Payment alternative | 🟡 HIGH | ⏳ TO-DO |
| **Twilio** | WhatsApp messaging | 🟡 HIGH | ⏳ TO-DO |
| **OCR Space** | Receipt scanning | 🟢 LOW | ⏳ OPTIONAL |

---

## 1️⃣ Groq API Key (AI Agent)

### What It's For
Powers the autonomous AI agents (CEO, COO, CFO) via the Groq LLM. Used in:
- `aura_ai_service.dart` - Command parsing
- Edge Function: `groq-proxy`

### How to Get It

1. **Go to Groq Console**: https://console.groq.com/
2. **Sign up/Login** with email
3. **Navigate to API Keys** (Left sidebar)
4. **Create new API key**:
   - Name: `AuraSphere Production`
   - Copy the key (starts with `gsk_`)
5. **Keep it safe** - you'll need it in next step

### Verification
```bash
# Test your key
curl -X POST "https://api.groq.com/openai/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_GROQ_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mixtral-8x7b-32768",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Store In Supabase
```
Secret Name: GROQ_API_KEY
Secret Value: gsk_XXXXXXXXXXXXXXXXXXXX
```

---

## 2️⃣ Resend API Key (Email)

### What It's For
Sends transactional emails (signup confirmation, invoice reminders, password resets). Used in:
- `email_service.dart`
- Edge Function: `send-email`

### How to Get It

1. **Go to Resend**: https://resend.com/
2. **Sign up/Login** with email
3. **Navigate to API Keys**: https://resend.com/api-keys
4. **Create API Key**:
   - Name: `AuraSphere Production`
   - Copy the key (starts with `re_`)
5. **Verify domain** (optional but recommended):
   - Dashboard → Domains → Add domain
   - Follow DNS verification steps
   - Use verified domain in emails

### Email Configuration
```
From Email: noreply@yourdomain.com
Reply-To: support@yourdomain.com
```

### Verification
```bash
# Test your key
curl -X POST "https://api.resend.com/emails" \
  -H "Authorization: Bearer YOUR_RESEND_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "noreply@yourdomain.com",
    "to": "test@example.com",
    "subject": "Test",
    "html": "<p>Test email</p>"
  }'
```

### Store In Supabase
```
Secret Name: RESEND_API_KEY
Secret Value: re_XXXXXXXXXXXXXXXXXXXX
```

---

## 3️⃣ Stripe Keys (Payment)

### What It's For
Payment processing for subscriptions (solo, team, workshop plans). Used in:
- `stripe_payment_service.dart`
- Edge Function: `stripe-proxy`

### How to Get It

1. **Go to Stripe Dashboard**: https://dashboard.stripe.com/
2. **Sign up/Login** with email
3. **Enable Test Mode** (top right):
   - Toggle to "Test Mode"
4. **Get API Keys** (Developers → API Keys):
   - **Publishable Key** (starts with `pk_test_`)
   - **Secret Key** (starts with `sk_test_`)
5. **For Production**:
   - Toggle to "Live Mode"
   - Get live keys (`pk_live_`, `sk_live_`)
   - Need business verification first

### Configure Products & Prices
```
Products:
├─ Solo Plan
│  ├─ Monthly: $29/month
│  ├─ Annual: $290/year (2 months free)
│  └─ Trial: 14 days
├─ Team Plan
│  ├─ Monthly: $99/month
│  ├─ Annual: $990/year
│  └─ Trial: 14 days
└─ Workshop Plan
   ├─ Monthly: $299/month
   ├─ Annual: $2990/year
   └─ Trial: 14 days
```

In Stripe Dashboard:
1. Products → Create product
2. Add pricing (monthly + annual)
3. Copy price IDs into `stripe_payment_service.dart` priceIds map

### Verification
```bash
# Test your key
curl -X GET "https://api.stripe.com/v1/customers" \
  -H "Authorization: Bearer YOUR_STRIPE_SECRET_KEY"
```

### Store In Supabase
```
Secret Name: STRIPE_SECRET_KEY
Secret Value: sk_test_XXXXXXXXXXXXXXXXXXXX (or sk_live_ for production)

Secret Name: STRIPE_PUBLIC_KEY
Secret Value: pk_test_XXXXXXXXXXXXXXXXXXXX (or pk_live_ for production)
```

---

## 4️⃣ Paddle API Key (Payment Alternative)

### What It's For
Alternative payment processor to Stripe. Used in:
- `paddle_payment_service.dart`
- Edge Function: `paddle-proxy`

### How to Get It

1. **Go to Paddle**: https://www.paddle.com/
2. **Sign up/Login** as vendor
3. **Business Setup** → Complete verification
4. **API Keys** (Settings → Developer Tools):
   - **API Key** (starts with `pdl_`)
   - Note the Vendor ID (numerical)
5. **Create Products & Prices** in Paddle Dashboard

### Configure Products
```
Products:
├─ Solo Plan
├─ Team Plan
└─ Workshop Plan
```

Copy price IDs from Paddle into `paddle_payment_service.dart`

### Verification
```bash
# Test your key
curl -X GET "https://api.paddle.com/customers" \
  -H "Authorization: Bearer YOUR_PADDLE_KEY"
```

### Store In Supabase
```
Secret Name: PADDLE_API_KEY
Secret Value: pdl_XXXXXXXXXXXXXXXXXXXX
```

---

## 5️⃣ Twilio Credentials (WhatsApp)

### What It's For
WhatsApp message delivery (status updates, payment confirmations). Used in:
- `whatsapp_service.dart`
- Edge Function: `send-whatsapp`

### How to Get It

1. **Go to Twilio**: https://www.twilio.com/
2. **Sign up/Login** with email
3. **Create Account Type**: "Messaging"
4. **Get Credentials** (Account → API Keys & Tokens):
   - **Account SID** (starts with `AC`)
   - **Auth Token** (long random string)
5. **Enable WhatsApp**:
   - Messaging → Try it out → WhatsApp
   - Approve business account
   - Get WhatsApp Sandbox number or Business number
6. **Approve Senders**:
   - Add phone numbers that can send WhatsApp

### Testing
```bash
# Test your credentials
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/YOUR_SID/Messages.json" \
  -u "YOUR_SID:YOUR_AUTH_TOKEN" \
  -d "From=whatsapp:+14155552671" \
  -d "To=whatsapp:+YOUR_NUMBER" \
  -d "Body=Test"
```

### Store In Supabase
```
Secret Name: TWILIO_ACCOUNT_SID
Secret Value: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Secret Name: TWILIO_AUTH_TOKEN
Secret Value: your_auth_token_here
```

---

## 6️⃣ OCR Space API Key (Receipt Scanning)

### What It's For
Receipt/invoice image scanning for expense tracking. Used in:
- `ocr_service.dart`
- Edge Function: `ocr-proxy`

### How to Get It

1. **Go to OCR.space**: https://ocr.space/
2. **Sign up/Login** (free tier available)
3. **Get API Key** (Account → API Key):
   - Free tier: Limited requests
   - Pro tier: Unlimited requests
4. **Copy your API key**

### Verification
```bash
# Test your key
curl -X POST "https://api.ocr.space/parse/image" \
  -F "url=https://example.com/image.jpg" \
  -F "apikey=YOUR_API_KEY"
```

### Store In Supabase (Optional)
```
Secret Name: OCR_API_KEY
Secret Value: your_ocr_key_here
```

---

## 🚀 Setting Up Secrets in Supabase

### Method 1: Supabase Dashboard (Recommended)

1. **Go to Supabase Dashboard**: https://app.supabase.com/
2. **Select your project**: `lxufgzembtogmsvwhdvq`
3. **Navigate to**: Settings → Secrets
4. **Add each secret**:
   ```
   GROQ_API_KEY = gsk_XXXX...
   RESEND_API_KEY = re_XXXX...
   STRIPE_SECRET_KEY = sk_test_XXXX... or sk_live_XXXX...
   STRIPE_PUBLIC_KEY = pk_test_XXXX... or pk_live_XXXX...
   PADDLE_API_KEY = pdl_XXXX...
   TWILIO_ACCOUNT_SID = ACxxxx...
   TWILIO_AUTH_TOKEN = your_token...
   OCR_API_KEY = your_key... (optional)
   ```
5. **Click "Add secret"** for each one
6. **Deploy Edge Functions**:
   ```bash
   supabase functions deploy
   ```

### Method 2: Supabase CLI

```bash
# Install Supabase CLI (if not already installed)
npm install -g supabase

# Login to Supabase
supabase login

# Set secrets
supabase secrets set GROQ_API_KEY=gsk_XXXX...
supabase secrets set RESEND_API_KEY=re_XXXX...
supabase secrets set STRIPE_SECRET_KEY=sk_test_XXXX...
supabase secrets set STRIPE_PUBLIC_KEY=pk_test_XXXX...
supabase secrets set PADDLE_API_KEY=pdl_XXXX...
supabase secrets set TWILIO_ACCOUNT_SID=ACxxxx...
supabase secrets set TWILIO_AUTH_TOKEN=your_token...

# Deploy functions
supabase functions deploy

# Verify secrets
supabase functions invoke verify-secrets
```

---

## ✅ Verification Checklist

### Step 1: Create an Account for Each Service

- [ ] **Groq** - https://console.groq.com/ → Create account
- [ ] **Resend** - https://resend.com/ → Create account
- [ ] **Stripe** - https://dashboard.stripe.com/ → Create account
- [ ] **Paddle** - https://www.paddle.com/ → Create account
- [ ] **Twilio** - https://www.twilio.com/ → Create account
- [ ] **OCR.space** - https://ocr.space/ → Create account (optional)

### Step 2: Generate API Keys

- [ ] **Groq API Key** → Copy `gsk_XXXX...`
- [ ] **Resend API Key** → Copy `re_XXXX...`
- [ ] **Stripe Keys** → Copy `pk_test_XXXX...` and `sk_test_XXXX...`
- [ ] **Paddle API Key** → Copy `pdl_XXXX...`
- [ ] **Twilio SID & Token** → Copy credentials
- [ ] **OCR.space Key** → Copy key (optional)

### Step 3: Test Each Integration

```bash
# After deploying Edge Functions, test each one:

# Test Groq
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/groq-proxy \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "language": "en"}'

# Test Email
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/send-email \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"to": "test@example.com", "subject": "Test", "body": "<p>Test</p>"}'

# Test Stripe
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/stripe-proxy \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "getCustomer", "customerId": "test"}'

# Test WhatsApp
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/send-whatsapp \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"phone": "+1234567890", "message": "Test"}'
```

### Step 4: Verify All Secrets Are Accessible

```bash
# Run the verification function
supabase functions invoke verify-secrets --local
```

Expected output:
```json
{
  "summary": {
    "total": 8,
    "configured": 8,
    "missing": 0,
    "invalid": 0,
    "status": "✅ ALL SECRETS CONFIGURED"
  }
}
```

---

## 🔒 Security Best Practices

### DO ✅
- [ ] Store keys **only in Supabase Secrets**
- [ ] Use **separate keys for dev/prod**
- [ ] Rotate keys **every 90 days**
- [ ] Use **Environment variables** in Edge Functions
- [ ] Never commit keys to **git** (use `.env.local`)
- [ ] Monitor key **usage and billing**
- [ ] Set IP **whitelist** if available
- [ ] Use **least privilege** (API keys with minimal permissions)

### DON'T ❌
- [ ] Never hardcode keys in Dart/Flutter code
- [ ] Never expose keys in browser console
- [ ] Never share keys in emails/Slack/chat
- [ ] Never commit `.env` files with real keys
- [ ] Never use same key for dev and production
- [ ] Never log full API keys

---

## 📞 Troubleshooting

### Common Issues

**"Secret not found" error**
- Solution: Go to Supabase Dashboard → Settings → Secrets and verify secret name matches exactly (case-sensitive)
- Redeploy Edge Functions after adding secrets

**"401 Unauthorized" from Groq/Stripe/Paddle**
- Solution: Verify API key is correct in Supabase Secrets
- Check that secret name matches Edge Function code

**"CORS error" when calling Edge Function**
- Solution: This shouldn't happen - Edge Functions have CORS enabled
- Check browser console for actual error message

**"Function not found"**
- Solution: Run `supabase functions deploy` to deploy all Edge Functions
- Verify function names in supabase/functions/ directory

---

## 🎯 Next Steps (In Order)

### Phase 1: Prepare (Today)
1. [ ] Create accounts for all 6 services
2. [ ] Generate all API keys
3. [ ] Document keys securely (password manager, not email/chat)

### Phase 2: Configure (Today)
4. [ ] Add secrets to Supabase Dashboard
5. [ ] Deploy Edge Functions: `supabase functions deploy`
6. [ ] Run verify-secrets function

### Phase 3: Test (Today)
7. [ ] Test each Edge Function with curl
8. [ ] Test signup flow (email verification)
9. [ ] Test payment integration (Stripe/Paddle)
10. [ ] Test WhatsApp messaging

### Phase 4: Deploy (Today)
11. [ ] Build Flutter web: `flutter build web --release`
12. [ ] Deploy to production
13. [ ] Monitor logs for errors
14. [ ] Alert team of successful launch

---

## 📚 Reference Links

| Service | Link | Docs |
|---------|------|------|
| Groq | https://console.groq.com | https://console.groq.com/docs |
| Resend | https://resend.com | https://resend.com/docs |
| Stripe | https://dashboard.stripe.com | https://stripe.com/docs/api |
| Paddle | https://vendor.paddle.com | https://developer.paddle.com |
| Twilio | https://www.twilio.com/console | https://www.twilio.com/docs |
| OCR.space | https://ocr.space | https://ocr.space/ocrapi |
| Supabase | https://app.supabase.com | https://supabase.com/docs |

---

## ✨ Final Checklist

```
API KEYS CONFIGURATION CHECKLIST
═════════════════════════════════════════════════

GROQ (AI Agent)
  ☐ Account created
  ☐ API key generated
  ☐ Key stored in Supabase
  ☐ Functions deployed

RESEND (Email)
  ☐ Account created
  ☐ API key generated
  ☐ Domain verified (optional)
  ☐ Key stored in Supabase
  ☐ Functions deployed

STRIPE (Payment)
  ☐ Account created
  ☐ API keys generated (test)
  ☐ Products created
  ☐ Price IDs copied to code
  ☐ Keys stored in Supabase
  ☐ Functions deployed

PADDLE (Payment Alt)
  ☐ Account created
  ☐ API key generated
  ☐ Products created
  ☐ Price IDs copied to code
  ☐ Key stored in Supabase
  ☐ Functions deployed

TWILIO (WhatsApp)
  ☐ Account created
  ☐ Credentials generated
  ☐ WhatsApp enabled
  ☐ Business approved
  ☐ Credentials stored in Supabase
  ☐ Functions deployed

OCR.SPACE (Receipts)
  ☐ Account created (optional)
  ☐ API key generated
  ☐ Key stored in Supabase
  ☐ Functions deployed

VERIFICATION
  ☐ All 8 secrets in Supabase
  ☐ verify-secrets function runs successfully
  ☐ All external API integrations tested
  ☐ Email sending works
  ☐ Payment processing works
  ☐ WhatsApp messaging works

DEPLOYMENT
  ☐ Flutter web built
  ☐ Assets deployed
  ☐ Edge Functions deployed
  ☐ Signup tested end-to-end
  ☐ Payments tested end-to-end
  ☐ Live monitoring active

═════════════════════════════════════════════════
Ready to Launch: ☐ YES (when all items checked)
```

---

**Prepared By**: AI Code Agent  
**Date**: January 16, 2026  
**Version**: Configuration Guide v1.0  
**Status**: Ready for Setup

🔑 **All API keys documented. Ready to configure production!**
