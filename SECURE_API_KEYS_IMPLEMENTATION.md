# 🔐 Secure API Keys Implementation - Quick Start

Your API keys are now secured in **Supabase Edge Function Secrets**. Here's how to activate them:

---

## ⚡ Quick Setup (3 Steps)

### Step 1️⃣: Add Secrets to Supabase (2 minutes)

**Option A: Via Supabase Dashboard (Easiest)**
1. Go to: https://app.supabase.com/projects
2. Select your project: `AuraSphere CRM`
3. Navigate: **Settings** → **Secrets**
4. Click **New Secret** for each:

   | Key | Value |
   |-----|-------|
   | `GROQ_API_KEY` | `gsk_...` (your Groq key) |
   | `RESEND_API_KEY` | `re_...` (your Resend key) |

5. Click **Save** after each

**Option B: Via Supabase CLI (Faster)**
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Login (first time only)
supabase login

# Add secrets
supabase secrets set GROQ_API_KEY=gsk_YOUR_KEY_HERE
supabase secrets set RESEND_API_KEY=re_YOUR_KEY_HERE

# Verify
supabase secrets list
```

Expected output:
```
┌──────────────────┬─────────────────────────────┐
│ Name             │ Value                       │
├──────────────────┼─────────────────────────────┤
│ GROQ_API_KEY     │ ***...***                   │
│ RESEND_API_KEY   │ ***...***                   │
└──────────────────┴─────────────────────────────┘
```

### Step 2️⃣: Deploy Edge Functions (2 minutes)

```bash
# From project root
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Deploy email function (uses RESEND_API_KEY)
supabase functions deploy send-email

# Deploy receipt scanning (optional, if OCR enabled)
supabase functions deploy scan-receipt

# View deployment status
supabase functions list
```

### Step 3️⃣: Test in Flutter App (1 minute)

The app automatically calls Edge Functions through `backend_api_proxy.dart`.

**Test Email:**
```bash
# Open Flutter app and navigate to: Payment Reminders
# Click "Send Test Email"
# Check inbox for: "Payment Reminder from AuraSphere CRM"
```

**Test Groq LLM:**
```bash
# Open Aura Chat page
# Type: "Create invoice for Ahmed 500 AED"
# Should create invoice via Groq API
```

---

## 🔍 Verification Checklist

- [ ] **Secrets added**: `supabase secrets list` shows GROQ_API_KEY and RESEND_API_KEY
- [ ] **Functions deployed**: `supabase functions list` shows `send-email` and `scan-receipt`
- [ ] **No errors in logs**: `supabase functions logs send-email` shows successful execution
- [ ] **Email received**: Test email arrives in inbox
- [ ] **Invoice created**: Groq chat creates invoice successfully
- [ ] **No API keys in frontend**: Checked `env_loader.dart` (no hardcoded keys)

---

## 🛠️ File Reference

| File | What It Does | Status |
|------|-------------|--------|
| `lib/services/backend_api_proxy.dart` | Calls Edge Functions securely | ✅ Ready |
| `lib/core/env_loader.dart` | Only public Supabase URL/Key (no secrets) | ✅ Secure |
| `supabase/functions/send-email/index.ts` | Uses `Deno.env.get('RESEND_API_KEY')` | ✅ Ready |
| `supabase/functions/scan-receipt/index.ts` | Uses `Deno.env.get('GROQ_API_KEY')` | ✅ Ready |

---

## 📊 Architecture

```
[Flutter App]
    ↓
[backend_api_proxy.dart]
    ↓
[Supabase Edge Function] ← Gets key from Secrets vault
    ↓
[External API] (Groq, Resend, etc.)
```

**Security:** API keys never leave Supabase. Frontend calls are proxied through serverless functions.

---

## 🐛 Troubleshooting

### Issue: "Secret not found" error
```
❌ Error: RESEND_API_KEY not configured
```
**Fix:**
1. Verify secret exists: `supabase secrets list`
2. Check spelling (case-sensitive): `RESEND_API_KEY` not `resend_api_key`
3. Re-deploy function: `supabase functions deploy send-email`

### Issue: "401 Unauthorized" from Resend
```
❌ Error: Invalid API key for Resend
```
**Fix:**
1. Verify key format: Should start with `re_` followed by alphanumeric
2. Test key in Resend dashboard: https://resend.com/api-keys
3. Key may have expired - generate new one and update secret:
   ```bash
   supabase secrets set RESEND_API_KEY=re_NEW_KEY_HERE
   ```

### Issue: Email not sending
```
❌ Error: Recipient email not valid
```
**Fix:**
1. Check recipient email is valid
2. View function logs: `supabase functions logs send-email`
3. Test locally:
   ```bash
   supabase functions invoke send-email --body '{
     "to": "test@example.com",
     "subject": "Test",
     "body": "Test message"
   }'
   ```

---

## 📈 Next Steps

### 1. Production Deployment
```bash
# Deploy to production with same secrets
supabase functions deploy send-email --project-id fppmvibvpxrkwmymszhd

# Or use Vercel/Firebase
vercel deploy build/web --prod
```

### 2. Monitor Usage
- Check Groq API usage: https://console.groq.com (track free tier limit)
- Check Resend emails: https://resend.com/emails
- View function logs: `supabase functions logs send-email --tail`

### 3. Key Rotation (Optional but recommended)
Every 30-90 days, rotate API keys:
```bash
# 1. Generate new key in Resend/Groq dashboard
# 2. Update secret
supabase secrets set RESEND_API_KEY=re_NEW_KEY_HERE
# 3. Delete old key in external service
# 4. Deploy: supabase functions deploy send-email
```

---

## ✨ Success Indicators

✅ User receives email from: `Aurasphere CRM <invoices@aura-sphere.app>`
✅ Groq chat responds with parsed actions (create invoice, etc.)
✅ No console errors about missing API keys
✅ `supabase functions logs` show successful execution
✅ Edge function latency < 1 second
✅ Free tier limits respected (Groq: 14,400 req/min, Resend: 100 emails/day)

---

## 📚 Resources

- **Supabase Secrets Docs**: https://supabase.com/docs/guides/functions/secrets
- **Resend API Keys**: https://resend.com/api-keys
- **Groq API Console**: https://console.groq.com
- **Edge Function Logs**: `supabase functions logs <function-name> --tail`

---

**Status**: 🟢 **Ready to Deploy**

All infrastructure is in place. Just add your keys and deploy!
