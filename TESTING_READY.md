# 🚀 API TESTING - GETTING STARTED

**Status**: Ready to Start  
**Date**: January 4, 2026

---

## ✅ CURRENT STATE

- ✅ Dependencies installed
- ✅ App building...
- ✅ Groq API service ready (lib/services/aura_ai_service.dart)
- ✅ Resend API service ready (lib/services/email_service.dart)
- ✅ Environment config ready (lib/services/env_loader.dart)
- ⚠️ App startup in progress

---

## 📋 BEFORE YOU TEST

### **Step 1: Add API Keys** (2 minutes)

You have two options:

#### **Option A: Development (Quick - for testing)**
Edit `lib/services/env_loader.dart`:

**Line 19** - Add Groq API Key:
```dart
'GROQ_API_KEY': 'gsk_YOUR_KEY_HERE', // Replace with your key from console.groq.com
```

**Line 22** - Add Resend API Key:
```dart
'RESEND_API_KEY': 're_YOUR_KEY_HERE', // Replace with your key from resend.com
```

#### **Option B: Production (Secure - recommended)**
Use Supabase Secrets (see API_INTEGRATION_SETUP.md for full guide)

### **Step 2: Get API Keys** (5 minutes total)

**Groq API Key**:
1. Go to: https://console.groq.com
2. Sign up (free tier available)
3. Create API key
4. Copy key (format: `gsk_...`)

**Resend API Key**:
1. Go to: https://resend.com
2. Sign up (free tier: 100 emails/day)
3. Create API key
4. Copy key (format: `re_...`)

### **Step 3: Save & Rebuild**

```bash
# After adding keys:
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 🧪 QUICK TEST SUITE

Once app is running, follow this sequence:

### **Test 1: Sign In** (30 seconds)
1. Open app in Chrome
2. Click "Sign In"
3. Enter test credentials (or create account)
4. Click "Sign In" button

**Expected**: Dashboard loads with bottom navigation

### **Test 2: Groq AI - Create Invoice** (1 minute)
1. Navigate to **Aura Chat** tab (bottom nav)
2. In chat input, type: `"Create invoice for Ahmed 500 AED"`
3. Click **Send**

**Expected**:
```
Loading indicator appears...
(Wait 2-3 seconds)
Message: "Invoice INV-2026-XXXXX created for 500 AED" ✅
```

### **Test 3: Verify Invoice in Database** (30 seconds)
1. Navigate to **Invoice List** tab
2. Look for newly created invoice

**Expected**:
```
┌─────────────────────────────┐
│ Invoice: INV-2026-XXXXX     │
│ Client: Ahmed               │
│ Amount: 500 AED             │
│ Status: pending             │
└─────────────────────────────┘
```

### **Test 4: Resend Email - Send Reminder** (1 minute)
1. In **Invoice List**, find the invoice you just created
2. Click **Send Reminder** button
3. Check your email inbox (the email used in invoice)

**Expected Email**:
```
From: Aurasphere CRM <invoices@aura-sphere.app>
Subject: Reminder: Invoice INV-2026-XXXXX is overdue
Body: Payment reminder with [Pay Now] button
```

### **Test 5: Multi-Language - French** (1 minute)
1. Change app language to **French** (in settings)
2. Type in chat: `"Créer une facture pour Jean 300 EUR"`
3. Check if invoice is created

**Expected**: Invoice created with French client name

### **Test 6: Error Handling** (1 minute)
1. Use wrong API key in env_loader.dart
2. Try to create invoice
3. Observe error message

**Expected**: User-friendly error, app doesn't crash

---

## 📊 EXPECTED RESULTS SUMMARY

| Test | Expected Outcome | Status |
|------|-----------------|--------|
| Sign In | Dashboard appears | ⏳ Pending |
| Groq API | Invoice created | ⏳ Pending |
| Database | Invoice in list | ⏳ Pending |
| Email | Reminder delivered | ⏳ Pending |
| French | Command understood | ⏳ Pending |
| Errors | Graceful handling | ⏳ Pending |

---

## 🔍 DEBUGGING

If something fails:

1. **Open DevTools** (F12 in Chrome)
2. **Check Console** for errors
3. **Check Network tab** for API requests
4. **Look for**:
   - `api.groq.com` requests
   - `api.resend.com` requests
   - HTTP 200 responses
   - Error messages (401, 400, etc.)

---

## 📞 SUPPORT

- **Groq Issues**: https://groq.com/support
- **Resend Issues**: https://resend.com/support
- **Supabase Issues**: https://supabase.com/docs

---

## ✅ VERIFICATION CHECKLIST

After all tests pass:

- [ ] Groq API working (invoices created via chat)
- [ ] Resend API working (emails delivered)
- [ ] Multi-language support verified
- [ ] Error handling works
- [ ] Real-time sync working (instant invoice appearance)
- [ ] No console errors
- [ ] App doesn't crash on errors

---

**Ready to start testing?**

1. Add API keys (2 min)
2. Rebuild app (`flutter run -d chrome`)
3. Follow Quick Test Suite above
4. Record results in API_VERIFICATION_TESTS.md

Good luck! 🚀
