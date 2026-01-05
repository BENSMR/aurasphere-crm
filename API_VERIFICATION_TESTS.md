# ✅ GROQ & RESEND API - VERIFICATION & TESTING GUIDE

**Date**: January 4, 2026  
**Status**: Ready for Testing  
**Environment**: Supabase Integrated

---

## 📋 VERIFICATION CHECKLIST

### **Pre-Test Requirements**

- [ ] Groq API Key obtained from https://console.groq.com
- [ ] Resend API Key obtained from https://resend.com
- [ ] Keys added to `lib/services/env_loader.dart` (lines 19, 22)
- [ ] App built: `flutter clean && flutter pub get && flutter build web --release`
- [ ] Build artifacts ready: `build/web/index.html` exists
- [ ] Chrome/Firefox browser available
- [ ] Supabase dashboard open: https://app.supabase.com

---

## 🧪 TEST SUITE 1: GROQ AI INTEGRATION

### **Test 1.1: API Key Configuration**

**Objective**: Verify Groq API key is properly loaded

```bash
# Step 1: Open Developer Console (F12)
# Step 2: In Console, paste:
console.log("Checking Groq API configuration...");
// The app should NOT log warnings about missing GROQ_API_KEY

# Expected Output:
✅ No warnings in console about "GROQ_API_KEY is not set"
✅ App loads without errors
```

**Pass Criteria**:
- No console errors related to API keys
- App loads successfully
- Aura Chat tab is accessible

---

### **Test 1.2: Chat Input Validation**

**Objective**: Verify user can input commands in Aura Chat

**Steps**:
1. Open app: `flutter run -d chrome`
2. Navigate to **Aura Chat** tab
3. Type: `"Create invoice for Ahmed 500 AED"`
4. Click Send button

**Expected Output**:
```
Loading indicator appears...
(Wait 2-3 seconds for Groq API response)
Message appears: "Invoice INV-2026-XXXXX created for 500 AED"
✅ Chat displays success message
```

**Pass Criteria**:
- Message accepted without validation errors
- Send button responds to click
- Loading state visible during processing
- Success message returned within 5 seconds

---

### **Test 1.3: Groq API Call Verification**

**Objective**: Confirm API request reaches Groq servers

**Steps**:
1. Open DevTools Network tab (F12 → Network)
2. Type in Aura Chat: `"Create client Omar"`
3. Look for HTTP request to `api.groq.com`

**Expected Network Request**:
```
POST https://api.groq.com/openai/v1/chat/completions
Headers:
  Authorization: Bearer gsk_XXXXXXXXX...
  Content-Type: application/json

Request Body:
{
  "model": "llama-3.1-8b-instant",
  "messages": [
    {
      "role": "system",
      "content": "You are Aura, the proactive CRM assistant..."
    },
    {
      "role": "user",
      "content": "Create client Omar"
    }
  ],
  "temperature": 0.1,
  "max_tokens": 200
}

Response (HTTP 200):
{
  "choices": [
    {
      "message": {
        "content": "{\"action\":\"create_client\",\"name\":\"Omar\"}"
      }
    }
  ]
}
```

**Pass Criteria**:
- HTTP 200 status code
- Request headers include Authorization Bearer token
- Response contains valid JSON with action
- Response time < 3 seconds

---

### **Test 1.4: Database Integration - Create Invoice**

**Objective**: Verify Groq action execution saves to Supabase

**Steps**:
1. In Aura Chat, send: `"Create invoice for Sarah 250 EUR"`
2. Success message appears
3. Navigate to **Invoice List** page
4. Check if new invoice appears in the table

**Expected Result**:
```
Invoice List shows new entry:
┌─────────────────────────────┐
│ Invoice Number: INV-2026-... │
│ Client: Sarah               │
│ Amount: 250 EUR             │
│ Status: pending             │
│ Created: [Today's date]     │
└─────────────────────────────┘

✅ Invoice stored in supabase.invoices table
```

**Verify in Supabase**:
1. Go to https://app.supabase.com
2. Select your project
3. Navigate to SQL Editor
4. Run:
```sql
SELECT * FROM invoices 
WHERE client_id = (SELECT id FROM clients WHERE name = 'Sarah')
ORDER BY created_at DESC LIMIT 1;
```

**Pass Criteria**:
- Invoice appears in Invoice List UI
- Database query returns the record
- All fields correctly saved (amount, currency, status, dates)
- Timestamps are correct

---

### **Test 1.5: Multi-Language Support - French**

**Objective**: Test Groq with French language input

**Steps**:
1. Change app language to French (in settings)
2. In Aura Chat, send: `"Créer une facture pour Jean 300 EUR"`
3. Verify response and invoice creation

**Expected Output**:
```
Groq receives:
- userLang: "fr"
- System prompt in French language
- User input in French

Response: {"action":"create_invoice","client_name":"Jean",...}
Success message in French UI
Invoice created successfully
```

**Pass Criteria**:
- Command understood in French
- Invoice created with French client name
- No encoding issues with special characters (é, è, etc.)

---

### **Test 1.6: Multi-Language Support - Arabic**

**Objective**: Test Groq with Arabic language input

**Steps**:
1. Change app language to Arabic
2. In Aura Chat, send: `"إنشاء فاتورة لأحمد 400 AED"`
3. Verify response and invoice creation

**Expected Output**:
```
Groq receives:
- userLang: "ar"
- System prompt in Arabic
- User input in Arabic RTL

Response: {"action":"create_invoice","client_name":"أحمد",...}
Invoice created with Arabic client name
UI displays RTL correctly
```

**Pass Criteria**:
- Arabic text processed correctly
- Invoice created with Arabic characters
- RTL layout displays properly
- No encoding errors

---

### **Test 1.7: Error Handling - Invalid API Key**

**Objective**: Verify graceful failure with wrong key

**Steps**:
1. Change Groq API key to invalid value: `gsk_WRONG1234567890`
2. In Aura Chat, send: `"Create invoice for Test 100 EUR"`
3. Observe error handling

**Expected Output**:
```
HTTP 401 Unauthorized from Groq API
App catches error and displays:
"Unable to process command. Please try again."

Console logs:
❌ Groq error: 401 Unauthorized

✅ App does not crash
✅ Chat remains functional
```

**Pass Criteria**:
- Error caught gracefully
- User-friendly error message shown
- No app crash
- Console error logged for debugging

---

## 🧪 TEST SUITE 2: RESEND EMAIL INTEGRATION

### **Test 2.1: Email API Configuration**

**Objective**: Verify Resend API key is properly loaded

```bash
# Step 1: Open Developer Console (F12)
# Step 2: Check console for warnings
# Expected: No warnings about "RESEND_API_KEY is not set"
```

**Pass Criteria**:
- No console errors about missing API keys
- App loads successfully

---

### **Test 2.2: Create Invoice & Send Reminder Email**

**Objective**: Test end-to-end email sending workflow

**Steps**:
1. Navigate to **Invoice List** page
2. Create new invoice:
   - Client: `test@example.com`
   - Amount: `500`
   - Currency: `USD`
   - Due Date: `2025-12-31`
3. Click **Send Reminder** button on invoice
4. Check email inbox for payment reminder

**Expected Email**:
```
From: Aurasphere CRM <invoices@aura-sphere.app>
To: test@example.com
Subject: Reminder: Invoice INV-2026-XXXXX is overdue

Body:
┌─────────────────────────────────┐
│ Payment Reminder                │
│                                 │
│ Hi there,                       │
│                                 │
│ Your invoice INV-2026-XXXXX    │
│ for USD 500 was due on         │
│ 2025-12-31                      │
│                                 │
│ [Pay Now Button]                │
│ (Links to: crm.aura-sphere.app) │
│                                 │
│ Thank you for your business!    │
│                                 │
│ Sent by Aurasphere CRM          │
└─────────────────────────────────┘
```

**Verify in Resend Dashboard**:
1. Go to https://resend.com/emails
2. Check Email Activity for delivery confirmation
3. Verify status: ✅ Delivered

**Pass Criteria**:
- Email sent successfully (HTTP 200)
- Email received in inbox (not spam)
- All fields rendered correctly
- Payment button clickable
- Timestamps accurate

---

### **Test 2.3: Multi-Language Email - French**

**Objective**: Test French email template

**Steps**:
1. Create invoice with client in French-speaking region
2. Set app language to French
3. Click **Send Reminder**
4. Check email

**Expected Email Subject**:
```
Rappel : La facture INV-2026-XXXXX est en retard
```

**Expected Email Body** (French):
```
Bonjour,

Votre facture INV-2026-XXXXX d'un montant de 
USD 500 était due le 2025-12-31.

Veuillez effectuer le paiement dès que possible:

[Payer maintenant]

Merci pour votre confiance!

Envoyé par Aurasphere CRM
```

**Pass Criteria**:
- Subject in French
- Body in French
- Special characters (é, è, ç) rendered correctly
- No encoding issues

---

### **Test 2.4: Multi-Language Email - Arabic**

**Objective**: Test Arabic email with RTL support

**Steps**:
1. Create invoice and set app to Arabic
2. Click **Send Reminder**
3. Check email in Arabic

**Expected Email Subject**:
```
تذكير: الفاتورة INV-2026-XXXXX متأخرة
```

**Expected Email Body** (Arabic RTL):
```
مرحبا،

فاتورتك INV-2026-XXXXX بمبلغ 
USD 500 كان موعد استحقاقها في 2025-12-31.

يرجى إتمام الدفع في أقرب وقت ممكن:

[ادفع الآن]

شكراً لك على تعاملك معنا!

أرسلت من Aurasphere CRM
```

**Pass Criteria**:
- Arabic text rendered RTL correctly
- Subject in Arabic
- Body in Arabic with RTL `dir="rtl"` applied
- No encoding issues with Arabic characters

---

### **Test 2.5: Email Delivery Verification**

**Objective**: Confirm HTTP 200 response from Resend API

**Steps**:
1. Open DevTools Network tab
2. Create invoice and click Send Reminder
3. Find POST request to `api.resend.com/emails`

**Expected Network Request**:
```
POST https://api.resend.com/emails
Headers:
  Authorization: Bearer re_XXXXXXXXX...
  Content-Type: application/json

Request Body:
{
  "from": "Aurasphere CRM <invoices@aura-sphere.app>",
  "to": ["customer@example.com"],
  "subject": "Reminder: Invoice INV-2026-XXXXX is overdue",
  "html": "<h2>Payment Reminder</h2>..."
}

Response (HTTP 200):
{
  "id": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "from": "invoices@aura-sphere.app",
  "to": "customer@example.com",
  "created_at": "2026-01-04T12:00:00.000Z"
}
```

**Pass Criteria**:
- HTTP 200 status
- Response includes email ID
- Response time < 2 seconds
- Authorization header present

---

### **Test 2.6: Error Handling - Invalid Email Address**

**Objective**: Test handling of invalid recipient email

**Steps**:
1. Create invoice with invalid email: `not-an-email`
2. Click **Send Reminder**
3. Observe error handling

**Expected Behavior**:
```
Resend API returns HTTP 400 Bad Request
App shows error message:
"Failed to send email. Please check recipient address."

Console logs error for debugging
Chat remains functional
```

**Pass Criteria**:
- Error handled gracefully
- User-friendly message displayed
- App doesn't crash

---

### **Test 2.7: Error Handling - Wrong API Key**

**Objective**: Test behavior with invalid Resend key

**Steps**:
1. Change Resend key to: `re_INVALID1234567890`
2. Click **Send Reminder** on any invoice
3. Observe error response

**Expected Behavior**:
```
HTTP 401 Unauthorized from Resend API
App displays:
"Email service not configured. Please contact support."

Console logs 401 error
Button disabled temporarily (retry mechanism)
```

**Pass Criteria**:
- HTTP 401 handled properly
- Clear error messaging
- No app crash
- Retry mechanism (optional) works

---

## 🔍 TEST SUITE 3: SUPABASE INTEGRATION VERIFICATION

### **Test 3.1: Real-Time Sync - Invoice Updates**

**Objective**: Verify Supabase real-time listeners work

**Steps**:
1. Open Invoice List page
2. In Aura Chat, create new invoice: `"Create invoice for Alex 1000 EUR"`
3. Watch Invoice List page
4. New invoice should appear immediately without refresh

**Expected Behavior**:
```
Aura Chat: Success message "Invoice created"
Invoice List: New row appears instantly
Database: Record appears in supabase.invoices
Real-time subscription triggers UI update
```

**Pass Criteria**:
- Invoice appears instantly (< 1 second)
- No manual page refresh needed
- UI updates automatically via PostgreSQL listener
- Data consistency between UI and database

---

### **Test 3.2: Row-Level Security (RLS) Verification**

**Objective**: Verify only authenticated users can access data

**Steps**:
1. Open app with valid login
2. Open Browser DevTools
3. In Console, attempt:
```javascript
// This should work (authenticated)
await supabaseClient
  .from('invoices')
  .select('*')
  .limit(1);
```
4. Logout
5. Try same query in Console

**Expected Behavior**:
```
With Authentication:
✅ Query succeeds, returns data

Without Authentication:
❌ Query fails with error:
"new row violates row-level security policy"
```

**Pass Criteria**:
- Authenticated users access data
- Unauthenticated users blocked by RLS
- Database enforces security policies

---

### **Test 3.3: Data Isolation - Multi-Tenant**

**Objective**: Verify organizations see only their data

**Steps**:
1. Create Account 1: User A (Org: Company A)
2. Create Account 2: User B (Org: Company B)
3. User A creates invoice for Client X
4. Login as User B
5. Check if User B can see User A's invoice

**Expected Behavior**:
```
User A sees: Their invoice for Client X
User B sees: Empty invoice list (no cross-tenant data)
Supabase RLS: Automatically filters by org_id
```

**Pass Criteria**:
- Each organization sees only their data
- RLS policies enforce tenant isolation
- No data leakage between organizations

---

### **Test 3.4: Supabase Secrets - Secure Key Storage**

**Objective**: Verify API keys stored in Supabase (if using Edge Functions)

**Steps**:
1. Go to https://app.supabase.com → Settings → Secrets
2. Verify keys are stored (not visible in plaintext in client code)
3. Check that Edge Functions can access them

**Expected Secrets**:
```
GROQ_API_KEY: gsk_XXXXXXXXX...
RESEND_API_KEY: re_XXXXXXXXX...
```

**Pass Criteria**:
- Keys stored in Supabase Vault
- Not visible in frontend code
- Edge Functions can access via Deno.env.get()
- Keys never transmitted to client browser

---

## 📊 TEST RESULTS SUMMARY

### **Groq API Tests**

| Test | Status | Notes |
|------|--------|-------|
| 1.1 - API Key Config | ⏳ Pending | ✅ Pass / ❌ Fail |
| 1.2 - Chat Input | ⏳ Pending | ✅ Pass / ❌ Fail |
| 1.3 - API Call | ⏳ Pending | ✅ Pass / ❌ Fail |
| 1.4 - Database Insert | ⏳ Pending | ✅ Pass / ❌ Fail |
| 1.5 - French Lang | ⏳ Pending | ✅ Pass / ❌ Fail |
| 1.6 - Arabic Lang | ⏳ Pending | ✅ Pass / ❌ Fail |
| 1.7 - Error Handling | ⏳ Pending | ✅ Pass / ❌ Fail |

### **Resend API Tests**

| Test | Status | Notes |
|------|--------|-------|
| 2.1 - API Key Config | ⏳ Pending | ✅ Pass / ❌ Fail |
| 2.2 - Email Send | ⏳ Pending | ✅ Pass / ❌ Fail |
| 2.3 - French Email | ⏳ Pending | ✅ Pass / ❌ Fail |
| 2.4 - Arabic Email | ⏳ Pending | ✅ Pass / ❌ Fail |
| 2.5 - HTTP 200 | ⏳ Pending | ✅ Pass / ❌ Fail |
| 2.6 - Invalid Email | ⏳ Pending | ✅ Pass / ❌ Fail |
| 2.7 - Invalid Key | ⏳ Pending | ✅ Pass / ❌ Fail |

### **Supabase Integration Tests**

| Test | Status | Notes |
|------|--------|-------|
| 3.1 - Real-Time Sync | ⏳ Pending | ✅ Pass / ❌ Fail |
| 3.2 - RLS Security | ⏳ Pending | ✅ Pass / ❌ Fail |
| 3.3 - Data Isolation | ⏳ Pending | ✅ Pass / ❌ Fail |
| 3.4 - Secrets Vault | ⏳ Pending | ✅ Pass / ❌ Fail |

---

## 🚀 QUICK TEST SEQUENCE (5 minutes)

For fast verification, run these tests in order:

1. **Test 1.2**: Type `"Create invoice for Test 100 AED"` in Aura Chat
   - ⏱️ 30 seconds
   - Verifies: Groq API key, chat input, API call

2. **Test 1.4**: Check Invoice List for new invoice
   - ⏱️ 15 seconds
   - Verifies: Database integration, Supabase insert

3. **Test 2.2**: Click **Send Reminder** on invoice
   - ⏱️ 2 minutes
   - Verifies: Resend API key, email delivery

4. **Test 3.1**: Check if Invoice List updates in real-time
   - ⏱️ 10 seconds
   - Verifies: Supabase real-time listeners

**Total**: ~3-5 minutes for critical path verification

---

## 🔧 DEBUGGING TIPS

### **Groq API Issues**

| Problem | Solution |
|---------|----------|
| **401 Unauthorized** | Check API key format: `gsk_...` |
| **No response after 5s** | Check rate limits (14,400 req/min free) |
| **JSON parse error** | Verify Groq response contains valid JSON |
| **Command not recognized** | Check language-specific prompt in code |

### **Resend API Issues**

| Problem | Solution |
|---------|----------|
| **401 Unauthorized** | Check API key format: `re_...` |
| **Email not received** | Check spam folder, verify from domain |
| **HTML not rendering** | Check HTML template syntax |
| **CORS error** | Ensure Resend origin is whitelisted |

### **Supabase Issues**

| Problem | Solution |
|---------|----------|
| **Data not saving** | Check RLS policies, verify user auth |
| **Real-time not updating** | Enable real-time broadcasts on table |
| **Secrets not accessible** | Verify Edge Function has permission |
| **Auth token expired** | Clear browser cache, re-login |

---

## 📞 SUPPORT RESOURCES

**Groq**:
- API Docs: https://console.groq.com/docs
- Status Page: https://status.groq.com
- Support: https://groq.com/support

**Resend**:
- API Docs: https://resend.com/docs
- Email Activity: https://resend.com/emails
- Support: https://resend.com/support

**Supabase**:
- Docs: https://supabase.com/docs
- Dashboard: https://app.supabase.com
- Status: https://status.supabase.com

---

## ✅ SIGN-OFF CHECKLIST

Once all tests pass, verify:

- [ ] All 7 Groq tests passing
- [ ] All 7 Resend tests passing
- [ ] All 4 Supabase tests passing
- [ ] No console errors
- [ ] No performance issues (< 3s for API calls)
- [ ] Multi-language support verified (EN, FR, AR)
- [ ] Error handling working correctly
- [ ] Real-time sync functioning
- [ ] Data isolation confirmed
- [ ] API keys secure in Supabase

**Status**: 🟢 **READY FOR PRODUCTION** (after all tests pass)

---

**Document Created**: January 4, 2026  
**Last Updated**: January 4, 2026  
**Version**: 1.0
