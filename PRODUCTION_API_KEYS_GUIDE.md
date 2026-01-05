# 🔑 PRODUCTION API KEYS CONFIGURATION GUIDE

## **WHAT YOU NEED TO LAUNCH**

Your app needs API keys from these services. Here's what to do:

---

## ✅ **ALREADY CONFIGURED**

### **Supabase**
```env
SUPABASE_URL=https://fppmvibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
**Status**: ✅ Live and working  
**What it does**: Authentication, database, real-time updates

---

## ⚠️ **NEED TO CONFIGURE FOR PRODUCTION**

### **1. STRIPE PAYMENT** (Required for payments)

**Get Your Key:**
1. Go to https://dashboard.stripe.com
2. Login to your Stripe account
3. Navigate to: Developers → API Keys
4. Copy your **Publishable Key** (starts with `pk_live_`)

**Update in `.env`:**
```env
STRIPE_KEY=pk_live_YOUR_ACTUAL_STRIPE_KEY_HERE
```

**Test First:**
- Use test key: `pk_test_...` (doesn't charge real money)
- Switch to live key: `pk_live_...` (for production)

**Setup Webhooks:**
- In Stripe dashboard → Webhooks
- Add endpoint: `https://your-domain.com/api/stripe-webhook`
- Subscribe to: `invoice.payment_succeeded`, `customer.subscription.updated`

---

### **2. WHATSAPP** (Optional but recommended)

**Get Your Credentials:**
1. Go to https://www.twilio.com (or https://www.facebook.com/business)
2. Set up WhatsApp Business Account
3. Get: `ACCOUNT_SID`, `AUTH_TOKEN`, `PHONE_ID`

**Update in `.env`:**
```env
WHATSAPP_BUSINESS_ACCOUNT_ID=your_account_id
WHATSAPP_BUSINESS_PHONE_ID=your_phone_id
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
```

**Test:**
- Send test message via app
- Verify delivery in WhatsApp Business account

---

### **3. EMAIL SERVICE - RESEND** (Required for emails)

**Get Your Key:**
1. Go to https://resend.com
2. Create free account
3. Get API Key from dashboard
4. Copy your **API Key**

**Update in `.env`:**
```env
RESEND_API_KEY=re_YOUR_RESEND_API_KEY_HERE
```

**Setup:**
- Verify sender email domain (or use default)
- Test sending invoice email

---

### **4. GROQ AI** (For AI chat feature)

**Get Your Key:**
1. Go to https://console.groq.com
2. Sign up (free tier available)
3. Create API Key
4. Copy your **API Key**

**Update in `.env`:**
```env
GROQ_API_KEY=gsk_YOUR_GROQ_API_KEY_HERE
```

**What it does:** Powers the AI chat assistant (natural language commands)

---

### **5. OCR SERVICE** (For receipt scanning)

**Option A: Free OCR Space**
```env
OCR_API_KEY=ocr_space_free_tier_api_key
```
(Free tier available, ~25 requests/day)

**Option B: Paid OCR Provider**
1. Go to https://api.ocr.space
2. Get paid API key for higher limits
3. Update `.env`

---

### **6. GOOGLE ANALYTICS** (Optional, for tracking)

**Get Your ID:**
1. Go to https://analytics.google.com
2. Create new property for your domain
3. Get your **Measurement ID** (G-XXXXXXXXXX)

**Add to index.html:**
```html
<!-- Add to <head> -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

---

## 📋 **COMPLETE .ENV TEMPLATE FOR PRODUCTION**

```env
# ===== SUPABASE (Already working) =====
SUPABASE_URL=https://fppmvibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA

# ===== STRIPE PAYMENT (REQUIRED) =====
STRIPE_KEY=pk_live_51234567890abcdefghijklmnop

# ===== EMAIL SERVICE - RESEND (REQUIRED) =====
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxx

# ===== WHATSAPP (Optional but recommended) =====
WHATSAPP_BUSINESS_ACCOUNT_ID=your_whatsapp_account_id
WHATSAPP_BUSINESS_PHONE_ID=your_whatsapp_phone_id
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_twilio_auth_token

# ===== GROQ AI (For AI Chat) =====
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxxxxx

# ===== OCR (For Receipt Scanning) =====
OCR_API_KEY=ocr_space_api_key_or_paid_provider_key

# ===== OPTIONAL: Paddle Payment =====
PADDLE_VENDOR_ID=your_paddle_vendor_id
PADDLE_API_KEY=your_paddle_api_key
```

---

## 🚀 **HOW TO USE THESE KEYS**

### **Option 1: Local Development**
```bash
# Create .env file in project root with test keys
# Keys are automatically loaded by EnvLoader.dart
```

### **Option 2: Firebase Hosting**
1. Go to Firebase Console
2. Project Settings → Environment Variables
3. Add each key
4. Deploy

### **Option 3: Vercel**
1. Go to Vercel Dashboard
2. Project Settings → Environment Variables
3. Add each key
4. Redeploy

### **Option 4: Netlify**
1. Go to Netlify Site Settings
2. Build & Deploy → Environment
3. Add each key
4. Redeploy

---

## ⚠️ **SECURITY BEST PRACTICES**

### **DO**
✅ Use production keys only in production  
✅ Use test keys in development/staging  
✅ Store keys in environment variables, NOT in code  
✅ Rotate keys periodically  
✅ Use separate accounts for dev/prod  
✅ Restrict API key permissions to minimum needed  

### **DON'T**
❌ Commit `.env` file with real keys to GitHub  
❌ Hardcode keys in Dart/JavaScript  
❌ Share keys via email/Slack  
❌ Use same keys for dev and production  
❌ Leave keys exposed in browser DevTools  

---

## 🔄 **KEY ROTATION CHECKLIST**

Every 3 months (or if key is compromised):

1. **Stripe**: 
   - Create new API key
   - Update in production
   - Delete old key
   - Update webhooks if needed

2. **Resend**:
   - Create new API key
   - Update deployment
   - Delete old key

3. **Groq**:
   - Create new API key
   - Update in deployment
   - Delete old key

4. **WhatsApp**:
   - Regenerate auth token
   - Update in all deployments
   - Verify messaging still works

---

## 🧪 **TEST EACH KEY AFTER SETUP**

### **Stripe**
```
Create test invoice → Should process payment
```

### **Resend**
```
Send test email → Check inbox
```

### **Groq**
```
Use AI chat → Ask natural language question
Should get response
```

### **WhatsApp**
```
Send test message → Receive on WhatsApp Business account
```

### **OCR**
```
Upload receipt photo → Should extract text
```

---

## 📞 **HELP WITH GETTING KEYS**

| Service | Website | Docs | Free Tier |
|---------|---------|------|-----------|
| Stripe | stripe.com | https://stripe.com/docs | Yes ($0 until first charge) |
| Resend | resend.com | https://resend.com/docs | Yes (100/day) |
| Groq | groq.com | https://groq.com/docs | Yes (generous free tier) |
| Twilio | twilio.com | https://twilio.com/docs | Yes ($15 credit) |
| OCR Space | ocr.space | https://ocr.space/ocrapi | Yes (25 req/day) |

---

## ✅ **LAUNCH CHECKLIST**

- [ ] Have Stripe live key (pk_live_...)
- [ ] Have Resend API key
- [ ] Have Groq API key (optional but recommended)
- [ ] Have WhatsApp credentials (optional)
- [ ] Updated .env with production keys
- [ ] Don't commit .env to Git
- [ ] Test each key works
- [ ] Deploy to production
- [ ] Verify features work in production
- [ ] Set up monitoring/alerts

---

**Once all keys are configured, you're ready to launch!**

Next step: [QUICK_LAUNCH_GUIDE.md](QUICK_LAUNCH_GUIDE.md)
