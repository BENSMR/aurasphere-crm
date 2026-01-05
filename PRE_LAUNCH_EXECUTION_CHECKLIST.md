# 🚀 AuraSphere CRM - PRE-LAUNCH EXECUTION CHECKLIST

**Status**: Ready for Launch  
**Target Launch Date**: January 5, 2026 (< 24 hours)  
**Critical Path Duration**: 4-6 hours execution + 24-48 hours domain propagation

---

## PHASE 1: PAYMENT SETUP (30 minutes) ✅

### Stripe Configuration
- [ ] Create Stripe account at https://stripe.com
- [ ] Complete identity verification
- [ ] Navigate to Developers → API Keys
- [ ] Copy Publishable Key: `pk_live_XXXXXXXXXXXXXXXX`
- [ ] Copy Secret Key: `sk_live_XXXXXXXXXXXXXXXX`
- [ ] Create 3 Products in Products section:
  - [ ] Solo Plan ($9.99/month) → Get Price ID: `price_XXXXXXXX`
  - [ ] Team Plan ($15.00/month) → Get Price ID: `price_XXXXXXXX`
  - [ ] Workshop Plan ($29.00/month) → Get Price ID: `price_XXXXXXXX`
- [ ] Create Webhook:
  - [ ] Endpoint: `https://yourdomain.com/api/webhooks/stripe`
  - [ ] Events: `payment_intent.succeeded`, `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`
  - [ ] Copy Webhook Secret: `whsec_XXXXXXXXXXXXXXXX`

### Update `.env` File
```env
# .env.production
STRIPE_PUBLISHABLE_KEY=pk_live_XXXXXXXXXXXXXXXX
STRIPE_SECRET_KEY=sk_live_XXXXXXXXXXXXXXXX
STRIPE_WEBHOOK_SECRET=whsec_XXXXXXXXXXXXXXXX
```

### Test Stripe Integration
- [ ] Use test card: `4242 4242 4242 4242` (expiry: any future date)
- [ ] Test subscription creation
- [ ] Test webhook receipt
- [ ] Verify payment in Stripe dashboard

**Estimated Time**: 30 min

---

## PHASE 2: EMAIL SERVICE SETUP (15 minutes) ✅

### Resend Configuration
- [ ] Go to https://resend.com/dashboard
- [ ] Copy API Key: `re_XXXXXXXXXXXXXXXX` (already registered)
- [ ] Settings → Domains
- [ ] Add Domain: `yourdomain.com`
- [ ] Add DNS records (TXT, DKIM, SPF):
  ```
  TXT: resend-verification=xxxxx
  DKIM: k1._domainkey.yourdomain.com CNAME xxxxx.resend.dev
  SPF: v=spf1 include:resend.com ~all
  ```
- [ ] Wait for DNS propagation (5-30 min)
- [ ] Verify domain in Resend dashboard

### Update `.env`
```env
RESEND_API_KEY=re_XXXXXXXXXXXXXXXX
RESEND_FROM_EMAIL=noreply@yourdomain.com
```

### Test Email Service
- [ ] Send test welcome email
- [ ] Check inbox (may be in spam)
- [ ] Verify domain validation emails sent

**Estimated Time**: 15 min

---

## PHASE 3: ERROR LOGGING SETUP (15 minutes) ✅

### Sentry Configuration
- [ ] Go to https://sentry.io
- [ ] Create account or login
- [ ] Create new project → Select "Dart"
- [ ] Copy DSN: `https://xxxxxxxxxxxxx@xxxxx.ingest.sentry.io/xxxxxx`
- [ ] Go to Settings → Project
- [ ] Configure alerts (optional)

### Update `.env`
```env
SENTRY_DSN=https://xxxxxxxxxxxxx@xxxxx.ingest.sentry.io/xxxxxx
SENTRY_ENABLED=true
```

### Verify Installation
- [ ] Check `pubspec.yaml` has `sentry_flutter: ^7.0.0`
- [ ] Verify initialization in `main.dart`
- [ ] Test error capture

**Estimated Time**: 15 min

---

## PHASE 4: ANALYTICS SETUP (15 minutes) ✅

### Google Analytics 4
- [ ] Go to https://analytics.google.com
- [ ] Create new property: "AuraSphere CRM"
- [ ] Web stream: `yourdomain.com`
- [ ] Copy Measurement ID: `G-XXXXXXXXXX`

### Update Code
- [ ] Add to `lib/services/analytics_service.dart`
- [ ] Initialize on app start
- [ ] Verify tracking (check GA dashboard after 24 hours)

**Estimated Time**: 15 min

---

## PHASE 5: MOBILE & DOWNLOAD LIMITS (30 minutes) ✅

### Database Setup
- [ ] Run Supabase migration: Create `app_downloads` table
- [ ] Enable RLS policies
- [ ] Test insert/select

### Code Implementation
- [ ] Add `lib/services/plan_limits_service.dart`
- [ ] Implement download limit checks
- [ ] Test with different plan IDs

### iOS Build
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Update version: 1.0.0, Build: 1
- [ ] Set Team ID for signing
- [ ] Run: `flutter build ios --release`

### Android Build
- [ ] Create keystore: `keytool -genkey -v -keystore ~/upload-keystore.jks`
- [ ] Create `android/key.properties` with keystore details
- [ ] Run: `flutter build appbundle --release`

**Estimated Time**: 30 min

---

## PHASE 6: PWA & DOMAIN SETUP (24-48 hours, start now)

### Domain Registration
- [ ] Register domain at Namecheap/GoDaddy/Google Domains
- [ ] **NOTE**: DNS changes can take 24-48 hours, start this FIRST
- [ ] DNS Nameserver Configuration:
  - [ ] If using Vercel: Point to Vercel nameservers
  - [ ] If using Netlify: Point to Netlify nameservers
  - [ ] If using Firebase: Point A records to `199.36.158.100` & `199.36.159.100`

### PWA Configuration
- [ ] Verify `web/manifest.json` configured correctly
- [ ] Verify `web/index.html` has:
  ```html
  <link rel="manifest" href="manifest.json">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  ```
- [ ] Test PWA installability: `flutter build web --release`

### SSL Certificate
- [ ] Vercel/Netlify/Firebase auto-issue Let's Encrypt SSL
- [ ] No manual configuration needed
- [ ] Automatic renewal enabled

**Estimated Time**: DNS starts propagating (24-48 hours in parallel with other tasks)

---

## PHASE 7: WEB BUILD & DEPLOYMENT (45 minutes) ✅

### Build for Production
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Clean and build
flutter clean
flutter pub get
flutter build web --release

# Verify build
ls -l build/web/index.html
ls -l build/web/main.dart.js
```

### Option A: Deploy to Vercel (Recommended)
```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd c:\Users\PC\AuraSphere\crm\aura_crm
vercel --prod

# Configure environment variables in Vercel dashboard
```

**Checklist**:
- [ ] Vercel account created
- [ ] Project linked
- [ ] Environment variables set:
  - [ ] SUPABASE_URL
  - [ ] SUPABASE_ANON_KEY
  - [ ] STRIPE_PUBLISHABLE_KEY
  - [ ] RESEND_API_KEY
  - [ ] SENTRY_DSN
- [ ] Build successful
- [ ] Test at `https://yourdomain.vercel.app`

### Option B: Deploy to Netlify (Alternative)
```bash
npm install -g netlify-cli
netlify login
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter build web --release
netlify deploy --prod --dir=build/web
```

### Option C: Deploy to Firebase Hosting (Alternative)
```bash
npm install -g firebase-tools
firebase login
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter build web --release
firebase deploy --only hosting
```

**Estimated Time**: 45 min

---

## PHASE 8: COMPREHENSIVE TESTING (45 minutes) ✅

### Authentication Flow
- [ ] Sign up with new email
- [ ] Verify welcome email received
- [ ] Login with email/password
- [ ] Test password reset flow
- [ ] Verify reset email received
- [ ] Logout and login again

### Payment Flow (TEST MODE)
- [ ] Navigate to pricing page
- [ ] Select Solo plan
- [ ] Proceed to checkout
- [ ] Use test card: `4242 4242 4242 4242`
- [ ] Verify subscription created in Stripe dashboard
- [ ] Verify confirmation email received
- [ ] Check user organization has correct plan in database

### Feature Access
- [ ] Dashboard loads
- [ ] Client list loads
- [ ] Can create new client
- [ ] Job management works
- [ ] Invoice creation works
- [ ] Team page loads (check plan limits)
- [ ] AI chat works with Groq API
- [ ] Analytics tracking works (check GA after 24 hours)
- [ ] Error logging works (Sentry should capture it)

### Mobile Responsiveness
- [ ] Test on mobile (375px width)
- [ ] Test on tablet (600px width)
- [ ] Test on desktop (1920px width)
- [ ] All buttons clickable on mobile
- [ ] Forms easily fillable
- [ ] Images load correctly
- [ ] No horizontal scroll needed

### Plan Limits
- [ ] Solo plan shows "1 user max"
- [ ] Team plan shows "3 users"
- [ ] Workshop plan shows "7 users"
- [ ] AI calls count down correctly
- [ ] Download limits enforced

### Performance
- [ ] Page load < 3 seconds
- [ ] Lighthouse score > 80
- [ ] No console errors
- [ ] PWA installable on mobile

**Estimated Time**: 45 min

---

## PHASE 9: CRITICAL SECURITY CHECKS (30 minutes) ✅

### HTTPS/SSL
- [ ] All pages served over HTTPS
- [ ] No mixed content warnings
- [ ] SSL certificate valid (not expired)
- [ ] SSL Labs score: A or A+ (optional)

### Authentication
- [ ] Passwords not logged
- [ ] API keys not exposed in client code
- [ ] JWT tokens secure
- [ ] No sensitive data in localStorage
- [ ] CORS configured correctly

### Database
- [ ] RLS policies enabled on all tables
- [ ] Users can only see own data
- [ ] No SQL injection vulnerabilities
- [ ] Backups enabled in Supabase

### Environment Variables
- [ ] No hardcoded secrets
- [ ] All sensitive keys in `.env.production`
- [ ] Vercel/Netlify has all env vars set
- [ ] No env vars in Git history

### Third-Party Services
- [ ] Stripe keys are production, not test
- [ ] Resend domain verified
- [ ] Sentry project configured
- [ ] Google Analytics tracking code verified

**Estimated Time**: 30 min

---

## PHASE 10: LAUNCH CHECKLIST (Final)

### Pre-Launch (Day Before)
- [ ] All code deployed and tested
- [ ] Database migrations applied
- [ ] Backups enabled
- [ ] Monitoring set up (Sentry, analytics)
- [ ] Support email configured
- [ ] Documentation written
- [ ] Team notified
- [ ] Status page created (optional)

### Launch Day
- [ ] Team available for support
- [ ] Monitor error logs (Sentry)
- [ ] Monitor analytics (Google Analytics)
- [ ] Monitor uptime (UptimeRobot - optional)
- [ ] First customer payment tested
- [ ] Email notifications verified
- [ ] Database performance check

### Post-Launch (First 24 hours)
- [ ] Check error logs (Sentry)
- [ ] Review analytics (GA)
- [ ] Check payment processing (Stripe)
- [ ] Verify email delivery
- [ ] Monitor server performance
- [ ] Check database size
- [ ] Review user feedback
- [ ] Fix any critical bugs immediately
- [ ] Celebrate! 🎉

---

## DEPLOYMENT QUICK REFERENCE COMMANDS

### iOS App Store
```bash
# Open Xcode
open ios/Runner.xcworkspace

# Build for archive
flutter build ios --release

# In Xcode: Product → Archive
# Then: Organizer → Distribute App → App Store Connect
```

### Android Play Store
```bash
# Build app bundle
flutter build appbundle --release

# Upload at: https://play.google.com/console
# File location: build/app/outputs/bundle/release/app-release.aab
```

### Web (Vercel)
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm
flutter build web --release
vercel --prod
```

---

## ESTIMATED TIMELINE

| Phase | Task | Duration | Status |
|-------|------|----------|--------|
| 1 | Payment Setup (Stripe) | 30 min | ✅ Ready |
| 2 | Email Service (Resend) | 15 min | ✅ Ready |
| 3 | Error Logging (Sentry) | 15 min | ✅ Ready |
| 4 | Analytics (GA4) | 15 min | ✅ Ready |
| 5 | Mobile & Download Limits | 30 min | ✅ Ready |
| 6 | Domain & SSL (parallel) | 24-48 hrs | ⏳ Parallel |
| 7 | Web Build & Deployment | 45 min | ✅ Ready |
| 8 | Comprehensive Testing | 45 min | ✅ Ready |
| 9 | Security Checks | 30 min | ✅ Ready |
| 10 | Launch Checklist | Ongoing | ✅ Ready |
| **TOTAL** | **WEB LAUNCH** | **~4 hours + DNS** | **✅ GO LIVE** |

---

## CRITICAL SUCCESS FACTORS

1. ✅ **Payment works** - Users can subscribe successfully
2. ✅ **Emails sent** - Welcome, invoice, password reset emails deliver
3. ✅ **No errors** - Sentry captures zero critical errors
4. ✅ **Analytics track** - User behavior visible in GA
5. ✅ **Plan limits enforced** - Users can't exceed their plan
6. ✅ **Mobile works** - App usable on phones/tablets
7. ✅ **Security solid** - HTTPS, no exposed secrets
8. ✅ **Performance good** - Pages load < 3 seconds
9. ✅ **Database stable** - No connection issues
10. ✅ **Support ready** - Team can handle inquiries

---

## LAUNCH SUCCESS CRITERIA

✅ **Web**: Live at yourdomain.com  
✅ **Email**: Resend verified and working  
✅ **Payment**: First 3 test subscriptions successful  
✅ **Mobile**: iOS build in TestFlight, Android in Play Console  
✅ **Analytics**: Tracking active  
✅ **Errors**: Sentry monitoring, zero critical errors  
✅ **Users**: Can sign up, subscribe, use all features  
✅ **Security**: HTTPS, no vulnerabilities  
✅ **Performance**: Lighthouse > 80  
✅ **Support**: Email/chat response ready  

---

## ROLLBACK PLAN (If Critical Issue)

If critical issue found during launch:

1. **Web Outage**: Rollback to previous Vercel deployment
2. **Payment Broken**: Disable payment, switch to manual billing
3. **Database Issue**: Use Supabase backup/restore
4. **Email Not Sending**: Disable email features temporarily
5. **Performance**: Enable caching, reduce bundle size

---

**Status**: 🟢 ALL SYSTEMS READY  
**Last Updated**: January 4, 2026  
**Next Action**: Execute Phase 1 (Payment Setup)  

**Let's Launch! 🚀**
