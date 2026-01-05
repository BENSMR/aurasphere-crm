# 🚀 QUICK API ACTIVATION CODE

## 1️⃣ GROQ API KEY (AI Agents)

### ✅ Code Already in Place
File: `lib/services/aura_ai_service.dart` (lines 1-30)

```dart
static Future<Map<String, dynamic>?> parseCommand(String input, String userLang) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${EnvLoader.get('GROQ_API_KEY')}',  // ← Uses API key
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',  // Fast model (5B tokens/day free)
        'messages': [...],
        'temperature': 0.1,  // Deterministic responses
        'max_tokens': 200,
      }),
    );
    // ... handles response
  }
}
```

### 🔧 TO ACTIVATE:
1. Get key: https://console.groq.com/keys
2. Copy key value (looks like: `gsk_...`)
3. Open: `lib/services/env_loader.dart` (line 19)
4. Replace:
   ```dart
   'GROQ_API_KEY': '', // ← Add key here
   ```
   With:
   ```dart
   'GROQ_API_KEY': 'gsk_YOUR_ACTUAL_KEY_HERE',
   ```
5. Save file
6. Run: `flutter run -d chrome`
7. Test: Open Aura Chat → Type "create invoice for Ahmed 300 AED"

---

## 2️⃣ RESEND API KEY (Email Service)

### ✅ Code Already in Place
File: `lib/services/email_service.dart` (lines 1-30)

```dart
static Future<bool> sendPaymentReminder({
  required String toEmail,
  required String invoiceNumber,
  required double amount,
  required String currency,
  required String dueDate,
  String language = 'en',
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer ${EnvLoader.get('RESEND_API_KEY')}',  // ← Uses API key
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': 'Aurasphere CRM <invoices@aura-sphere.app>',
        'to': [toEmail],
        'subject': _getSubject(language, invoiceNumber),
        'html': _getHtmlBody(language, invoiceNumber, amount, currency, dueDate),
      }),
    );
    return response.statusCode == 200;
  }
}
```

### 🔧 TO ACTIVATE:
1. Get key: https://resend.com/api-keys
2. Copy key value (starts with: `re_`)
3. Open: `lib/services/env_loader.dart` (line 22)
4. Replace:
   ```dart
   'RESEND_API_KEY': '', // ← Add key here
   ```
   With:
   ```dart
   'RESEND_API_KEY': 're_YOUR_ACTUAL_KEY_HERE',
   ```
5. Save file
6. Run: `flutter run -d chrome`
7. Test: Create invoice → Mark as paid → Check email

---

## 3️⃣ PRODUCTION SETUP (Recommended)

### Via Supabase Secrets (Secure):
```bash
# 1. Install Supabase CLI
npm install -g supabase

# 2. Login
supabase login

# 3. Add Groq key
supabase secrets set GROQ_API_KEY "gsk_YOUR_KEY"

# 4. Add Resend key
supabase secrets set RESEND_API_KEY "re_YOUR_KEY"

# 5. Verify
supabase secrets list

# 6. Deploy
vercel deploy build/web --prod
```

---

## 4️⃣ UPDATED ENV LOADER

**File**: `lib/services/env_loader.dart`

```dart
class EnvLoader {
  static final Map<String, String> _fallbackEnv = {
    // Supabase (already configured)
    'SUPABASE_URL': 'https://fppmvibvpxrkwmymszhd.supabase.co',
    'SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    
    // ✨ NEW: AI & Email APIs
    'GROQ_API_KEY': '', // ← Paste your Groq key here
    'RESEND_API_KEY': '', // ← Paste your Resend key here
    
    // Optional: For future features
    'STRIPE_PUBLIC_KEY': '',
    'STRIPE_SECRET_KEY': '',
    'TWILIO_ACCOUNT_SID': '',
    'TWILIO_AUTH_TOKEN': '',
  };

  static String get(String key) {
    final value = _fallbackEnv[key];
    if (value == null || value.isEmpty) {
      print('⚠️  "$key" not configured. Feature disabled.');
    }
    return value ?? '';
  }

  static bool isConfigured(String key) {
    return (_fallbackEnv[key] ?? '').isNotEmpty;
  }
}
```

---

## 5️⃣ HOW TO GET API KEYS

### GROQ API Key:
```
1. Go to: https://console.groq.com
2. Sign up (free)
3. Click: "API Keys"
4. Click: "Create API Key"
5. Copy: gsk_...
6. Rate limit: 14,400 requests/min (free tier)
```

### RESEND API Key:
```
1. Go to: https://resend.com
2. Sign up (free)
3. Click: "API Keys"
4. Click: "Create API Key"
5. Copy: re_...
6. Rate limit: 100 emails/day (free), then pay-as-you-go
```

---

## 6️⃣ TESTING CHECKLIST

### Test Groq (AI Agents):
```
✅ Step 1: Add GROQ_API_KEY to env_loader.dart
✅ Step 2: Run: flutter run -d chrome
✅ Step 3: Login to app
✅ Step 4: Go to "Aura Chat" page
✅ Step 5: Type: "create invoice for Ahmed 500 AED"
✅ Step 6: AI should automatically create invoice
✅ Step 7: Check dashboard - invoice appears
```

### Test Resend (Email):
```
✅ Step 1: Add RESEND_API_KEY to env_loader.dart
✅ Step 2: Run: flutter run -d chrome
✅ Step 3: Login to app
✅ Step 4: Create an invoice
✅ Step 5: Mark as paid
✅ Step 6: Check email inbox
✅ Step 7: Payment reminder email arrives
```

---

## 7️⃣ TROUBLESHOOTING

### Error: "401 Unauthorized" (Groq)
```
❌ Cause: Invalid or missing API key
✅ Fix:
   1. Check key at: https://console.groq.com/keys
   2. Copy exact key (no spaces)
   3. Update: lib/services/env_loader.dart
   4. Hot reload or restart app
```

### Error: "401 Unauthorized" (Resend)
```
❌ Cause: Invalid or missing API key
✅ Fix:
   1. Check key at: https://resend.com/api-keys
   2. Ensure key starts with "re_"
   3. Update: lib/services/env_loader.dart
   4. Hot reload or restart app
```

### Error: "Email not sent"
```
❌ Cause: Sender domain not verified
✅ Fix:
   1. Go to: https://resend.com/emails
   2. Add domain: invoices@aura-sphere.app
   3. Follow verification steps
   4. Wait 30 min for verification
   5. Try again
```

### Groq AI returning null
```
❌ Cause: API key not set or rate limit exceeded
✅ Fix:
   1. Verify key in env_loader.dart
   2. Check Groq dashboard for usage
   3. Try simpler command: "list invoices"
   4. Wait a minute and retry
```

---

## 8️⃣ FEATURES UNLOCKED

### When Groq is Activated:
✅ Voice/text commands in natural language
✅ Automatic invoice creation ("create invoice for Ahmed 300 AED")
✅ Automatic expense logging ("log 50 AED for fuel")
✅ Client management ("add client John Smith")
✅ 5 AI agents: CEO, CFO, Marketing, Sales, Admin
✅ Multi-language support: EN, FR, IT, AR, MT, DE, ES, BG

### When Resend is Activated:
✅ Payment reminders (overdue invoices)
✅ Invoice confirmations
✅ Receipt notifications
✅ HTML-styled professional emails
✅ Multi-language support: EN, FR, AR

---

## 9️⃣ OPTIONAL CONFIGURATIONS

**Future API Keys (not required now):**

```dart
// Stripe (for payments)
'STRIPE_PUBLIC_KEY': 'pk_live_...',
'STRIPE_SECRET_KEY': 'sk_live_...',

// Twilio (for WhatsApp)
'TWILIO_ACCOUNT_SID': 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
'TWILIO_AUTH_TOKEN': 'your_auth_token',

// SendGrid (alternative to Resend)
'SENDGRID_API_KEY': 'SG.xxx...',
```

These can be added later as needed.

---

## 🎯 FINAL SETUP SUMMARY

| Step | Action | Time | Status |
|------|--------|------|--------|
| 1 | Get Groq API key | 2 min | ⏳ Todo |
| 2 | Get Resend API key | 2 min | ⏳ Todo |
| 3 | Add keys to env_loader.dart | 1 min | ⏳ Todo |
| 4 | Test Groq in Aura Chat | 2 min | ⏳ Todo |
| 5 | Test Resend with invoice | 2 min | ⏳ Todo |
| 6 | Deploy to production | 5 min | ⏳ Todo |

**Total Time**: ~15 minutes

---

**Status**: ✅ Ready to implement!  
**Generated**: January 4, 2026  
**Document**: QUICK_API_ACTIVATION.md
