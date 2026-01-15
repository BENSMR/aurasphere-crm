# 🚀 Deployment Guide - Complete Production Guide

**Version**: 1.0 | **Updated**: January 15, 2026

---

## 📋 Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Configuration](#environment-configuration)
3. [Web Deployment](#web-deployment)
4. [Mobile Deployment](#mobile-deployment)
5. [Database Migrations](#database-migrations)
6. [Edge Functions Deployment](#edge-functions-deployment)
7. [Monitoring & Logging](#monitoring--logging)
8. [Plan-Specific Deployment](#plan-specific-deployment)
9. [Rollback Procedures](#rollback-procedures)

---

## Pre-Deployment Checklist

### Code Quality

```bash
# Run analyzer
flutter analyze

# Fix issues
dart fix --apply

# Format code
dart format lib/

# Run tests
flutter test
flutter test integration_test/

# Check dependencies
flutter pub outdated
flutter pub upgrade --major-versions
```

### Security Audit

- [ ] **API Keys**
  - [ ] No API keys hardcoded in code
  - [ ] All keys moved to Supabase Secrets
  - [ ] Edge Functions use env.get()
  - [ ] Verified with `grep -r "sk_\|pk_\|gsk_" lib/`

- [ ] **RLS Policies**
  - [ ] All queries include org_id filter
  - [ ] RLS policies reviewed and tested
  - [ ] Cross-org data access prevented
  - [ ] Row-level security enforced

- [ ] **Authentication**
  - [ ] Auth guards on all protected pages
  - [ ] Session management configured
  - [ ] Password requirements met
  - [ ] OAuth providers configured (if used)

- [ ] **Data Privacy**
  - [ ] GDPR compliance verified
  - [ ] Data retention policies set
  - [ ] User deletion cascade works
  - [ ] PII encryption configured

- [ ] **Dependency Vulnerabilities**
  ```bash
  flutter pub get --security-updates
  ```

### Performance Optimization

```bash
# Optimize web build
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check bundle size
du -sh build/web/

# Expected size: 12-15 MB (minified)
```

### Content Verification

- [ ] All 30+ pages functional
- [ ] All 43 services tested
- [ ] All 9 languages (i18n) verified
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Dark mode/light mode working
- [ ] Accessibility features working

---

## Environment Configuration

### Development Environment

**File**: `.env.development`

```bash
# Supabase
SUPABASE_URL=https://fppmuibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...

# APIs
STRIPE_PUBLISHABLE_KEY=pk_test_...
PADDLE_VENDOR_ID=12345

# Features
ENABLE_AI_AGENTS=true
ENABLE_INTEGRATIONS=true
DEBUG_MODE=true
LOG_LEVEL=debug
```

**Configuration in Dart**:

```dart
// lib/core/env_loader.dart
class EnvLoader {
  static const String supabaseUrl = 'https://fppmuibvpxrkwmymszhd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGc...';
  static const String stripePublishableKey = 'pk_test_...';
  static bool debugMode = true;
}
```

### Staging Environment

**File**: `.env.staging`

```bash
# Supabase (Staging project)
SUPABASE_URL=https://staging-supabase-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...staging...

# APIs (Test keys)
STRIPE_PUBLISHABLE_KEY=pk_test_...
PADDLE_VENDOR_ID=test_12345

# Features
ENABLE_AI_AGENTS=true
ENABLE_INTEGRATIONS=true
DEBUG_MODE=false
LOG_LEVEL=info
```

### Production Environment

**File**: `.env.production`

```bash
# Supabase (Production)
SUPABASE_URL=https://fppmuibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...prod...

# APIs (Live keys)
STRIPE_PUBLISHABLE_KEY=pk_live_...
PADDLE_VENDOR_ID=123456

# Features
ENABLE_AI_AGENTS=true
ENABLE_INTEGRATIONS=true
DEBUG_MODE=false
LOG_LEVEL=warning
CRASH_REPORTING=true
```

### Secrets Management

**Supabase Console → Settings → Secrets**

```bash
# Supabase Secrets (for Edge Functions)
STRIPE_SECRET_KEY = sk_live_...
STRIPE_WEBHOOK_SECRET = whsec_...
PADDLE_API_KEY = pad_live_...
RESEND_API_KEY = re_...
GROQ_API_KEY = gsk_...
TWILIO_ACCOUNT_SID = AC...
TWILIO_AUTH_TOKEN = ...
SMTP_PASSWORD = ...
```

---

## Web Deployment

### Option 1: Vercel Deployment

#### Setup

```bash
# Install Vercel CLI
npm install -g vercel

# Initialize Vercel
vercel login
vercel init
```

#### Configuration

**File**: `vercel.json`

```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "env": {
    "SUPABASE_URL": "@supabase_url",
    "SUPABASE_ANON_KEY": "@supabase_anon_key",
    "STRIPE_PUBLISHABLE_KEY": "@stripe_publishable_key"
  }
}
```

#### Deploy

```bash
# Deploy to production
vercel --prod

# Deploy to staging
vercel

# View logs
vercel logs <deployment-url>
```

### Option 2: Firebase Hosting

#### Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project
firebase init hosting
```

#### Configuration

**File**: `firebase.json`

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/node_modules/**", "**/.*"],
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
            "key": "X-Frame-Options",
            "value": "SAMEORIGIN"
          },
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          }
        ]
      }
    ]
  }
}
```

#### Deploy

```bash
# Build web
flutter build web --release

# Deploy to Firebase
firebase deploy

# Check deployment
firebase hosting:list
```

### Option 3: Self-Hosted (Docker)

#### Dockerfile

```dockerfile
FROM node:18-alpine AS build

WORKDIR /app

# Install Flutter
RUN apk add --no-cache curl git bash
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:$PATH"
RUN flutter config --enable-web

# Copy source
COPY . .

# Get dependencies
RUN flutter pub get

# Build web
RUN flutter build web --release

# Nginx stage
FROM nginx:alpine

# Copy built app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

#### Deploy

```bash
# Build image
docker build -t aura-crm:latest .

# Run container
docker run -p 80:80 aura-crm:latest

# Push to registry
docker tag aura-crm:latest your-registry/aura-crm:latest
docker push your-registry/aura-crm:latest
```

---

## Mobile Deployment

### Android Deployment

#### 1. Build Release APK

```bash
# Build APK
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release

# Output locations
# APK: build/app/outputs/flutter-apk/app-release.apk
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

#### 2. Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Fill in app details:
   - Name: "AuraSphere CRM"
   - Category: Business
   - Description: "SaaS CRM for tradespeople"

4. Upload App Bundle:
   - Internal Testing → Upload build/app/outputs/bundle/release/app-release.aab
   - Create version notes
   - Release to testing → Staging → Production

#### 3. App Configuration

**File**: `android/app/build.gradle`

```gradle
android {
    defaultConfig {
        applicationId = "com.aurasphere.crm"
        minSdkVersion = 21
        targetSdkVersion = 33
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        release {
            keyAlias 'aura-crm'
            keyPassword System.getenv("KEY_PASSWORD")
            storeFile file(System.getenv("KEYSTORE_PATH"))
            storePassword System.getenv("KEYSTORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### iOS Deployment

#### 1. Build Release IPA

```bash
# Build IPA
flutter build ios --release

# Output: build/ios/ipa/

# Alternatively, use Xcode
open ios/Runner.xcworkspace
# Select "Runner" → "Signing & Capabilities"
# Set Team ID and Bundle ID
# Build → iOS Device
# Product → Archive
```

#### 2. App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app:
   - Name: "AuraSphere CRM"
   - Bundle ID: "com.aurasphere.crm"
   - SKU: "aura-crm-001"

3. Complete app information:
   - Description
   - Keywords
   - Support URL
   - Privacy Policy URL

4. Upload build:
   - Xcode → Window → Organizer
   - Select build → Upload to App Store

5. Submit for review

#### 3. App Configuration

**File**: `ios/Runner/Info.plist`

```xml
<dict>
    <!-- App name -->
    <key>CFBundleDisplayName</key>
    <string>AuraSphere</string>
    
    <!-- Version -->
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    
    <key>CFBundleVersion</key>
    <string>1</string>
    
    <!-- Minimum iOS version -->
    <key>MinimumOSVersion</key>
    <string>12.0</string>
    
    <!-- Permissions -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to photos to upload receipts and invoices</string>
    
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to scan documents and take photos</string>
</dict>
```

---

## Database Migrations

### Pre-Deployment Backup

```bash
# Backup production database
supabase db push --dry-run

# Export data
supabase db push --backup-name "2026-01-15-pre-deployment"
```

### Run Migrations

```bash
# Check pending migrations
supabase status

# Apply migrations
supabase db push

# Verify schema
supabase db show

# Rollback if needed (covered in Rollback section)
```

### Migration Versioning

**File**: `supabase/migrations/20260115_add_new_features.sql`

```sql
-- Migration: 2026-01-15 - Add new features
-- Author: Dev Team
-- Description: Add feature_personalization audit log and device limits

BEGIN;

-- Create feature_audit_log table
CREATE TABLE IF NOT EXISTS public.feature_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  performed_by uuid NOT NULL REFERENCES auth.users(id),
  target_user_id uuid,
  target_device_id uuid,
  details TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT fk_org_id FOREIGN KEY (org_id) REFERENCES organizations(id)
);

-- Add indexes
CREATE INDEX idx_feature_audit_org_id ON feature_audit_log(org_id);
CREATE INDEX idx_feature_audit_created_at ON feature_audit_log(created_at);

-- Add RLS
ALTER TABLE feature_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view audit logs for their org" ON feature_audit_log
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

COMMIT;
```

### Testing Migrations

```bash
# Test migration in staging
supabase db push --project-id=staging-project

# Verify data integrity
SELECT COUNT(*) FROM feature_audit_log;

# Test rollback
supabase db reset --project-id=staging-project
```

---

## Edge Functions Deployment

### Deploy All Functions

```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy groq-proxy

# View function logs
supabase functions logs groq-proxy
```

### Deploy Groq AI Proxy

**File**: `supabase/functions/groq-proxy/index.ts`

```typescript
import "https://esm.sh/v135/@supabase/supabase-js@2.43.4";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");

export const handler = async (req: Request) => {
  try {
    const { message, language, model } = await req.json();

    if (!message) {
      return new Response(
        JSON.stringify({ error: "Message required" }),
        { status: 400 }
      );
    }

    const response = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${GROQ_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messages: [{ role: "user", content: message }],
          model: model || "mixtral-8x7b-32768",
          temperature: 0.7,
          max_tokens: 1024,
        }),
      }
    );

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    );
  }
};
```

### Deploy Email Proxy

**File**: `supabase/functions/email-proxy/index.ts`

```typescript
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

export const handler = async (req: Request) => {
  try {
    const { to, subject, body, replyTo } = await req.json();

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "noreply@aurasphere.io",
        to,
        subject,
        html: body,
        reply_to: replyTo,
      }),
    });

    return new Response(await response.text(), {
      status: response.status,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    );
  }
};
```

### Set Secrets

```bash
# Set Groq API key
supabase secrets set GROQ_API_KEY=gsk_...

# Set Resend API key
supabase secrets set RESEND_API_KEY=re_...

# Set Stripe keys
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...

# Verify secrets set
supabase secrets list
```

---

## Monitoring & Logging

### Application Monitoring

**Sentry Integration** (Error Tracking)

```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://your-sentry-dsn@sentry.io/project-id';
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = 0.1;
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

### Logging Configuration

**File**: `lib/core/logger_config.dart`

```dart
import 'package:logger/logger.dart';

class LoggerConfig {
  static final Logger logger = Logger(
    level: kReleaseMode ? Level.warning : Level.debug,
    printer: PrettyPrinter(
      methodCount: 3,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );
}
```

### Database Monitoring

**Supabase Dashboard**

1. Go to Supabase Console
2. Click "Analytics"
3. Monitor:
   - Query latency
   - Error rates
   - Connection count
   - Storage usage

### Real-Time Alerts

**Setup Slack Integration**:

1. In Supabase Console → Database Webhooks
2. Create webhook for critical events:
   ```
   Table: invoices
   Event: UPDATE (when status = 'failed_payment')
   Endpoint: https://your-slack-webhook
   ```

---

## Plan-Specific Deployment

### SOLO Plan Deployment

```bash
# Disable advanced features
flutter build web --release \
  --dart-define=ENABLE_AI_AGENTS=false \
  --dart-define=ENABLE_TEAM_FEATURES=false \
  --dart-define=ENABLE_INTEGRATIONS=false

# Device limit enforcement
# Mobile: 2 devices max
# Tablet: 1 device max
```

### TEAM Plan Deployment

```bash
# Enable limited AI agents
flutter build web --release \
  --dart-define=ENABLE_AI_AGENTS=true \
  --dart-define=AI_AGENT_MODE=limited \
  --dart-define=ENABLE_TEAM_FEATURES=true \
  --dart-define=ENABLE_INTEGRATIONS=true

# Device limits
# Mobile: 3 devices max
# Tablet: 2 devices max
```

### WORKSHOP Plan Deployment

```bash
# Enable all features
flutter build web --release \
  --dart-define=ENABLE_AI_AGENTS=true \
  --dart-define=AI_AGENT_MODE=full \
  --dart-define=ENABLE_TEAM_FEATURES=true \
  --dart-define=ENABLE_INTEGRATIONS=true

# Device limits
# Mobile: 5 devices max
# Tablet: 3 devices max
```

---

## Rollback Procedures

### Web Rollback

#### Vercel

```bash
# View deployments
vercel list

# Rollback to previous
vercel rollback <deployment-url>

# Redeploy specific version
vercel deploy --prod
```

#### Firebase

```bash
# View deployments
firebase hosting:channel:list

# Rollback
firebase hosting:rollback
```

### Database Rollback

```bash
# Check backup
supabase db backups list

# Restore from backup
supabase db restore \
  --backup-id <backup-id> \
  --project-id <project-id>
```

### Mobile Rollback

#### Google Play

1. Go to Internal Testing → Release Management
2. Select build to revert
3. Click "Revert release"

#### App Store

1. In App Store Connect
2. Select build
3. Click "Delete release"
4. Previous version becomes active

---

## Post-Deployment Verification

### Smoke Tests

```bash
# Test critical flows
✅ User can sign up
✅ User can create invoice
✅ User can send invoice
✅ Payment processing works
✅ AI agents execute (if enabled)
✅ Integrations send data (if enabled)
✅ Real-time updates work
✅ Mobile/tablet responsive
```

### Performance Verification

```bash
# Web Vitals
✅ Core Web Vitals Green (Lighthouse)
✅ LCP < 2.5s
✅ FID < 100ms
✅ CLS < 0.1

# API Performance
✅ Invoice list: < 100ms
✅ Payment checkout: < 500ms
✅ AI agent run: < 5s
```

### Security Verification

```bash
# Security headers
✅ HTTPS enforced
✅ X-Frame-Options: SAMEORIGIN
✅ X-Content-Type-Options: nosniff
✅ Content-Security-Policy set

# Data security
✅ RLS policies active
✅ API keys not exposed
✅ Edge Function secrets loaded
✅ Auth tokens valid
```

---

## Version Management

### Semantic Versioning

```
MAJOR.MINOR.PATCH

1.0.0 = First production release
1.1.0 = New features
1.0.1 = Bug fixes
2.0.0 = Breaking changes
```

### Tagging Releases

```bash
# Create version tag
git tag -a v1.0.0 -m "Production release 1.0.0"

# Push tags
git push origin --tags

# Create release notes on GitHub
# Include:
# - New features
# - Bug fixes
# - Breaking changes
# - Migration instructions
```

---

## Post-Deployment Checklist

- [ ] All 30+ pages accessible
- [ ] All 43 services functional
- [ ] 9 languages working
- [ ] Responsive design verified
- [ ] Payments processing
- [ ] AI agents (if enabled) running
- [ ] Integrations sending data (if enabled)
- [ ] Real-time updates working
- [ ] Performance within SLA
- [ ] Security headers present
- [ ] Error tracking functional
- [ ] Database backups running
- [ ] Monitoring active
- [ ] Alerts configured
- [ ] Documentation updated

---

## Emergency Procedures

### Service Down

1. **Assess Impact**: Check Supabase status, Firebase status
2. **Notify Users**: Post status on status page
3. **Gather Team**: Start incident response
4. **Isolate Issue**: Check logs, database, Edge Functions
5. **Apply Fix**: Deploy hotfix or rollback
6. **Verify Recovery**: Run smoke tests
7. **Post-Mortem**: Document what happened

### Data Corruption

1. **Stop Operations**: Prevent further writes
2. **Assess Scope**: Determine affected records
3. **Restore Backup**: Use most recent good backup
4. **Verify Data**: Validate restored data integrity
5. **Sync Services**: Update replicated systems

### Security Incident

1. **Isolate**: Stop the threat immediately
2. **Assess**: Determine breach scope
3. **Notify**: Alert affected users
4. **Remediate**: Fix vulnerability, reset credentials
5. **Audit**: Review access logs, apply patches

---

Generated: January 15, 2026
