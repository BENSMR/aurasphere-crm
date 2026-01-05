# ⚡ QUICK REFERENCE - Secure API Keys Setup

## 3-Step Implementation

### 1️⃣ Add Secrets to Supabase (2 min)

```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm
supabase login
supabase secrets set GROQ_API_KEY=gsk_YOUR_KEY
supabase secrets set RESEND_API_KEY=re_YOUR_KEY
supabase secrets list  # Verify
```

### 2️⃣ Deploy Edge Functions (1 min)

```bash
supabase functions deploy send-email
supabase functions deploy supplier-ai-agent
supabase functions list  # Verify
```

### 3️⃣ Test in Flutter App (2 min)

- Open app → Invoices → Send Test Email → Check inbox
- Open app → Aura Chat → "Create invoice" → Should work

---

## What Changed

| Service | Before | After | Key |
|---------|--------|-------|-----|
| Email | `http.post` + exposed key | `Edge Function` | RESEND_API_KEY |
| Groq | `http.post` + exposed key | `Edge Function` | GROQ_API_KEY |

---

## Files Modified

- ✅ `lib/services/email_service.dart` - Now uses Edge Function
- ✅ `lib/services/aura_ai_service.dart` - Now uses Edge Function
- ✅ `lib/core/env_loader.dart` - No secrets (only public values)

---

## Verification

```bash
# Check secrets exist
supabase secrets list

# Check functions deployed
supabase functions list

# View logs
supabase functions logs send-email --tail
```

---

## Keys Location

**Get from:**
- Groq: https://console.groq.com/keys (copy `gsk_...`)
- Resend: https://resend.com/api-keys (copy `re_...`)

**Store in:**
- Supabase Dashboard: Settings → Secrets
- Or CLI: `supabase secrets set NAME=VALUE`

---

## Security Flow

```
Frontend (no keys)
    ↓
Edge Function (gets key from Secrets)
    ↓
External API (Groq/Resend)
```

**Result:** Keys encrypted, never exposed! ✅

---

## Total Time: ~10 minutes

1. Add secrets: 2 min
2. Deploy: 1 min  
3. Test: 2 min
4. Verify: 1 min
5. Buffer: 2 min

---

**Questions?** See full docs in `SECURE_API_IMPLEMENTATION_COMPLETE.md`
