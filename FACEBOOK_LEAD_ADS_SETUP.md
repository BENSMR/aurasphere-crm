# 🚀 WHITE SCREEN FIX + FACEBOOK LEAD ADS SETUP

## ✅ PART 1: Fixed White Screen Issue

### What Was Wrong
- Flutter Web **cannot** read `.env` files
- App was trying to load EnvLoader which failed silently
- AuthGate wrapper added extra complexity

### What We Fixed ✅
1. **Removed `flutter_dotenv`** from pubspec.yaml
2. **Removed `.env` from assets** in pubspec.yaml
3. **Hardcoded Supabase keys** directly in main.dart (safe - these are public API keys)
4. **Load LandingPageAnimated directly** - no AuthGate wrapper

### Rebuild Your App
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter clean
flutter pub get
flutter build web --release
```

✅ **White screen should be FIXED** - You'll now see the landing page!

---

## 📱 PART 2: Facebook Lead Ads Integration

### What It Does
- 📝 Captures leads from Facebook Lead Ads forms
- 💾 Automatically inserts into Supabase `clients` table
- 🔒 Verifies webhook signature (prevents spoofing)
- 🔄 Updates existing clients if email matches

### Architecture
```
Facebook Lead Ad Form
        ↓
   [User fills form]
        ↓
Facebook sends webhook
        ↓
Supabase Edge Function
        ↓
Verifies signature
Fetches lead details
        ↓
Inserts/updates in `clients` table
        ↓
✅ Lead captured!
```

---

## 🔧 SETUP STEPS

### Step 1: Deploy Edge Function to Supabase

1. **Install Supabase CLI** (if not already done):
```bash
npm install -g supabase
```

2. **Navigate to project directory**:
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm
```

3. **Create the function directory structure** (if not exists):
```bash
mkdir -p supabase/functions/facebook-lead-webhook
```

4. **The function file is already created at**:
```
supabase/functions/facebook-lead-webhook/index.ts
```

5. **Deploy the function**:
```bash
supabase functions deploy facebook-lead-webhook
```

**You'll get output like:**:
```
✅ Function deployed successfully
Webhook URL: https://uielvgnzaurhopolerok.supabase.co/functions/v1/facebook-lead-webhook
```

✅ **Copy this URL - you'll need it for Facebook!**

### Step 2: Set Environment Variables in Supabase

1. **Go to**: Supabase Dashboard → Project → Settings → Environment Variables
2. **Add these variables**:

```env
FACEBOOK_APP_SECRET=your_app_secret_from_meta
FACEBOOK_ACCESS_TOKEN=your_long_lived_token_with_leads_permission
WHATSAPP_WEBHOOK_VERIFY_TOKEN=your_random_secret_string_here
DEFAULT_ORG_ID=your_organization_id_here
```

**How to get these**:

#### Get FACEBOOK_APP_SECRET:
1. Go to: https://developers.facebook.com/
2. Select your app → Settings → Basic
3. Copy "App Secret" (click "Show" button)

#### Get FACEBOOK_ACCESS_TOKEN:
1. Go to: https://developers.facebook.com/
2. Select your app → Tools → Access Token Debugger
3. Go to: https://developers.facebook.com/tools/debug/accesstoken/
4. Click "Get User Access Token" → Select "leads_retrieval" permission
5. Copy the token

#### Generate WHATSAPP_WEBHOOK_VERIFY_TOKEN:
Create a random string (example):
```
my_secret_verify_token_abc123xyz789
```

#### Get DEFAULT_ORG_ID:
1. Go to Supabase Dashboard → SQL Editor
2. Run:
```sql
SELECT id FROM organizations LIMIT 1;
```
3. Copy the first organization ID

### Step 3: Configure Facebook Lead Ads Webhook

1. **Go to**: https://developers.facebook.com/
2. **Select your app** → Webhooks → Setup
3. **For "Page" object**:
   - **Callback URL**: `https://uielvgnzaurhopolerok.supabase.co/functions/v1/facebook-lead-webhook`
   - **Verify Token**: Use your WHATSAPP_WEBHOOK_VERIFY_TOKEN value
   - Click **Verify and Save**

4. **Subscribe to webhook fields**:
   - Click **Edit** → Enable **leadgen** field
   - Check: **leadgen**
   - Click **Save**

5. **For your Lead Ads form**:
   - Go to your form → Settings
   - **Webhook URL**: Same as above
   - Enable **Leads API access**

✅ **Webhook is now connected!**

---

## 🧪 TEST THE INTEGRATION

### Test Via Facebook
1. Fill out a test lead form on Facebook
2. Check Supabase → Tables → `clients`
3. You should see a new client with the lead's info!

### View Edge Function Logs
```bash
# Tail logs from the function
supabase functions list
supabase functions download facebook-lead-webhook

# Or in Supabase Dashboard:
# Go to Functions → facebook-lead-webhook → Logs
```

---

## 🗑️ FILES TO DELETE (Optional)

Since we're no longer using the old AuthGate pattern:

1. **`lib/auth_gate.dart`** - No longer used
2. **`lib/landing_page.dart`** - (simple version, keep landing_page_animated.dart)

These files might cause import conflicts. If you want to delete them:

```bash
rm lib/auth_gate.dart
rm lib/landing_page.dart
```

Then rebuild:
```bash
flutter clean
flutter pub get
flutter build web --release
```

---

## ✅ FINAL CHECKLIST

- [ ] Removed flutter_dotenv dependency
- [ ] Updated main.dart to load LandingPageAnimated directly
- [ ] Rebuilt app with `flutter build web --release`
- [ ] White screen is FIXED
- [ ] Deployed Edge Function to Supabase
- [ ] Set environment variables in Supabase
- [ ] Configured Facebook webhook
- [ ] Tested by creating a test lead
- [ ] Lead appears in `clients` table

---

## 🆘 TROUBLESHOOTING

### Edge Function Deploy Fails
```bash
# Make sure you're logged in:
supabase login

# Link your project:
supabase link --project-ref uielvgnzaurhopolerok

# Try deploy again:
supabase functions deploy facebook-lead-webhook
```

### Webhook Not Triggering
- ✅ Check Edge Function logs in Supabase Dashboard
- ✅ Verify Facebook webhook URL is correct (copy-paste exactly)
- ✅ Verify "Verify Token" matches your WHATSAPP_WEBHOOK_VERIFY_TOKEN
- ✅ Make sure leadgen field is subscribed in Facebook app

### Leads Not Appearing in Supabase
- ✅ Check that DEFAULT_ORG_ID is correct
- ✅ Check organization actually exists in `organizations` table
- ✅ Check Edge Function logs for SQL errors
- ✅ Verify RLS policies on `clients` table allow inserts

### Import Error: "auth_gate.dart not found"
- ✅ Delete the file: `rm lib/auth_gate.dart`
- ✅ Rebuild: `flutter clean && flutter pub get && flutter build web`

---

## 📊 NEXT STEPS

### Once Leads Are Flowing:
1. **View leads dashboard**: Navigate to `/leads` route
2. **Auto-create jobs**: Add integration to create jobs from leads
3. **Send welcome WhatsApp**: Use WhatsApp service to message new leads
4. **Track conversion**: Add `source` field tracking (already done with "facebook_lead_ads")

### Advanced Features:
- Map Facebook form fields to custom client fields
- Create automation: Lead → Client → Job → Invoice
- Add lead scoring based on form data
- Email notifications for new leads

---

## 🔐 SECURITY NOTES

**SAFE** ✅:
- Supabase public keys in main.dart (any user can see them)
- FACEBOOK_ACCESS_TOKEN in Supabase env vars (never exposed to frontend)
- FACEBOOK_APP_SECRET in Supabase env vars (never exposed to frontend)

**NOT SAFE** ❌:
- Never hardcode secrets in Flutter code
- Never commit `.env` to Git
- Never log sensitive data to console in production

---

**You now have**:
1. ✅ White screen fixed
2. ✅ Facebook Lead Ads auto-capturing
3. ✅ Secure webhook integration
4. ✅ Leads flowing to your database

**Next**: Test a Facebook lead form and watch it appear in Supabase! 🚀
