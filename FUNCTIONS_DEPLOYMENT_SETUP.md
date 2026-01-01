# 🚀 Complete Edge Functions Deployment Setup

## ⚠️ Authentication Required

To deploy Edge Functions, you must authenticate with Supabase CLI first.

---

## Step 1: Install Supabase CLI (if not already installed)

```bash
# Using npm
npm install -g supabase

# Or using Homebrew (Mac)
brew install supabase/tap/supabase

# Verify installation
supabase --version
```

---

## Step 2: Authenticate with Supabase

Run this command in your terminal:

```bash
supabase login
```

**This will**:
1. Open a browser window asking for authentication
2. Prompt you to verify your Supabase account
3. Generate an access token
4. Save it locally for future use

---

## Step 3: Link Your Project

Link your local project to your Supabase project:

```bash
cd C:\Users\PC\AuraSphere\crm\aura_crm

supabase link --project-ref fppmvibvpxrkwmymszhd
```

**When prompted**:
- **Database password**: Enter your Supabase database password (from Dashboard → Settings → Database)
- **It will download your project schema locally**

---

## Step 4: Deploy Edge Functions

### Deploy send-email Function

```bash
supabase functions deploy send-email
```

**Expected Output**:
```
✅ Function send-email deployed successfully
   Endpoint: https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/send-email
```

### Deploy scan-receipt Function

```bash
supabase functions deploy scan-receipt
```

**Expected Output**:
```
✅ Function scan-receipt deployed successfully
   Endpoint: https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/scan-receipt
```

### Verify Both Deployed

```bash
supabase functions list
```

**Expected Output**:
```
✅ send-email       Deployed
✅ scan-receipt     Deployed
```

---

## Step 5: Add Secrets to Functions

### Via Supabase Dashboard (Recommended)

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your **AuraSphere CRM** project
3. Go to **Edge Functions** in left sidebar

#### For send-email function:
1. Click on **send-email**
2. Click **Configuration** tab
3. Click **Add Secret**
   - **Name**: `RESEND_API_KEY`
   - **Value**: `re_[YOUR_NEW_RESEND_KEY_HERE]`
   - Click **Save**

#### For scan-receipt function:
1. Click on **scan-receipt**
2. Click **Configuration** tab
3. Click **Add Secret**
   - **Name**: `OCR_API_KEY`
   - **Value**: `[YOUR_NEW_OCR_KEY_HERE]`
   - Click **Save**

### Via CLI (Alternative)

```bash
# Set RESEND_API_KEY secret for send-email
supabase secrets set RESEND_API_KEY="re_your_resend_key_here" --project-ref fppmvibvpxrkwmymszhd

# Set OCR_API_KEY secret for scan-receipt
supabase secrets set OCR_API_KEY="your_ocr_key_here" --project-ref fppmvibvpxrkwmymszhd

# Verify secrets
supabase secrets list --project-ref fppmvibvpxrkwmymszhd
```

---

## Step 6: Test the Deployed Functions

### Test send-email

Open your browser and run:

```bash
curl -X POST https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/send-email \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "your-test-email@example.com",
    "subject": "Test Email from AuraSphere",
    "body": "<h1>Hello!</h1><p>Your Edge Function is working!</p>"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Email sent successfully",
  "emailId": "email_1234567890"
}
```

### Test scan-receipt

```bash
# Create a test with a sample image
curl -X POST https://fppmvibvpxrkwmymszhd.supabase.co/functions/v1/scan-receipt \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "imageUrl": "https://example.com/receipt.jpg"
  }'
```

---

## 📋 Full Deployment Checklist

```
EDGE FUNCTIONS DEPLOYMENT CHECKLIST
====================================

SETUP PHASE:
☐ Installed Supabase CLI (supabase --version)
☐ Authenticated with Supabase (supabase login)
☐ Linked project (supabase link --project-ref fppmvibvpxrkwmymszhd)

DEPLOYMENT PHASE:
☐ send-email function deployed (supabase functions deploy send-email)
☐ scan-receipt function deployed (supabase functions deploy scan-receipt)
☐ Both functions showing in list (supabase functions list)

SECRETS CONFIGURATION:
☐ RESEND_API_KEY added to send-email
☐ OCR_API_KEY added to scan-receipt
☐ Secrets verified (supabase secrets list)

TESTING PHASE:
☐ Test send-email function (curl request successful)
☐ Test scan-receipt function (curl request successful)
☐ Check function logs for errors
☐ Verify no API key leaks in logs

FLUTTER APP VERIFICATION:
☐ Build Flutter app (flutter build web --release)
☐ Test email sending from app
☐ Test receipt scanning from app
☐ Check browser DevTools for no API keys exposed

PRODUCTION DEPLOYMENT:
☐ Deploy build/web to hosting (Vercel/Netlify/Firebase)
☐ Test all features in production
☐ Monitor Edge Function logs for errors
☐ Set up error alerts

COMPLETION DATE: _______________
DEPLOYED BY: _______________
```

---

## 🔗 Quick Commands Reference

```bash
# Authentication
supabase login
supabase logout

# Project Management
supabase link --project-ref fppmvibvpxrkwmymszhd
supabase unlink

# Functions
supabase functions deploy send-email
supabase functions deploy scan-receipt
supabase functions list
supabase functions delete send-email
supabase functions logs send-email
supabase functions logs scan-receipt

# Secrets
supabase secrets set RESEND_API_KEY="value" --project-ref fppmvibvpxrkwmymszhd
supabase secrets list --project-ref fppmvibvpxrkwmymszhd
```

---

## ⚠️ Troubleshooting

### Issue: "Access token not provided"
**Solution**: 
```bash
supabase login
# Then try deploy again
```

### Issue: "Project not linked"
**Solution**:
```bash
supabase link --project-ref fppmvibvpxrkwmymszhd
```

### Issue: "Function already exists"
**Solution**: Normal - function is already deployed. To update:
```bash
supabase functions deploy send-email --force-rebuild
```

### Issue: "Secret not found" error when calling function
**Solution**:
1. Go to Supabase Dashboard → Edge Functions → [Function Name]
2. Click **Configuration**
3. Verify the secret is listed
4. Redeploy the function: `supabase functions deploy [name]`

### Issue: 401 Unauthorized when calling function
**Solution**: 
1. Verify your Anon Key is correct
2. Check function logs for detailed error
3. Verify secrets are set correctly

### Issue: Email not sending (function returns error)
**Solution**:
1. Verify RESEND_API_KEY is correct
2. Check function logs: `supabase functions logs send-email`
3. Verify recipient email is valid
4. Check Resend dashboard for account issues

### Issue: Can't authenticate (supabase login fails)
**Solution**:
1. Verify you have a Supabase account at https://app.supabase.com
2. Check internet connection
3. Try: `supabase login --no-prompt` and paste token manually
4. Get token from: Dashboard → Settings → Access Tokens

---

## 🎯 What Happens After Deployment

1. **Functions Live**: Your Edge Functions are now running on Supabase servers
2. **Secrets Secure**: API keys are securely stored (not in code)
3. **App Ready**: Flutter app can call functions without exposing keys
4. **Scalable**: Functions auto-scale based on demand
5. **Monitored**: You can view logs and metrics in dashboard

---

## 📞 Support

- **Supabase Documentation**: https://supabase.com/docs/guides/functions
- **CLI Reference**: https://supabase.com/docs/reference/cli
- **Troubleshooting**: https://supabase.com/docs/guides/functions/troubleshooting

---

**Last Updated**: January 1, 2026  
**Status**: Ready for deployment  
**Next Action**: Run `supabase login` to start
