# 🚀 Manual Deployment Steps - Run These Commands

## ✅ Supabase CLI is Installed
Version: 2.67.1 ✅

---

## Step 1: Authenticate (REQUIRED - Do This First)

**Run in PowerShell:**
```powershell
supabase login
```

**What happens:**
1. Browser opens automatically
2. Sign in to your Supabase account
3. Grant access to CLI
4. Auth token is saved locally

**After login, you should see:**
```
✅ Logged in to Supabase successfully
```

---

## Step 2: Link Your Project

**Run in PowerShell:**
```powershell
cd C:\Users\PC\AuraSphere\crm\aura_crm
supabase link --project-ref fppmvibvpxrkwmymszhd
```

**When prompted for "Database password":**
- Go to: https://app.supabase.com
- Select your AuraSphere CRM project
- Go to: Settings → Database → Password
- Copy and paste the password

**Expected output:**
```
✅ Linked to project [fppmvibvpxrkwmymszhd]
```

---

## Step 3: Deploy send-email Function

**Run in PowerShell:**
```powershell
cd C:\Users\PC\AuraSphere\crm\aura_crm
supabase functions deploy send-email
```

**Expected output:**
```
✅ Function send-email deployed successfully
   Endpoint: https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/send-email
```

---

## Step 4: Deploy scan-receipt Function

**Run in PowerShell:**
```powershell
supabase functions deploy scan-receipt
```

**Expected output:**
```
✅ Function scan-receipt deployed successfully
   Endpoint: https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/scan-receipt
```

---

## Step 5: Verify Both Deployed

**Run in PowerShell:**
```powershell
supabase functions list
```

**Expected output:**
```
✅ send-email       Deployed
✅ scan-receipt     Deployed
```

---

## Step 6: Add Secrets (Via Supabase Dashboard)

### For send-email:

1. Go to: https://app.supabase.com
2. Select **AuraSphere CRM** project
3. Go to: **Edge Functions** (left sidebar)
4. Click on: **send-email**
5. Click: **Configuration** tab
6. Click: **Add Secret**
   - **Name**: `RESEND_API_KEY`
   - **Value**: `re_[YOUR_NEW_RESEND_KEY]`
   - Click **Save**

### For scan-receipt:

1. Go to: **Edge Functions**
2. Click on: **scan-receipt**
3. Click: **Configuration** tab
4. Click: **Add Secret**
   - **Name**: `OCR_API_KEY`
   - **Value**: `[YOUR_NEW_OCR_KEY]`
   - Click **Save**

---

## Step 7: Test the Functions (Optional but Recommended)

### Test send-email in PowerShell:

```powershell
$headers = @{
    "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA"
    "Content-Type" = "application/json"
}

$body = @{
    "to" = "your-email@example.com"
    "subject" = "Test Email from AuraSphere"
    "body" = "<h1>Hello!</h1><p>Your Edge Function is working!</p>"
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/send-email" `
  -Method POST `
  -Headers $headers `
  -Body $body
```

**Expected response:**
```json
{
  "success": true,
  "message": "Email sent successfully",
  "emailId": "email_1234567890"
}
```

---

## 📋 Complete Checklist

Print this and check off as you go:

```
EDGE FUNCTIONS DEPLOYMENT CHECKLIST
====================================

STEP 1: Authentication
☐ Ran: supabase login
☐ Browser opened automatically
☐ Successfully authenticated
☐ Saw: "Logged in to Supabase successfully"

STEP 2: Link Project
☐ Ran: supabase link --project-ref fppmvibvpxrkwmymszhd
☐ Entered database password
☐ Saw: "Linked to project"

STEP 3: Deploy send-email
☐ Ran: supabase functions deploy send-email
☐ Saw: "Function send-email deployed successfully"

STEP 4: Deploy scan-receipt
☐ Ran: supabase functions deploy scan-receipt
☐ Saw: "Function scan-receipt deployed successfully"

STEP 5: Verify Deployment
☐ Ran: supabase functions list
☐ Saw both functions listed as "Deployed"

STEP 6: Add Secrets (Dashboard)
☐ Added RESEND_API_KEY to send-email
☐ Added OCR_API_KEY to scan-receipt
☐ Both secrets show green checkmark ✅

STEP 7: Test Functions (Optional)
☐ Tested send-email function
☐ Tested scan-receipt function
☐ Both returned success responses

DEPLOYMENT COMPLETE: YES ✅
```

---

## 🎯 Commands Summary (Copy & Paste)

```powershell
# 1. Login
supabase login

# 2. Link project
supabase link --project-ref fppmvibvpxrkwmymszhd

# 3. Deploy functions
supabase functions deploy send-email
supabase functions deploy scan-receipt

# 4. Verify
supabase functions list
```

---

## ⚠️ If You Get Errors

### Error: "Access token not provided"
**Solution**: 
```powershell
supabase login
# Then try again
```

### Error: "Project not linked"
**Solution**:
```powershell
supabase link --project-ref fppmvibvpxrkwmymszhd
```

### Error: "Function already exists"
**Solution**: This is normal - function is already deployed. To update it:
```powershell
supabase functions deploy send-email --force-rebuild
```

### Error: Function deployment fails
**Solution**: 
1. Check the error message in detail
2. Verify your project ref is correct: `fppmvibvpxrkwmymszhd`
3. Run: `supabase projects list` to see all projects

---

## ✅ What Happens After Deployment

1. **Functions Live**: Your Edge Functions run on Supabase servers
2. **Secrets Secure**: API keys stored safely (not in code)
3. **App Works**: Flutter app can call functions without exposing keys
4. **Auto-scaling**: Functions scale based on demand
5. **Monitoring**: View logs in Supabase Dashboard

---

## 📞 Next Steps After Deployment

1. ✅ Run automated tests:
   ```powershell
   flutter test test/security_unit_tests.dart
   ```

2. ✅ Manual testing with checklist:
   - See: SECURITY_TESTING_CHECKLIST.md

3. ✅ Deploy to production:
   ```powershell
   flutter build web --release
   # Then deploy build/web to hosting
   ```

---

**Last Updated**: January 1, 2026  
**Status**: Ready to deploy  
**Time Estimate**: 10-15 minutes for all steps
