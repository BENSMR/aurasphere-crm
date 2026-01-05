# 🚀 AuraSphere CRM - Complete Deployment & Configuration Guide

**Status**: Pre-Launch Configuration  
**Date**: January 4, 2026  
**Target**: Launch Ready in < 24 hours

---

## 1️⃣ PAYMENT PROCESSING SETUP

### A. STRIPE INTEGRATION (Primary)

#### Step 1: Create Stripe Account
```bash
1. Go to https://stripe.com
2. Sign up for business account
3. Verify identity and bank details
4. Complete onboarding
```

#### Step 2: Get API Keys
```
Dashboard → Developers → API Keys
- Publishable Key: pk_live_XXXXXXXXXXXXXXXX
- Secret Key: sk_live_XXXXXXXXXXXXXXXX
```

#### Step 3: Update `.env` file
```env
# STRIPE CONFIGURATION
STRIPE_PUBLISHABLE_KEY=pk_live_XXXXXXXXXXXXXXXX
STRIPE_SECRET_KEY=sk_live_XXXXXXXXXXXXXXXX
STRIPE_WEBHOOK_SECRET=whsec_XXXXXXXXXXXXXXXX
```

#### Step 4: Set up Products in Stripe
```
Dashboard → Products
Create 3 products:

1. Solo Plan ($9.99/month)
   - Product ID: prod_solo_XXXXX
   - Price ID: price_solo_XXXXX
   - Recurring: Monthly

2. Team Plan ($15.00/month)
   - Product ID: prod_team_XXXXX
   - Price ID: price_team_XXXXX
   - Recurring: Monthly

3. Workshop Plan ($29.00/month)
   - Product ID: prod_workshop_XXXXX
   - Price ID: price_workshop_XXXXX
   - Recurring: Monthly
```

#### Step 5: Configure Webhook
```
Dashboard → Webhooks
- Endpoint: https://yourdomain.com/api/webhooks/stripe
- Events to listen for:
  • payment_intent.succeeded
  • customer.subscription.created
  • customer.subscription.updated
  • customer.subscription.deleted
  • charge.failed
```

#### Step 6: Backend Endpoint (Node.js/Dart)
```dart
// lib/services/stripe_service.dart
import 'package:http/http.dart' as http;

class StripeService {
  static const String stripeSecretKey = String.fromEnvironment('STRIPE_SECRET_KEY');
  static const String stripePubKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  
  // Create subscription
  static Future<String> createSubscription({
    required String customerId,
    required String priceId,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/subscriptions'),
      headers: {
        'Authorization': 'Bearer $stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'customer': customerId,
        'items[0][price]': priceId,
      },
    );
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to create subscription: ${response.body}');
    }
  }
  
  // Cancel subscription
  static Future<void> cancelSubscription(String subscriptionId) async {
    final response = await http.delete(
      Uri.parse('https://api.stripe.com/v1/subscriptions/$subscriptionId'),
      headers: {
        'Authorization': 'Bearer $stripeSecretKey',
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel subscription');
    }
  }
}
```

---

### B. PADDLE INTEGRATION (Alternative)

#### Step 1: Create Paddle Account
```bash
1. Go to https://www.paddle.com
2. Sign up for business account
3. Verify identity
4. Complete setup
```

#### Step 2: Get API Credentials
```
Settings → API Keys
- Seller ID: XXXXXX
- API Key: xxxxxxxxxxxxx
- Public Key: pk_live_XXXXXXXXXXXXXXXX
```

#### Step 3: Update `.env`
```env
# PADDLE CONFIGURATION
PADDLE_SELLER_ID=XXXXXX
PADDLE_API_KEY=xxxxxxxxxxxxx
PADDLE_PUBLIC_KEY=pk_live_XXXXXXXXXXXXXXXX
```

#### Step 4: Configure Products in Paddle
```
Products → Create Product
- Solo: Price ID: xxxxxx
- Team: Price ID: xxxxxx
- Workshop: Price ID: xxxxxx
```

#### Step 5: Webhook Setup
```
Developer → Webhooks
- Endpoint: https://yourdomain.com/api/webhooks/paddle
- Events:
  • subscription.created
  • subscription.updated
  • subscription.cancelled
  • transaction.completed
  • transaction.failed
```

---

### C. LEMON SQUEEZY (Budget Alternative)

#### Step 1: Create Account
```bash
Go to https://www.lemonsqueezy.com
Sign up and verify email
```

#### Step 2: Get API Key
```
Settings → API → Create Token
```

#### Step 3: Update `.env`
```env
LEMONSQUEEZY_API_KEY=xxxxxxxxxxxxx
LEMONSQUEEZY_STORE_ID=XXXXXX
```

---

## 2️⃣ EMAIL SERVICE SETUP (Resend)

### Resend Configuration

#### Step 1: API Key (Already Registered)
```
Dashboard → API Keys
Your API Key: re_XXXXXXXXXXXXXXXX
```

#### Step 2: Update `.env`
```env
RESEND_API_KEY=re_XXXXXXXXXXXXXXXX
RESEND_FROM_EMAIL=noreply@yourdomain.com
RESEND_FROM_NAME=AuraSphere CRM
```

#### Step 3: Verify Domain
```
Settings → Domains
1. Add yourdomain.com
2. Add DNS records:
   - TXT record for verification
   - DKIM records
   - SPF records
3. Verify domain
```

#### Step 4: Email Templates

**File**: `lib/services/email_service.dart`
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  static const String resendApiKey = String.fromEnvironment('RESEND_API_KEY');
  static const String fromEmail = String.fromEnvironment('RESEND_FROM_EMAIL');
  
  // Welcome Email
  static Future<void> sendWelcomeEmail({
    required String userEmail,
    required String userName,
    required String planName,
  }) async {
    final htmlContent = '''
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h1>Welcome to AuraSphere CRM, $userName!</h1>
        <p>Your $planName plan is now active.</p>
        <p>Get started by:</p>
        <ul>
          <li>Adding your first client</li>
          <li>Creating your first job</li>
          <li>Inviting team members (if applicable)</li>
        </ul>
        <p><a href="https://yourdomain.com/dashboard">Go to Dashboard</a></p>
      </body>
    </html>
    ''';
    
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': fromEmail,
        'to': userEmail,
        'subject': 'Welcome to AuraSphere CRM',
        'html': htmlContent,
      }),
    );
    
    if (response.statusCode != 200) {
      print('Email send failed: ${response.body}');
      throw Exception('Failed to send email');
    }
  }
  
  // Invoice Email
  static Future<void> sendInvoiceEmail({
    required String clientEmail,
    required String invoiceNumber,
    required double amount,
    required String pdfUrl,
  }) async {
    final htmlContent = '''
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>Invoice #$invoiceNumber</h2>
        <p>Amount Due: \$$amount</p>
        <p><a href="$pdfUrl">Download Invoice</a></p>
      </body>
    </html>
    ''';
    
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': fromEmail,
        'to': clientEmail,
        'subject': 'Invoice #$invoiceNumber',
        'html': htmlContent,
        'attachments': [
          {
            'filename': 'invoice_$invoiceNumber.pdf',
            'path': pdfUrl,
          }
        ],
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to send invoice email');
    }
  }
  
  // Subscription Confirmation
  static Future<void> sendSubscriptionConfirmation({
    required String userEmail,
    required String planName,
    required double amount,
  }) async {
    final htmlContent = '''
    <html>
      <body style="font-family: Arial, sans-serif;">
        <h2>Subscription Confirmed</h2>
        <p>Plan: $planName</p>
        <p>Amount: \$$amount/month</p>
        <p>Your subscription is active and will renew monthly.</p>
      </body>
    </html>
    ''';
    
    await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': fromEmail,
        'to': userEmail,
        'subject': 'Your $planName Subscription is Active',
        'html': htmlContent,
      }),
    );
  }
}
```

---

## 3️⃣ ERROR LOGGING (Sentry)

### Sentry Setup

#### Step 1: Create Account
```bash
Go to https://sentry.io
Sign up with email
Create new project → Dart/Flutter
```

#### Step 2: Get DSN
```
Project Settings → Client Keys (DSN)
DSN: https://xxxxxxxxxxxxx@xxxxx.ingest.sentry.io/xxxxxx
```

#### Step 3: Update `.env`
```env
SENTRY_DSN=https://xxxxxxxxxxxxx@xxxxx.ingest.sentry.io/xxxxxx
SENTRY_ENABLED=true
```

#### Step 4: Add to Flutter Dependencies
```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0
```

#### Step 5: Initialize in Main
```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.enableAutoSessionTracking = true;
    },
    appRunner: () => runApp(const MyApp()),
  );
}

// Capture exceptions
try {
  // Code
} catch (exception, stackTrace) {
  await Sentry.captureException(
    exception,
    stackTrace: stackTrace,
  );
}
```

---

## 4️⃣ ANALYTICS SETUP (Google Analytics / Mixpanel)

### Google Analytics 4

#### Step 1: Create GA4 Property
```
Google Analytics → Create Account
- Account: AuraSphere
- Property: AuraSphere CRM
- Data Stream: Web (yourdomain.com)
```

#### Step 2: Get Measurement ID
```
Property Settings → Data Streams → Web
Measurement ID: G-XXXXXXXXXX
```

#### Step 3: Add to Flutter
```yaml
# pubspec.yaml
dependencies:
  google_analytics_flutter: ^1.0.0
```

#### Step 4: Initialize
```dart
// lib/services/analytics_service.dart
import 'package:google_analytics_flutter/google_analytics.dart';

class AnalyticsService {
  static final GoogleAnalytics _analytics = GoogleAnalytics();
  
  static Future<void> initialize() async {
    await _analytics.initialize(
      measurementId: 'G-XXXXXXXXXX',
      apiSecret: 'your_api_secret',
    );
  }
  
  // Track page view
  static void trackPageView(String pageName) {
    _analytics.event(
      name: 'page_view',
      parameters: {
        'page_title': pageName,
      },
    );
  }
  
  // Track subscription event
  static void trackSubscription(String planName, double amount) {
    _analytics.event(
      name: 'purchase',
      parameters: {
        'value': amount,
        'currency': 'USD',
        'items': [
          {
            'item_name': planName,
            'price': amount,
          }
        ],
      },
    );
  }
  
  // Track feature usage
  static void trackFeatureUsage(String feature) {
    _analytics.event(
      name: 'feature_used',
      parameters: {
        'feature_name': feature,
      },
    );
  }
}
```

---

## 5️⃣ MOBILE/TABLET DOWNLOAD LIMITS PER PLAN

### Implementation

**File**: `lib/services/plan_limits_service.dart`
```dart
class PlanLimitsService {
  static const Map<String, PlanLimits> planLimits = {
    'solo': PlanLimits(
      name: 'Solo',
      maxUsers: 1,
      aiCallsPerMonth: 500,
      mobileDownloadsPerMonth: 2,
      tabletDownloadsPerMonth: 1,
      dataStorageGB: 5,
    ),
    'team': PlanLimits(
      name: 'Team',
      maxUsers: 3,
      aiCallsPerMonth: 1000,
      mobileDownloadsPerMonth: 5,
      tabletDownloadsPerMonth: 3,
      dataStorageGB: 25,
    ),
    'workshop': PlanLimits(
      name: 'Workshop',
      maxUsers: 7,
      aiCallsPerMonth: 1500,
      mobileDownloadsPerMonth: 15,
      tabletDownloadsPerMonth: 10,
      dataStorageGB: 100,
    ),
  };
  
  static Future<bool> canDownloadApp(String planId, String deviceType) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    
    final plan = planLimits[planId];
    if (plan == null) return false;
    
    // Get current month downloads
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    
    final response = await supabase
        .from('app_downloads')
        .select('id')
        .eq('user_id', userId)
        .eq('device_type', deviceType)
        .gte('created_at', firstDay.toIso8601String());
    
    final downloads = response.length ?? 0;
    final limit = deviceType == 'mobile'
        ? plan.mobileDownloadsPerMonth
        : plan.tabletDownloadsPerMonth;
    
    return downloads < limit;
  }
  
  static Future<void> recordDownload(String planId, String deviceType) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    
    await supabase.from('app_downloads').insert({
      'user_id': userId,
      'plan_id': planId,
      'device_type': deviceType,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

class PlanLimits {
  final String name;
  final int maxUsers;
  final int aiCallsPerMonth;
  final int mobileDownloadsPerMonth;
  final int tabletDownloadsPerMonth;
  final int dataStorageGB;
  
  const PlanLimits({
    required this.name,
    required this.maxUsers,
    required this.aiCallsPerMonth,
    required this.mobileDownloadsPerMonth,
    required this.tabletDownloadsPerMonth,
    required this.dataStorageGB,
  });
}
```

### Database Migration
```sql
-- Create app_downloads table
CREATE TABLE app_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id VARCHAR NOT NULL,
  device_type VARCHAR NOT NULL, -- 'mobile', 'tablet', 'desktop'
  app_version VARCHAR NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_app_downloads_user_month 
ON app_downloads(user_id, DATE_TRUNC('month', created_at), device_type);
```

---

## 6️⃣ PWA & DEPLOYMENT SETUP

### A. PWA Configuration

**File**: `web/manifest.json`
```json
{
  "name": "AuraSphere CRM",
  "short_name": "AuraSphere",
  "description": "Complete CRM for tradespeople",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#007BFF",
  "scope": "/",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "screenshots": [
    {
      "src": "icons/screenshot-1.png",
      "sizes": "540x720",
      "type": "image/png",
      "form_factor": "narrow"
    }
  ],
  "shortcuts": [
    {
      "name": "Dashboard",
      "short_name": "Dashboard",
      "description": "View your dashboard",
      "url": "/dashboard?mode=dashboard",
      "icons": [
        {
          "src": "icons/icon-dashboard.png",
          "sizes": "192x192"
        }
      ]
    }
  ]
}
```

**File**: `web/index.html`
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Complete CRM for tradespeople">
  <meta name="theme-color" content="#007BFF">
  
  <link rel="manifest" href="manifest.json">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  
  <title>AuraSphere CRM</title>
</head>
<body>
  <noscript>
    <p>Enable JavaScript to run AuraSphere CRM</p>
  </noscript>
  
  <script src="flutter_bootstrap.js" async></script>
  
  <!-- Service Worker -->
  <script>
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', function() {
        navigator.serviceWorker.register('flutter_service_worker.js');
      });
    }
  </script>
</body>
</html>
```

---

### B. Vercel Deployment

**File**: `vercel.json`
```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "env": {
    "SUPABASE_URL": "@supabase_url",
    "SUPABASE_ANON_KEY": "@supabase_anon_key",
    "STRIPE_PUBLISHABLE_KEY": "@stripe_publishable_key",
    "RESEND_API_KEY": "@resend_api_key",
    "SENTRY_DSN": "@sentry_dsn"
  },
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=3600, s-maxage=3600"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        }
      ]
    },
    {
      "source": "/assets/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

**Deployment Command**:
```bash
npm i -g vercel
vercel login
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter build web --release
vercel --prod
```

### C. Netlify Deployment

**File**: `netlify.toml`
```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/*"
  [headers.values]
    X-Content-Type-Options = "nosniff"
    X-Frame-Options = "DENY"
    Cache-Control = "public, max-age=3600"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[context.production.environment]
  SUPABASE_URL = ""
  SUPABASE_ANON_KEY = ""
  STRIPE_PUBLISHABLE_KEY = ""
  RESEND_API_KEY = ""
  SENTRY_DSN = ""
```

**Deployment Command**:
```bash
npm i -g netlify-cli
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter build web --release
netlify deploy --prod --dir=build/web
```

---

### D. Firebase Hosting

**File**: `firebase.json`
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=3600"
          }
        ]
      },
      {
        "source": "/assets/**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
```

**Deployment Command**:
```bash
npm i -g firebase-tools
firebase login
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter build web --release
firebase deploy --only hosting
```

---

## 7️⃣ DOMAIN & SSL SETUP

### Step 1: Domain Registration
```
Provider options:
- Namecheap
- GoDaddy
- Google Domains
- Cloudflare

Buy: yourdomain.com
```

### Step 2: DNS Configuration
```
Vercel/Netlify/Firebase auto-manages SSL
Just point DNS to their nameservers:

Vercel:
  NS Records → vercel's nameservers

Netlify:
  NS Records → netlify's nameservers

Firebase:
  A Records → 199.36.158.100
  A Records → 199.36.159.100
```

### Step 3: SSL Certificate (Auto)
```
All major hosts auto-issue Let's Encrypt SSL
- Automatic renewal
- No extra config needed
```

---

## 8️⃣ MOBILE BUILD CONFIGURATION

### iOS Build
```bash
# Update version
open ios/Runner.xcworkspace

# In Xcode:
# 1. General → Version (1.0.0) and Build (1)
# 2. Signing → Team ID
# 3. Capabilities → Push Notifications (if needed)

# Build
flutter build ios --release

# Upload to App Store
# Use Transporter app
```

### Android Build
```bash
# Create keystore
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create android/key.properties
storePassword=xxxxx
keyPassword=xxxxx
keyAlias=upload
storeFile=upload-keystore.jks

# Build
flutter build appbundle --release

# Upload to Google Play Console
# Via Play Console web interface
```

---

## 9️⃣ ENVIRONMENT VARIABLES (.env)

**File**: `.env.production`
```env
# SUPABASE
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=xxxxxxxxxxxxx

# PAYMENT
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxx
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
PADDLE_SELLER_ID=xxxxx
PADDLE_API_KEY=xxxxxxxxxxxxx

# EMAIL
RESEND_API_KEY=re_xxxxxxxxxxxxx
RESEND_FROM_EMAIL=noreply@yourdomain.com

# ERROR LOGGING
SENTRY_DSN=https://xxxxx@xxxxx.ingest.sentry.io/xxxxxx
SENTRY_ENABLED=true

# ANALYTICS
GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
MIXPANEL_TOKEN=xxxxxxxxxxxxx

# AI
GROQ_API_KEY=gsk_xxxxxxxxxxxxx

# DOMAIN
DOMAIN=https://yourdomain.com
```

---

## 🔟 PRE-LAUNCH CHECKLIST

### Payment Processing ✅
- [ ] Stripe account created & configured
- [ ] Stripe API keys in `.env`
- [ ] Stripe products created (3 plans)
- [ ] Stripe webhook configured
- [ ] Paddle account created (optional)
- [ ] Payment flow tested with test cards

### Email Service ✅
- [ ] Resend API key in `.env`
- [ ] Domain verified in Resend
- [ ] Welcome email template tested
- [ ] Invoice email template tested
- [ ] Subscription confirmation email tested

### Error Logging ✅
- [ ] Sentry project created
- [ ] DSN in `.env`
- [ ] Sentry Flutter SDK added
- [ ] Test error captured

### Analytics ✅
- [ ] Google Analytics 4 configured
- [ ] Measurement ID in code
- [ ] Page tracking verified
- [ ] Event tracking verified

### Mobile Limits ✅
- [ ] Database table created (app_downloads)
- [ ] Download limit service implemented
- [ ] RLS policies configured

### Domain & SSL ✅
- [ ] Domain registered
- [ ] DNS pointing to hosting provider
- [ ] SSL certificate auto-issued
- [ ] HTTPS accessible

### Deployment ✅
- [ ] PWA manifest configured
- [ ] Service worker ready
- [ ] Build web release successful
- [ ] Vercel/Netlify account created
- [ ] Environment variables set in hosting
- [ ] First deployment successful

### Testing ✅
- [ ] Sign up flow works
- [ ] Payment flow works (test mode)
- [ ] Email sent successfully
- [ ] Analytics tracking
- [ ] Error logging working
- [ ] Mobile-responsive verified

---

## 🎯 DEPLOYMENT QUICK START

### 1. Build Web
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter clean
flutter pub get
flutter build web --release
```

### 2. Deploy to Vercel (< 1 hour)
```bash
npm i -g vercel
vercel login
# Follow prompts
vercel --prod
```

### 3. Configure Environment Variables
```
Vercel Dashboard → Project Settings → Environment Variables
Add all from .env.production
```

### 4. Test Live
```
https://yourdomain.vercel.app
or
https://yourdomain.com (after DNS)
```

---

## ⚠️ CRITICAL BEFORE LAUNCH

1. ✅ Test payment with real Stripe test cards
2. ✅ Verify emails are sent
3. ✅ Test signup → payment → email flow
4. ✅ Verify error logging captures errors
5. ✅ Verify analytics tracking
6. ✅ Test on mobile devices
7. ✅ Verify PWA installable
8. ✅ Check SSL certificate valid
9. ✅ Check all 29 pages load
10. ✅ Check database migrations applied

---

## 📊 LAUNCH TIMELINE

| Task | Duration | Status |
|------|----------|--------|
| Payment setup | 30 min | ⏳ Ready |
| Email service | 15 min | ✅ Ready |
| Error logging | 15 min | ⏳ Ready |
| Analytics | 15 min | ⏳ Ready |
| Mobile limits | 20 min | ✅ Ready |
| PWA config | 10 min | ✅ Ready |
| Domain setup | 24-48 hrs | ⏳ Parallel |
| Build & deploy | 30 min | ✅ Ready |
| Testing | 30 min | ⏳ Ready |
| **TOTAL** | **~4-48 hours** | ✅ **GO LIVE** |

---

**Status**: Ready for Launch ✅  
**Last Updated**: January 4, 2026  
**Next Step**: Execute deployment commands above
