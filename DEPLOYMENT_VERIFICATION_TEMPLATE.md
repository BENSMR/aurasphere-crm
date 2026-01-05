# 📋 DEPLOYMENT VERIFICATION TEMPLATE

Use this checklist to verify each step of your launch.

---

## 🏗️ BUILD VERIFICATION

**Date**: _______________  
**Time Started**: _______________  

### Build Command
```bash
flutter build web --release
```

**Status**:
- [ ] Build started successfully
- [ ] Compilation completed (look for "✨ Built build/web")
- [ ] Build output directory created: `build/web/`

**Build Output Verification**:
```bash
# Run these commands to verify
dir build/web                    # Windows
ls -la build/web                 # Mac/Linux

# Look for these files:
- index.html          (Main page)
- main.dart.js        (Compiled Dart code)
- flutter.js          (Flutter runtime)
- assets/             (Images, fonts, etc)
```

- [ ] `index.html` exists
- [ ] `main.dart.js` exists (>1 MB for release build)
- [ ] `flutter.js` exists
- [ ] `assets/` folder has files
- [ ] `pubspec.lock` NOT in build/web (good, removed)

**Build Size**:
```bash
# Check total size (should be 12-15 MB)
du -sh build/web     # Mac/Linux
Get-ChildItem -Path build/web -Recurse | Measure-Object -Property Length -Sum  # Windows
```

- [ ] Total size: 12-15 MB ✅
- [ ] NOT larger than 50 MB ⚠️
- [ ] Acceptable for deployment

---

## 🔑 PRODUCTION SECRETS VERIFICATION

### Environment Variables Checklist

**Stripe**
- [ ] Key obtained from stripe.com
- [ ] Key is production (starts with `pk_live_`) - NOT test key
- [ ] Added to `.env` locally: `STRIPE_KEY=pk_live_xxx`
- [ ] Added to hosting platform's env vars
- [ ] Webhook endpoint configured: `https://yourdomain.com/api/stripe-webhook`

**Resend Email**
- [ ] Key obtained from resend.com
- [ ] Added to `.env`: `RESEND_API_KEY=re_xxx`
- [ ] Added to hosting platform's env vars
- [ ] Sender domain verified (resend.com dashboard)

**Groq AI**
- [ ] Key obtained from groq.com
- [ ] Added to `.env`: `GROQ_API_KEY=gsk_xxx`
- [ ] Added to hosting platform's env vars

**WhatsApp (Optional)**
- [ ] Twilio Account SID obtained
- [ ] Twilio Auth Token obtained
- [ ] Phone ID from WhatsApp Business
- [ ] Added to hosting platform's env vars

**OCR (Optional)**
- [ ] API key configured
- [ ] Free tier or paid account active

### Secret Storage Verification
- [ ] `.env` file exists locally (gitignore so not committed)
- [ ] `.env` NOT pushed to GitHub ✅
- [ ] Secrets only in hosting platform env vars
- [ ] No secrets visible in browser DevTools Network tab
- [ ] No hardcoded API keys in source code

---

## 🚀 HOSTING DEPLOYMENT VERIFICATION

### Choose Your Platform

#### **FIREBASE** ☑️
```bash
firebase init hosting
firebase deploy
```

Verification:
- [ ] Firebase CLI installed: `firebase --version`
- [ ] Logged in: `firebase login`
- [ ] Project selected: `firebase use --add`
- [ ] Public directory set to: `build/web`
- [ ] Deployment successful: "Deploy complete!"
- [ ] Live URL: `https://yourproject.web.app`
- [ ] HTTPS active: ✅ Automatic
- [ ] Can access live URL: ✅

---

#### **VERCEL** ☑️
```bash
vercel --prod --cwd build/web
```

Verification:
- [ ] Vercel CLI installed: `vercel --version`
- [ ] Logged in: `vercel login`
- [ ] Build directory correct: `build/web`
- [ ] Deployment successful: "Ready on *.vercel.app"
- [ ] Live URL: `https://yourapp.vercel.app`
- [ ] HTTPS active: ✅ Automatic
- [ ] Can access live URL: ✅

---

#### **NETLIFY** ☑️
```bash
netlify deploy --prod --dir=build/web
```

Verification:
- [ ] Netlify CLI installed: `netlify --version`
- [ ] Logged in: `netlify login`
- [ ] Deploy directory: `build/web`
- [ ] Deployment successful: "Website is live"
- [ ] Live URL: `https://yoursite.netlify.app`
- [ ] HTTPS active: ✅ Automatic
- [ ] Can access live URL: ✅

---

## ✅ FUNCTIONAL VERIFICATION

### Smoke Tests (Critical)

**Basic Load**
- [ ] Homepage loads (< 1.5 seconds)
- [ ] No 404 errors
- [ ] No blank white screen
- [ ] All text and images visible

**Authentication**
- [ ] Sign-up page accessible
- [ ] Sign-in page accessible
- [ ] Can log in with test account
- [ ] Dashboard loads after login
- [ ] Profile page works

**Navigation**
- [ ] Top navigation visible
- [ ] Bottom nav works (mobile)
- [ ] Can navigate between pages
- [ ] No broken links

**Data Loading**
- [ ] Dashboard shows data
- [ ] Jobs list loads
- [ ] Invoices list loads
- [ ] Clients list loads
- [ ] No "undefined" errors

### Critical Path Tests

**Create Job**
- [ ] Job creation form loads
- [ ] Can fill in job details
- [ ] Can set date/time
- [ ] Can assign client
- [ ] Job saves successfully
- [ ] Job appears in list
- [ ] Can edit job

**Create Invoice**
- [ ] Invoice creation accessible
- [ ] Can select client
- [ ] Can add line items
- [ ] Can set amount
- [ ] Invoice saves
- [ ] Invoice appears in list
- [ ] Can view invoice

**Send Email**
- [ ] Invoice email send button works
- [ ] Resend API responds
- [ ] Email received (check inbox/spam)
- [ ] Email contains invoice data
- [ ] PDF attachment present (if applicable)

**Payment Flow**
- [ ] Payment button visible on invoice
- [ ] Stripe payment form loads
- [ ] Can enter test card: `4242 4242 4242 4242`
- [ ] Payment processes successfully
- [ ] Invoice marked as paid
- [ ] Confirmation email sent

**AI Chat** (If enabled)
- [ ] Chat interface loads
- [ ] Can type message
- [ ] Groq API responds
- [ ] Response appears in chat
- [ ] No errors in console

**WhatsApp** (If enabled)
- [ ] WhatsApp send button visible
- [ ] Can compose message
- [ ] Message sends via Twilio
- [ ] Delivery confirmed

### Performance Tests

**Load Times**
- [ ] Homepage: < 1.5 seconds ✅
- [ ] Dashboard: < 2 seconds ✅
- [ ] Job list: < 1 second ✅
- [ ] Invoice list: < 1 second ✅

**Network**
- [ ] No waterfall delays
- [ ] Images optimized (< 100KB each)
- [ ] CSS/JS minified
- [ ] No failed requests

**Browser DevTools Checks**
- [ ] Console: No red errors ✅
- [ ] Network: All requests 200-399 status ✅
- [ ] Performance: No jank (60fps smooth)
- [ ] Accessibility: No major a11y errors

### Security Tests

**Authentication**
- [ ] Unauthenticated users redirected to `/`
- [ ] Cannot access `/dashboard` without login
- [ ] Logout works
- [ ] Session expires correctly

**Data Protection**
- [ ] API calls use HTTPS ✅
- [ ] No sensitive data in localStorage (beyond JWT)
- [ ] No hardcoded API keys visible
- [ ] CORS headers correct
- [ ] CSRF tokens present (if applicable)

**Browser Security**
- [ ] No console warnings (yellow)
- [ ] CSP headers present
- [ ] X-Frame-Options set
- [ ] X-Content-Type-Options set
- [ ] No mixed content (HTTP mixed with HTTPS)

### Responsive Design

**Desktop (1920x1080)**
- [ ] Layout optimal
- [ ] Sidebar visible
- [ ] Multi-column layout works
- [ ] No overflow

**Tablet (768x1024)**
- [ ] Layout adapts
- [ ] Touch targets large enough (44px+)
- [ ] Navigation readable

**Mobile (375x667)**
- [ ] Single column layout
- [ ] Bottom nav accessible
- [ ] Text readable (16px+)
- [ ] Buttons tappable

**Test on Devices**
- [ ] Desktop browser (Chrome, Firefox, Safari)
- [ ] iPhone (Safari)
- [ ] Android (Chrome)
- [ ] Tablet (iPad)

---

## 📊 MONITORING SETUP

### Error Tracking
- [ ] Sentry account created
- [ ] Sentry DSN added to app
- [ ] Test error tracking (throw test exception)
- [ ] Error appeared in Sentry dashboard
- [ ] Email alerts configured

### Uptime Monitoring
- [ ] Uptime Robot account created
- [ ] Monitor created for production URL
- [ ] Check interval: 5 minutes
- [ ] SMS/Email alerts enabled
- [ ] Dashboard accessible

### Analytics
- [ ] Google Analytics ID installed
- [ ] Events tracked (sign-up, job creation, etc.)
- [ ] Dashboard accessible
- [ ] User flow visible

### Logs
- [ ] Supabase logs accessible
- [ ] Edge Function logs visible
- [ ] Application logs monitored
- [ ] Alert rules configured for errors

---

## 🎉 LAUNCH COMPLETE

When all items are checked ✅:

**Sign-off**
- [ ] All tests passed
- [ ] Stakeholders notified
- [ ] Support ready
- [ ] Monitoring active
- [ ] Backup verified

**Time Deployed**: _______________  
**Deployed By**: _______________  
**Verified By**: _______________  
**Go-Live Time**: _______________  

---

## 📞 ROLLBACK PLAN

**If Critical Issues Found**:
1. Immediately take site down (don't leave broken experience)
2. Revert to previous deployment
3. Fix issue locally
4. Redeploy
5. Notify users of outage & resolution

**Rollback Commands**:
```bash
# Firebase
firebase deploy --only hosting:yourproject

# Vercel
vercel --prod revert

# Netlify
netlify deploy --prod --trigger
```

---

**Keep this checklist for your records and post-launch reference!**
