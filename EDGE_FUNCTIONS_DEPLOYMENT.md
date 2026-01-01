# 🚀 Edge Functions Deployment Guide

## ✅ Functions Created

Two Edge Functions have been created and are ready to deploy:

### 1. **send-email** (`supabase/functions/send-email/index.ts`)
- **Purpose**: Send emails securely using Resend
- **Triggers**: From invoice sending, notifications, etc.
- **Secret Required**: `RESEND_API_KEY`

### 2. **scan-receipt** (`supabase/functions/scan-receipt/index.ts`)
- **Purpose**: Process receipt images using OCR
- **Triggers**: From expense creation with receipt upload
- **Secret Required**: `OCR_API_KEY`

---

## 📋 Deployment Steps

### Step 1: Authenticate with Supabase CLI

```bash
supabase login
```

This will prompt you to:
1. Enter your Supabase project URL
2. Enter your Supabase API key (get from Dashboard → Settings → API)
3. Authenticate via browser

### Step 2: Set Project Reference

If you haven't already, configure your local Supabase project:

```bash
supabase init
```

Or link to your existing project:

```bash
supabase link --project-ref fppmvibvpxrkwmymszhd
```

### Step 3: Deploy send-email Function

```bash
supabase functions deploy send-email
```

**Expected Output**:
```
✅ Function send-email deployed successfully!
  Endpoint: https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/send-email
```

### Step 4: Deploy scan-receipt Function

```bash
supabase functions deploy scan-receipt
```

**Expected Output**:
```
✅ Function scan-receipt deployed successfully!
  Endpoint: https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/scan-receipt
```

### Step 5: Add Secrets to Functions

#### For send-email function:

Go to **Supabase Dashboard** → **Edge Functions** → **send-email** → **Configuration**

Add the secret:
- **Name**: `RESEND_API_KEY`
- **Value**: `re_[YOUR_NEW_RESEND_KEY]`
- Click **Save**

#### For scan-receipt function:

Go to **Supabase Dashboard** → **Edge Functions** → **scan-receipt** → **Configuration**

Add the secret:
- **Name**: `OCR_API_KEY`
- **Value**: `[YOUR_NEW_OCR_KEY]`
- Click **Save**

### Step 6: Verify Deployment

```bash
# List all deployed functions
supabase functions list

# Expected output:
# send-email    | Deployed ✅
# scan-receipt  | Deployed ✅
```

---

## 🧪 Test the Functions

### Test send-email

```bash
curl -X POST https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/send-email \
  -H "Authorization: Bearer [YOUR_ANON_KEY]" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "test@example.com",
    "subject": "Test Email",
    "body": "<h1>Hello!</h1><p>This is a test email from AuraSphere CRM</p>"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Email sent successfully",
  "emailId": "email_123abc..."
}
```

### Test scan-receipt

```bash
curl -X POST https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/scan-receipt \
  -H "Authorization: Bearer [YOUR_ANON_KEY]" \
  -H "Content-Type: application/json" \
  -d '{
    "imageBase64": "[BASE64_ENCODED_IMAGE_DATA]"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Receipt scanned successfully",
  "rawText": "Vendor Inc\n2024-01-01\n$45.99",
  "parsedData": {
    "vendor": "Vendor Inc",
    "amount": "$45.99",
    "date": "2024-01-01",
    "items": [...]
  }
}
```

---

## 🔐 Function Security

Both functions are configured with:

✅ **CORS Headers**: Allows requests from your Flutter web app
✅ **Secrets Management**: API keys stored in Supabase (not in code)
✅ **Input Validation**: Both functions validate required fields
✅ **Error Handling**: Safe error messages without exposing internals

---

## 🔗 Integration with Flutter App

The functions are called through `backend_api_proxy.dart`:

```dart
// Send email example
final proxy = BackendApiProxy();
final result = await proxy.sendEmail(
  to: 'client@example.com',
  subject: 'Your Invoice',
  body: '<h1>Invoice Details</h1>...',
);

// Scan receipt example
final receipt = await proxy.processImageOCR('base64_image_data');
```

---

## ⚠️ Troubleshooting

### Issue: "Access token not provided"
**Solution**: Run `supabase login` first

### Issue: "Function already exists"
**Solution**: Function is already deployed, no action needed

### Issue: "Secret not found" error when testing
**Solution**: Add the secret to the function in Supabase Dashboard:
1. Go to Edge Functions → [Function Name]
2. Click Configuration
3. Add the secret from Supabase Settings → Secrets

### Issue: "CORS error" in browser console
**Solution**: The function already has CORS headers. Clear browser cache and retry.

### Issue: Email not sending
**Solution**:
1. Verify RESEND_API_KEY is correct in Supabase secrets
2. Check function logs: Edge Functions → send-email → Logs
3. Verify recipient email is valid

### Issue: OCR not processing image
**Solution**:
1. Verify OCR_API_KEY is correct in Supabase secrets
2. Ensure image is in valid format (JPEG, PNG, etc.)
3. Check function logs for detailed error

---

## 📊 Function Status Dashboard

After deployment, view your functions:

1. Go to **Supabase Dashboard**
2. Navigate to **Edge Functions**
3. You should see:
   - ✅ send-email (Active)
   - ✅ scan-receipt (Active)

Each function shows:
- Last deployment time
- Recent logs
- Configuration/Secrets
- Invocation count

---

## 🔄 Redeployment

If you update a function, redeploy it:

```bash
supabase functions deploy send-email
# or
supabase functions deploy scan-receipt
```

The new version will be live immediately.

---

## 📝 Next Steps

After deploying functions:

1. ✅ **Update Flutter App** - Already configured in `backend_api_proxy.dart`
2. ✅ **Add Secrets** - Done via Supabase Dashboard
3. ✅ **Run Tests** - `flutter test test/api_integration_tests.dart`
4. ✅ **Test Manual Flows**:
   - Send an invoice and verify email arrives
   - Upload a receipt and verify OCR extracts data
5. ✅ **Deploy to Production** - `flutter build web --release`

---

## 🎯 Quick Reference

| Component | Status | Location |
|-----------|--------|----------|
| send-email function | ✅ Created | `supabase/functions/send-email/` |
| scan-receipt function | ✅ Created | `supabase/functions/scan-receipt/` |
| Backend proxy | ✅ Ready | `lib/services/backend_api_proxy.dart` |
| Supabase secrets | ⏳ Pending | Supabase Dashboard → Settings → Secrets |
| Function secrets | ⏳ Pending | Supabase Dashboard → Edge Functions → [Function] → Configuration |

---

**Last Updated**: January 1, 2026  
**Functions Ready**: ✅ YES  
**Next Action**: Run `supabase login` and deploy functions
