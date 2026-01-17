# ⚡ API Keys & Secrets - Quick Setup Checklist
**AuraSphere CRM Production Deployment**  
**Date**: January 16, 2026

---

## 🎯 Quick Reference

### Services & Their Keys

| Service | Key Name | Prefix | Status |
|---------|----------|--------|--------|
| **Groq** (AI) | `GROQ_API_KEY` | `gsk_` | ☐ TODO |
| **Resend** (Email) | `RESEND_API_KEY` | `re_` | ☐ TODO |
| **Stripe** (Payment) | `STRIPE_SECRET_KEY` | `sk_test_` / `sk_live_` | ☐ TODO |
| **Stripe** (Frontend) | `STRIPE_PUBLIC_KEY` | `pk_test_` / `pk_live_` | ☐ TODO |
| **Paddle** (Payment) | `PADDLE_API_KEY` | `pdl_` | ☐ TODO |
| **Twilio** (WhatsApp) | `TWILIO_ACCOUNT_SID` | `AC` | ☐ TODO |
| **Twilio** (WhatsApp) | `TWILIO_AUTH_TOKEN` | (long string) | ☐ TODO |
| **OCR** (Receipts) | `OCR_API_KEY` | (varies) | ☐ OPTIONAL |

---

## 📝 Step-by-Step Guide

### 1️⃣ CREATE ACCOUNTS & GET API KEYS

```
1. Go to: https://console.groq.com/
   → Sign up → Create API key
   → Copy gsk_... key
   ✓ Save in password manager

2. Go to: https://resend.com/
   → Sign up → API Keys
   → Copy re_... key
   ✓ Save in password manager

3. Go to: https://dashboard.stripe.com/
   → Sign up → Developers → API Keys
   → Copy pk_test_ and sk_test_ keys
   ✓ Save in password manager
   → Create products (Solo, Team, Workshop)
   → Get price IDs

4. Go to: https://www.paddle.com/
   → Sign up → Developer Tools → API Keys
   → Copy pdl_... key
   ✓ Save in password manager
   → Create products
   → Get price IDs

5. Go to: https://www.twilio.com/
   → Sign up → Account → API Keys & Tokens
   → Copy Account SID (AC...)
   → Copy Auth Token
   ✓ Save in password manager
   → Enable WhatsApp

6. Go to: https://ocr.space/ (optional)
   → Sign up → API Key
   → Copy key
   ✓ Save in password manager
```

---

### 2️⃣ ADD SECRETS TO SUPABASE

**Option A: Using Supabase Dashboard (Easiest)**

1. Go to: https://app.supabase.com/
2. Select project: `lxufgzembtogmsvwhdvq`
3. Settings → Secrets
4. Click "Add secret"
5. Enter each:
   ```
   GROQ_API_KEY = gsk_XXXX...
   RESEND_API_KEY = re_XXXX...
   STRIPE_SECRET_KEY = sk_test_XXXX...
   STRIPE_PUBLIC_KEY = pk_test_XXXX...
   PADDLE_API_KEY = pdl_XXXX...
   TWILIO_ACCOUNT_SID = ACxxxx...
   TWILIO_AUTH_TOKEN = token...
   OCR_API_KEY = key... (optional)
   ```
6. Click "Deploy" button

**Option B: Using CLI**

```bash
supabase secrets set GROQ_API_KEY=gsk_XXXX...
supabase secrets set RESEND_API_KEY=re_XXXX...
supabase secrets set STRIPE_SECRET_KEY=sk_test_XXXX...
supabase secrets set STRIPE_PUBLIC_KEY=pk_test_XXXX...
supabase secrets set PADDLE_API_KEY=pdl_XXXX...
supabase secrets set TWILIO_ACCOUNT_SID=ACxxxx...
supabase secrets set TWILIO_AUTH_TOKEN=token...
supabase secrets set OCR_API_KEY=key...
```

---

### 3️⃣ DEPLOY EDGE FUNCTIONS

```bash
# Make sure you're in project directory
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Deploy all functions
supabase functions deploy

# Verify secrets are accessible
supabase functions invoke verify-secrets
```

**Expected output:**
```
✅ GROQ_API_KEY: CONFIGURED
✅ RESEND_API_KEY: CONFIGURED
✅ STRIPE_SECRET_KEY: CONFIGURED
✅ STRIPE_PUBLIC_KEY: CONFIGURED
✅ PADDLE_API_KEY: CONFIGURED
✅ TWILIO_ACCOUNT_SID: CONFIGURED
✅ TWILIO_AUTH_TOKEN: CONFIGURED
✅ ALL SECRETS CONFIGURED
```

---

### 4️⃣ UPDATE PRICE IDS IN CODE

After creating products in Stripe/Paddle, update the price IDs:

**File: `lib/services/stripe_payment_service.dart`**
```dart
// Around line 15
static const Map<String, String> priceIds = {
  'solo_monthly': 'price_XXXXX_from_stripe',
  'solo_annual': 'price_XXXXX_from_stripe',
  'team_monthly': 'price_XXXXX_from_stripe',
  'team_annual': 'price_XXXXX_from_stripe',
  'workshop_monthly': 'price_XXXXX_from_stripe',
  'workshop_annual': 'price_XXXXX_from_stripe',
};
```

**File: `lib/services/paddle_payment_service.dart`**
```dart
// Around line 15
static const Map<String, String> priceIds = {
  'solo_monthly': 'price_XXXXX_from_paddle',
  'solo_annual': 'price_XXXXX_from_paddle',
  'team_monthly': 'price_XXXXX_from_paddle',
  'team_annual': 'price_XXXXX_from_paddle',
  'workshop_monthly': 'price_XXXXX_from_paddle',
  'workshop_annual': 'price_XXXXX_from_paddle',
};
```

---

### 5️⃣ RUN SQL MIGRATIONS

1. Go to Supabase Dashboard
2. SQL Editor
3. Run these files in order:
   ```
   1. database_schema_setup.sql
   2. 20260105_create_african_prepayment_codes.sql
   3. 20260110_add_digital_signatures.sql
   4. 20260111_add_owner_feature_control.sql
   5. 20260114_add_cloudguard_finops.sql
   ```
   
   Or use: `SUPABASE_DEPLOYMENT_SCRIPT.sql`

---

### 6️⃣ CONFIGURE AUTHENTICATION

1. Supabase Dashboard → Authentication
2. Providers → Enable Email
3. Uncheck "Auto Confirm" (require email verification)
4. Email Templates → Update "Confirm Signup" template
5. SMTP Settings (if custom domain):
   - Provider: Resend
   - API Key: Your RESEND_API_KEY

---

### 7️⃣ BUILD & DEPLOY FLUTTER

```bash
# Clean build
flutter clean

# Build for web
flutter build web --release

# Output: build/web/
# Upload these files to your hosting (Netlify, Vercel, etc.)
```

---

### 8️⃣ TEST EVERYTHING

```bash
# 1. Test signup
- Open app
- Click "Sign Up"
- Enter email & password
- Check email for confirmation link
- Confirm email

# 2. Test payments
- Create account
- Go to billing
- Subscribe to Team plan
- Complete Stripe/Paddle payment
- Check subscription created

# 3. Test AI
- Go to dashboard
- Type AI command
- See AI response

# 4. Test email
- Trigger invoice reminder
- Check email received

# 5. Test WhatsApp (if enabled)
- Trigger status update
- Check WhatsApp message
```

---

## ✅ Final Checklist

### Create Accounts
- [ ] Groq (https://console.groq.com)
- [ ] Resend (https://resend.com)
- [ ] Stripe (https://dashboard.stripe.com)
- [ ] Paddle (https://www.paddle.com)
- [ ] Twilio (https://www.twilio.com)
- [ ] OCR.space (optional)

### Get API Keys
- [ ] Groq API Key
- [ ] Resend API Key
- [ ] Stripe Secret & Public Keys
- [ ] Paddle API Key
- [ ] Twilio Account SID & Auth Token
- [ ] OCR.space API Key (optional)

### Add to Supabase
- [ ] Login to Supabase Dashboard
- [ ] Settings → Secrets
- [ ] Add all 7-8 keys
- [ ] Click Deploy

### Deploy Functions
- [ ] Run: `supabase functions deploy`
- [ ] Run: `supabase functions invoke verify-secrets`
- [ ] Verify all secrets show ✅ CONFIGURED

### Update Code
- [ ] Update stripe_payment_service.dart with Stripe price IDs
- [ ] Update paddle_payment_service.dart with Paddle price IDs
- [ ] Verify no compilation errors

### Database
- [ ] Run all 5 SQL migrations in order
- [ ] Verify all tables created
- [ ] Verify RLS policies active

### Authentication
- [ ] Enable Email provider in Supabase
- [ ] Disable "Auto Confirm"
- [ ] Configure email templates
- [ ] Test signup flow

### Build & Deploy
- [ ] Flutter clean
- [ ] Flutter build web --release
- [ ] Deploy build/web/ to hosting
- [ ] Test live app

### Test Everything
- [ ] Test signup (email confirmation)
- [ ] Test password reset
- [ ] Test subscription (Stripe/Paddle)
- [ ] Test AI agent commands
- [ ] Test invoice reminders (email)
- [ ] Test WhatsApp (if enabled)
- [ ] Check logs for errors

---

## 🆘 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| "Secret not found" | Check Supabase Secrets page, redeploy functions |
| "401 Unauthorized" | Verify API key is correct in Supabase Secrets |
| "Function not found" | Run `supabase functions deploy` |
| "CORS error" | Should not happen - check browser console for real error |
| Email not sending | Check Resend API key and domain verification |
| Payment errors | Check Stripe/Paddle API keys in Secrets |
| WhatsApp not working | Check Twilio credentials and business account status |

---

## 📞 Support

**Detailed Guide**: See `API_KEYS_SETUP_GUIDE.md`  
**Deployment Script**: Run `setup-production.sh`  
**Troubleshooting**: See `PRE_LAUNCH_FIXES_COMPLETE.md`

---

## 🎉 You're Ready!

When all checkboxes are complete, your app is ready for production launch.

**Estimated Time**: 30-45 minutes total

**Date Completed**: ___________

---

*Last Updated: January 16, 2026*
