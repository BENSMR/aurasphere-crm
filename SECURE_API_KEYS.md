# 🔐 SECURE API KEYS - SECURITY BEST PRACTICES

**Date**: January 1, 2026  
**Status**: ⚠️ **API KEYS EXPOSED IN CLIENT CODE - FIX BEFORE PRODUCTION**

---

## ⚠️ SECURITY ALERT

### Current Issue
Your 3 API keys are hardcoded in the frontend code (`lib/core/env_loader.dart`):
- ✅ GROQ_API_KEY: `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`
- ✅ RESEND_API_KEY: `re_R3rrA9aq_7GxoYpBpLjGiduZo3xV1K6WC`
- ✅ OCR_API_KEY: `K88578875488957`

### Why This is a Problem
❌ Anyone can inspect the source code
❌ Keys are visible in browser DevTools
❌ Keys are in your GitHub repository (if public)
❌ Attackers can abuse your API quotas
❌ Could cause unexpected charges

### Risk Assessment
| API | Risk | Why |
|-----|------|-----|
| **Groq** | MEDIUM | Free tier, rate limited, but can be abused |
| **Resend** | MEDIUM | Can send spam emails from your account |
| **OCR** | LOW | Free tier, but quota can be exhausted |

---

## 🚀 SOLUTION: Use Backend Proxy

### What is a Backend Proxy?
Instead of calling APIs directly from frontend:

```
❌ WRONG (Current - Exposed):
Browser → Groq API
Browser → Resend API
Browser → OCR API

✅ RIGHT (Secure):
Browser → Your Backend → Groq API
Browser → Your Backend → Resend API
Browser → Your Backend → OCR API
```

### Option 1: Use Supabase Edge Functions (RECOMMENDED)

**Easiest solution - no new server needed!**

**Step 1**: Create Edge Function for Groq
```bash
supabase functions new groq-proxy
```

**Step 2**: Edit `supabase/functions/groq-proxy/index.ts`:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { messages, model } = await req.json()
  
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('GROQ_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.1,
      max_tokens: 200,
    }),
  })
  
  return response
})
```

**Step 3**: Set environment variable in Supabase dashboard
- Go to: Project Settings → Edge Functions
- Add: `GROQ_API_KEY = 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`

**Step 4**: Update client code
```dart
// OLD (Exposed):
'Authorization': 'Bearer ${EnvLoader.get('GROQ_API_KEY')}',

// NEW (Secure - uses Edge Function proxy):
final response = await supabase.functions.invoke('groq-proxy', body: {
  'messages': messages,
  'model': 'llama-3.1-8b-instant',
});
```

### Option 2: Use Vercel Functions (if deploying to Vercel)

Create `api/groq-proxy.js`:
```javascript
export default async (req, res) => {
  const { messages } = req.body
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ messages }),
  })
  return res.json(await response.json())
}
```

Set environment variable: `GROQ_API_KEY=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`

### Option 3: Use AWS Lambda (for high volume)

Same concept - backend function that hides the keys.

---

## 📋 IMMEDIATE ACTIONS (Development)

### For Development/Testing (Current - OK)
✅ Using hardcoded keys in dev is acceptable
✅ But should be in `.gitignore`
✅ And behind a feature flag

### For Production (Must Fix)

**Step 1**: Remove keys from source code
```dart
// Replace in lib/core/env_loader.dart:
'GROQ_API_KEY': '',  // Remove key
'RESEND_API_KEY': '', // Remove key
'OCR_API_KEY': '',  // Remove key
```

**Step 2**: Store keys in backend/environment
- Supabase Edge Functions (recommended)
- Your backend server
- AWS Secrets Manager
- Environment variables

**Step 3**: Call through proxy
```dart
// Use Edge Function proxy instead
final response = await supabase.functions.invoke('groq-proxy', body: {...});
```

---

## 🔒 SECURITY CHECKLIST

### Before Going to Production

- [ ] Remove API keys from source code
- [ ] Set up Edge Function proxy (or backend proxy)
- [ ] Store keys in Supabase Secrets/backend only
- [ ] Add API key rotation plan
- [ ] Monitor API usage in dashboards
- [ ] Set up billing alerts
- [ ] Enable rate limiting on backend proxy

### Git Security

- [ ] Add `lib/core/env_loader.dart` to `.gitignore` (if using real keys)
- [ ] Or use `.env.example` template without real keys
- [ ] Check git history for exposed keys: `git log --all -S "gsk_"`
- [ ] If keys were exposed: regenerate them immediately!

### Monitoring

- [ ] Check Groq dashboard for unusual API usage
- [ ] Check Resend dashboard for unusual emails
- [ ] Set up alerts for quota limits

---

## 📝 FILE TO ADD TO .gitignore

```
# API Keys and Secrets
lib/core/env_loader.dart
.env
.env.local
.env.*.local
```

---

## 🚀 DEPLOYMENT TIMELINE

### NOW (Development)
✅ Keys are set and working
✅ App builds and runs
✅ All features functional

### THIS WEEK (Before Production)
- [ ] Set up Supabase Edge Functions proxy
- [ ] Test proxy works
- [ ] Remove keys from source code
- [ ] Deploy with proxy

### PRODUCTION
- [ ] Zero keys in source code
- [ ] All API calls through secure proxy
- [ ] Monitor for abuse
- [ ] Plan key rotation (quarterly)

---

## 💡 QUICK FIX FOR NOW (Development)

Your app is working fine for development. To be safe:

**Step 1**: Create `.env.local` (not committed to git)
```
GROQ_API_KEY=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
RESEND_API_KEY=re_R3rrA9aq_7GxoYpBpLjGiduZo3xV1K6WC
OCR_API_KEY=K88578875488957
```

**Step 2**: Add to `.gitignore`
```
.env.local
lib/core/env_loader.dart
```

**Step 3**: Create `lib/core/env_loader.dart.example`
```dart
class EnvLoader {
  static final Map<String, String> _env = {
    'GROQ_API_KEY': 'gsk_XXX',  // Get from .env.local
    'RESEND_API_KEY': 're_XXX',
    'OCR_API_KEY': 'K_XXX',
  };
}
```

---

## ⚠️ WHAT IF KEYS ARE COMPROMISED?

If these keys are publicly visible anywhere:

**Immediate Actions**:
1. **Groq**: Go to https://console.groq.com/ → Rotate API key
2. **Resend**: Go to https://resend.com/ → Rotate API key
3. **OCR**: Go to https://ocr.space/ → Rotate API key
4. **Git**: Remove from history: `git filter-branch`
5. **Update**: Update with new keys

---

## 📊 RECOMMENDED SETUP FOR PRODUCTION

```
┌─────────────────────────────────────────────────────────┐
│                      SECURE ARCHITECTURE                │
└─────────────────────────────────────────────────────────┘

Frontend (Flutter Web)
    ↓ (no API keys)
Supabase Backend
    ├─ Edge Functions (Groq Proxy)
    │   └─ GROQ_API_KEY (stored securely)
    ├─ Edge Functions (Resend Proxy)
    │   └─ RESEND_API_KEY (stored securely)
    └─ Edge Functions (OCR Proxy)
        └─ OCR_API_KEY (stored securely)
```

---

## 🎯 CURRENT STATUS

### What's Working Now ✅
- All 3 API keys configured
- App builds and runs
- All features functional
- Ready for development/testing

### What Needs Work Before Production 🔴
- Move keys to secure backend
- Remove keys from source code
- Set up API proxy
- Add .gitignore protection

---

## 📞 SUPPORT

**For Supabase Edge Functions help**:
- Docs: https://supabase.com/docs/guides/functions

**For API Security**:
- OWASP Guide: https://owasp.org/

**For monitoring API usage**:
- Groq Dashboard: https://console.groq.com/
- Resend Dashboard: https://resend.com/
- OCR Dashboard: https://ocr.space/

---

## ✅ FINAL RECOMMENDATION

**Right now for development**: ✅ Good to go
**Before deploying to production**: ⚠️ Must move keys to backend/Supabase Edge Functions
**Timeline**: Do this before Week 2 deployment

Once Edge Functions are set up, your keys will be 100% secure and you can deploy with confidence.

---

**Status**: 🟡 **DEVELOPMENT READY - PRODUCTION REQUIRES BACKEND PROXY**
