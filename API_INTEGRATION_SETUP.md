# 🔗 API Integration Setup Guide

## 1. ✅ GROQ API SETUP (AI Agents)

### Step 1: Get Your Groq API Key
1. Go to https://console.groq.com
2. Sign up / Login
3. Create API Key
4. Copy the key

### Step 2: Add to Supabase (Recommended)
**Option A: Via Supabase Dashboard**
1. Go to `https://app.supabase.com` → Your Project
2. Navigate to **Settings** → **Secrets**
3. Add new secret:
   - Key: `GROQ_API_KEY`
   - Value: `your_groq_api_key_here`
4. Click **Save**

**Option B: Via Supabase CLI**
```bash
supabase secrets set GROQ_API_KEY="your_groq_api_key_here"
```

### Step 3: Update Environment Loader
**File**: `lib/services/env_loader.dart`

```dart
class EnvLoader {
  // Fallback values for web (hardcoded from Supabase project)
  static final Map<String, String> _fallbackEnv = {
    'SUPABASE_URL': 'https://fppmvibvpxrkwmymszhd.supabase.co',
    'SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    'GROQ_API_KEY': '', // ← Add your key here (optional for web)
    'RESEND_API_KEY': '', // ← Add your Resend key here
  };

  static Future<void> init() async {
    // For server-side: load from Supabase secrets
    // For web: use fallback values above
  }

  static String get(String key) {
    return _fallbackEnv[key] ?? '';
  }
}
```

### Step 4: Verify Groq Integration
**File**: `lib/services/aura_ai_service.dart` ✅ (Already configured)

The service already uses:
```dart
'Authorization': 'Bearer ${EnvLoader.get('GROQ_API_KEY')}',
'model': 'llama-3.1-8b-instant',  // Fast & accurate
'temperature': 0.1,  // Low temperature = deterministic
'max_tokens': 200,  // Short responses
```

**Supported AI Actions**:
- ✅ Create Invoice
- ✅ Create Expense  
- ✅ Create Client
- ✅ List Invoices
- ✅ List Clients
- ✅ List Expenses

**Supported Languages**: EN, FR, IT, AR, MT, DE, ES, BG

---

## 2. ✅ RESEND API SETUP (Email Service)

### Step 1: Get Your Resend API Key
1. Go to https://resend.com
2. Sign up / Login
3. Navigate to **API Keys**
4. Click **Create API Key**
5. Copy the key (starts with `re_`)

### Step 2: Add to Supabase
**Option A: Via Supabase Dashboard**
1. Go to `https://app.supabase.com` → Your Project
2. Navigate to **Settings** → **Secrets**
3. Add new secret:
   - Key: `RESEND_API_KEY`
   - Value: `re_your_resend_api_key_here`
4. Click **Save**

**Option B: Via Supabase CLI**
```bash
supabase secrets set RESEND_API_KEY="re_your_resend_api_key_here"
```

### Step 3: Verify Resend (Sendgrid Alternative)
**File**: `lib/services/email_service.dart` ✅ (Already configured)

The service already uses:
```dart
'Authorization': 'Bearer ${EnvLoader.get('RESEND_API_KEY')}',
'from': 'Aurasphere CRM <invoices@aura-sphere.app>', // ← Update this domain
'to': [toEmail],
'subject': _getSubject(language, invoiceNumber),
'html': _getHtmlBody(language, invoiceNumber, amount, currency, dueDate),
```

**Supported Email Features**:
- ✅ Payment Reminders
- ✅ Invoice Notifications
- ✅ Multi-language (EN, FR, AR)
- ✅ HTML templates

---

## 3. 🔄 DEPLOYMENT STEPS

### Step A: Local Testing
```bash
# 1. Update env_loader.dart with your API keys
# 2. Test Groq AI
flutter run -d chrome

# In app, go to: Aura Chat → Type "create invoice for Ahmed 300 AED"
# Expected: AI creates invoice automatically

# 3. Test Email
# Go to: Invoice → Mark as paid
# Expected: Payment confirmation email sent
```

### Step B: Production Deployment
```bash
# 1. Add secrets to Supabase (see above)
# 2. Build for web
flutter build web --release

# 3. Deploy
vercel deploy build/web --prod
```

---

## 4. 📋 QUICK CHECKLIST

| Component | Status | Action |
|-----------|--------|--------|
| **Groq API** | ✅ Integrated | Add key to `env_loader.dart` or Supabase Secrets |
| **Groq Models** | ✅ Configured | Using `llama-3.1-8b-instant` |
| **Resend API** | ✅ Integrated | Add key to `env_loader.dart` or Supabase Secrets |
| **Email Templates** | ✅ Ready | 3 languages (EN, FR, AR) |
| **AI Agents** | ✅ Ready | 5 agents (CEO, CFO, Marketing, Sales, Admin) |
| **Webhook Support** | ✅ Available | For real-time sync |

---

## 5. 🆘 TROUBLESHOOTING

### Groq API Error: "Invalid API Key"
```
Solution:
1. Verify key at https://console.groq.com/keys
2. Check env_loader.dart has correct key
3. Ensure no spaces in key
4. Redeploy
```

### Resend Email Not Sending
```
Solution:
1. Verify Resend API key at https://resend.com/api-keys
2. Check sender domain is verified
3. Add SPF/DKIM records if custom domain
4. Check email recipient is valid
5. View Resend dashboard for error logs
```

### Missing API Key Error
```
Solution:
1. Open lib/services/env_loader.dart
2. Add keys to _fallbackEnv map
3. Save file
4. Hot reload (flutter run -d chrome)
5. Test again
```

---

## 6. 📊 EXPECTED BEHAVIOR

### When Groq Key is SET ✅
```
User: "Create invoice for Ahmed 500 AED"
↓
Groq processes: "create_invoice" action
↓
App: Creates invoice automatically
↓
Result: Invoice shown in dashboard
```

### When Groq Key is NOT SET ⚠️
```
User: "Create invoice for Ahmed 500 AED"
↓
Groq returns: null
↓
App: Shows manual form
↓
User: Fills form manually
```

### When Resend Key is SET ✅
```
Invoice marked as paid
↓
App sends via Resend
↓
Recipient gets email in 30 seconds
↓
Email shows in Resend dashboard
```

### When Resend Key is NOT SET ⚠️
```
Invoice marked as paid
↓
App tries to send
↓
Error logged to console
↓
Email NOT sent (feature disabled)
```

---

## 7. 🚀 NEXT STEPS

1. **Get API Keys**
   - Groq: https://console.groq.com → Create Key
   - Resend: https://resend.com → Create API Key

2. **Add to Supabase**
   - Go to https://app.supabase.com
   - Settings → Secrets
   - Add both keys

3. **Update Local Config** (if testing locally)
   - Edit `lib/services/env_loader.dart`
   - Add keys to `_fallbackEnv` map

4. **Test**
   - Run: `flutter run -d chrome`
   - Try Aura Chat for Groq
   - Create invoice for Resend

5. **Deploy**
   - Build: `flutter build web --release`
   - Deploy: `vercel deploy build/web --prod`

---

**Status**: ✅ Ready to activate!  
**Generated**: January 4, 2026
