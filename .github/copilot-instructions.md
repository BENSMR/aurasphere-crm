# AuraSphere CRM - AI Coding Agent Instructions

**Last Updated**: January 2026 | Flutter 3.9.2 | Supabase 2.12.0

## 🎯 Quick Start for AI Agents

This is a **Flutter + Supabase SaaS CRM** with 40+ stateful pages, 40+ business logic services, and strict architectural constraints. The codebase enforces:
- **SetState-only** state management (no Provider/Riverpod)
- **Service layer** for all business logic (singleton pattern, never contains UI)
- **Multi-tenant RLS** on every Supabase query (must filter by `org_id`)
- **Edge Functions** as API proxies (no direct API calls with keys on frontend)
- **Two-part auth checks** on protected pages (`initState` + `build` guard)

### ⚠️ Critical Rules (Most Common Mistakes)

1. **EVERY Supabase query must filter by `org_id`** - RLS policies enforce this; missing it = security breach + silent query failure
   ```dart
   // ✅ CORRECT
   await supabase.from('invoices').select().eq('org_id', orgId).eq('status', 'sent');
   
   // ❌ WRONG - will fail silently or raise RLS error
   await supabase.from('invoices').select().eq('status', 'sent');
   ```

2. **Auth checks on EVERY protected page (both `initState` + `build`)**
   ```dart
   // Missing check = page accessible without login on hot reload
   @override
   void initState() {
     super.initState();
     if (Supabase.instance.client.auth.currentUser == null) {
       if (mounted) Navigator.pushReplacementNamed(context, '/');
     }
   }
   
   @override
   Widget build(BuildContext context) {
     if (Supabase.instance.client.auth.currentUser == null) {
       return const Scaffold(body: Center(child: Text('Unauthorized')));
     }
     // Page content...
   }
   ```

3. **Always check `if (mounted)` before setState in catch/finally blocks** - prevents "setState after dispose" crashes
   ```dart
   finally {
     if (mounted) setState(() => loading = false);  // CRITICAL
   }
   ```

4. **NEVER hardcode API keys or call external APIs directly from Flutter**
   ```dart
   // ❌ WRONG - key is exposed
   const groqKey = 'gsk_...';
   
   // ✅ CORRECT - use Edge Function proxy
   final result = await supabase.functions.invoke('groq-proxy', body: {...});
   ```

5. **Services never contain UI code** - they contain ONLY business logic
   ```dart
   // ❌ WRONG - UI code in service
   class InvoiceService {
     void showAlert() => showDialog(...);  // NEVER DO THIS
   }
   
   // ✅ CORRECT - service returns data, page handles UI
   class InvoiceService {
     Future<Invoice> getInvoice(String id) async { ... }
   }
   ```

## Architecture Overview

**AuraSphere CRM** is a Flutter web/mobile app for tradespeople to manage jobs, invoices, clients, and teams. Multi-tenant SaaS with Supabase backend, 9-language i18n, and extensive integrations (Stripe, Paddle, WhatsApp, QuickBooks, HubSpot, Slack).

### Core Stack
- **Frontend**: Flutter (Dart) with Material Design 3 + seeded colors from `#007BFF` (Electric Blue)
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **State Management**: **SetState-only** (no Provider/Riverpod/BLoC) - all pages manage local state via `setState()`
- **Routing**: Named routes in [lib/main.dart](../lib/main.dart) with auth guards on protected routes
- **i18n**: Manual JSON lookup in `assets/i18n/{en,fr,it,de,es,ar,mt,bg}.json`
- **Logging**: `package:logger/logger.dart` in services; `print()` with emoji in pages
- **Services**: 40+ singleton services in `/lib/services/` (see [service inventory](#services-architecture))

### Key Directories
- `/lib/services/` (40 files) - **ALL business logic lives here**; singleton pattern; Logger for logging; **NEVER UI code**
  - Example files: `invoice_service.dart`, `aura_ai_service.dart`, `stripe_service.dart`, `feature_personalization_service.dart`
  - **Pattern**: Static final instance, private constructor, factory method, always call `.single()` or `.maybeSingle()` on Supabase queries
- `/lib/` - Pages & widgets; ~25 `*_page.dart` files; each page manages only local state (loading, lists, form data)
  - Every protected page must check `currentUser == null` in both `initState` + `build` 
  - Use `setState()` with `if (mounted)` safety checks in catch/finally blocks
- `/lib/widgets/` - Reusable UI components (ModernButton, ModernCard, ModernPageTransition)
- `/lib/theme/` - Custom theme config and Material Design 3 extensions
- `/lib/core/` - Auth helper, env loader, app theme
- `/lib/validators/` - Input validation helpers
- `/supabase/functions/` - Deno Edge Functions (Groq AI, WhatsApp, payment webhooks, email, OCR)
  - API keys stored in Supabase Secrets; functions retrieve them at runtime
  - **Never expose keys on frontend** - always proxy through Edge Function
- `/supabase/migrations/` - PostgreSQL schema versions
- `/assets/i18n/` - 9 language JSON files (en, fr, it, de, es, ar, mt, bg)

### Critical Data Flows

1. **Multi-tenant Auth**: All queries filter by `org_id` + `auth.uid` (RLS enforced)
2. **AI Command Pipeline**: User input → `AuraAiService.parseCommand()` → Groq via Edge Function → Action dispatch
3. **Subscription Lifecycle**: Trial → Paddle/Stripe payment → org plan update → feature access control
4. **Automation**: Services run on schedule (backend) or via user triggers; NO cron in frontend

## Essential Patterns

### Auth Guard Pattern (Every Protected Page)
**Option 1: Simple Guard (Recommended)**
```dart
@override
void initState() {
  super.initState();
  _checkAuth();
}

Future<void> _checkAuth() async {
  if (Supabase.instance.client.auth.currentUser == null) {
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}

@override
Widget build(BuildContext context) {
  if (Supabase.instance.client.auth.currentUser == null) {
    return Scaffold(body: Center(child: Text('Unauthorized')));
  }
  // Page content
}
```
**Why both checks**: Race condition on hot reload. `initState` redirects; `build` guards state updates.

**Option 2: AuthGate Pattern (For root navigation)**
Use `AuthGate` widget in main.dart to check session in background without blocking UI:
```dart
class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuthInBackground();
  }

  Future<void> _checkAuthInBackground() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) => const LandingPageAnimated(); // Show landing immediately
}
```
**Why this pattern**: Non-blocking, fast initial render, graceful fallback if auth check fails.

### Supabase Query Pattern
```dart
final org = await supabase
    .from('organizations')
    .select('id, plan, owner_id')  // Only fetch needed fields
    .eq('owner_id', userId)
    .single();  // Use .single() for 1 result, .maybeSingle() for 0-1

// Batch complex queries with joins
final data = await supabase
    .from('invoices')
    .select('*, clients!inner(id, email)')  // Join with RLS check
    .eq('org_id', orgId)
    .eq('status', 'sent')
    .lt('due_date', overdueDate);
```
**Rules**: Never silently catch exceptions; use `.single()` + `.maybeSingle()`; always filter by `org_id`.

### Async State Management
```dart
class _PageState extends State<Page> {
  bool loading = true;
  List items = [];

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      items = await _fetchData();
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);  // Critical: check mounted
    }
  }
}
```
**Key**: Always `if (mounted)` before setState in finally/catch to prevent "setState after dispose" crashes.

### Logging Convention
**Pages**: Use `print()` with emoji prefixes for UI debugging:
- `print('✅ Success: ...')` - Expected outcome
- `print('❌ Error: $e')` - Error with context
- `print('⚠️ Warning: ...')` - Unexpected but harmless
- `print('🔄 Processing: ...')` - Async work in progress
- `print('🤖 AI: ...')` - AI/LLM calls
- `print('📧 Email: ...')` - Email notifications
- `print('💳 Payment: ...')` - Financial transactions

**Services**: Use `Logger` from `package:logger/logger.dart` instead:
```dart
final _logger = Logger();
_logger.i('🔄 Processing...');  // Info
_logger.e('Failed: $error');     // Error
_logger.w('Warning: $msg');      // Warning
```

### Service Singleton Pattern
All services use lazy singleton with private constructor. Pattern varies slightly:

**With Logger (Recommended for business logic services):**
```dart
import 'package:logger/logger.dart';

final _logger = Logger();

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  final supabase = Supabase.instance.client;

  InvoiceService._internal();  // Private constructor

  factory InvoiceService() => _instance;

  Future<void> sendReminders() async {
    _logger.i('🔄 Sending reminders...');
    try {
      // Logic
    } catch (e) {
      _logger.e('Failed: $e');
      rethrow;
    }
  }
}
```

**Without Logger (Some services like PrepaymentCodeService):**
- No factory needed if no Logger overhead expected
- Still use static final instance

**Usage**: `InvoiceService().sendReminders()` - always same instance across app.

### Feature Flags & Personalization
Stored in `user_preferences.features` (JSONB):
```dart
final prefs = await supabase
    .from('user_preferences')
    .select('features, business_type')
    .eq('user_id', userId)
    .single();

// Check feature
final hasAI = prefs?['features']?['aura_ai_enabled'] == true;
final businessType = prefs?['business_type'];  // 'freelancer' or 'trades'
```
See [lib/services/feature_personalization_service.dart](../lib/services/feature_personalization_service.dart) for bulk feature management.

## Services Architecture (40 files)

### Core Business Logic
- `invoice_service.dart` - Overdue reminders, payment status tracking
- `recurring_invoice_service.dart` - Auto-billing setup and schedule management
- `tax_service.dart` - 40+ country tax rates + calculation
- `ocr_service.dart` - Receipt image → JSON extraction
- `pdf_service.dart` - Invoice PDF generation + templating
- `company_profile_service.dart` - Organization profile, logo, branding
- `digital_signature_service.dart` - XAdES-B/T/C/X invoice signing, RSA-SHA256, certificate management

### Team & Device Management
- `team_member_control_service.dart` - Team member codes, permissions, approval workflow (owner-controlled)
- `device_management_service.dart` - Mobile/tablet device registration, reference codes, access control
- `feature_personalization_service.dart` - Owner control for device features (mobile 6 features / tablet 8 features)

### Payment & Subscriptions
- `stripe_service.dart` - Stripe checkout, invoice sync, webhook handling
- `stripe_payment_service.dart` - Stripe payment operations (separate from checkout)
- `paddle_service.dart`, `paddle_payment_service.dart` - Paddle integration
- `trial_service.dart` - Trial creation, expiry tracking, upsell logic
- `prepayment_code_service.dart` - Prepaid code redemption (gift cards, prepayment codes)

### AI & Automation
- `aura_ai_service.dart` - Groq LLM command parsing (SECURE: via Edge Function only)
- `ai_automation_service.dart` - Budget alerts, rate limiting, cost tracking
- `autonomous_ai_agents_service.dart` - Auto job completion, lead scoring
- `lead_agent_service.dart` - Follow-up reminders, cold lead flagging
- `supplier_ai_agent.dart` - Supplier cost optimization
- `marketing_automation_service.dart` - Email campaigns, engagement tracking

### Feature Personalization
- `feature_personalization_helper.dart` - Mobile/tablet feature helpers
- See [feature_personalization_service.dart](../lib/services/feature_personalization_service.dart) for owner control layer

### Integrations
- `whatsapp_service.dart` - Message dispatch, media upload, delivery logs
- `integration_service.dart` - HubSpot deals, Slack notifications, Zapier webhooks, Google Calendar sync, QuickBooks sync
- `email_service.dart`, `resend_email_service.dart` - Email via Resend
- `quickbooks_service.dart` - OAuth + invoice/expense sync

### Infrastructure & Utilities
- `realtime_service.dart` - Supabase subscriptions (presence, live updates)
- `notification_service.dart` - In-app + email notifications, preference management
- `backup_service.dart` - Scheduled org backups to cold storage
- `reporting_service.dart` - Custom reports + data export
- `rate_limit_service.dart` - API throttling + cost control
- `backend_api_proxy.dart` - Middleware for secure API calls
- `aura_security.dart` - PKI key rotation, encryption
- `offline_service.dart` - Cached data + sync on reconnect
- `whitelabel_service.dart` - White-label tenant customization
- `env_loader.dart` - Environment variables (NOT API KEYS - those go to Edge Functions)

## Digital Signatures (XAdES-B Compliance)

New feature for electronic invoice signing with regulatory compliance:

### Standards & Algorithms
- **Format**: XAdES-B (with optional timestamp for T/C/X levels)
- **Algorithm**: RSA-SHA256 (default) or RSA-SHA512
- **Encoding**: UTF-8 for all XML and signature data
- **Certificate Format**: PEM-encoded X.509 certificates

### Service Pattern
```dart
final sigService = DigitalSignatureService();

// Upload signing certificate
await sigService.uploadCertificate(
  orgId: orgId,
  certificatePem: pemData,
  certificateName: 'Company Legal Signature',
  keyPassword: password,
);

// Sign an invoice
final signed = await sigService.signInvoice(
  orgId: orgId,
  invoiceId: invoiceId,
  certificateId: certId,
  xadesLevel: 'B', // XAdES-B, T, C, or X
);
```

### Database Tables
- `digital_certificates` - Certificate storage, validity tracking, revocation
- `invoice_signatures` - Signature records, XAdES XML, audit trail
- Both tables enforce `org_id` RLS policies

## Workflow & Build

### Dev Commands
```bash
flutter pub get                    # Fetch deps
flutter run -d chrome              # Run web (hot reload enabled)
flutter analyze                    # Lint (uses analysis_options.yaml)
dart fix --apply                   # Auto-fix formatting + issues
```

### Build & Deploy
```bash
flutter clean && flutter build web --release
# Output: build/web/ (~12-15 MB, minified+tree-shaken)

# Local test
cd build/web && python -m http.server 8000
```

### Route Management
All routes defined in [lib/main.dart](../lib/main.dart#L47-L59). When adding new page:

1. **Import & Register**: Add to `routes` map
   ```dart
   routes: {
     '/': (c) => const LandingPageAnimated(),
     '/sign-in': (c) => const SignInPage(),
     '/dashboard': (c) => const DashboardPage(),
     '/new-page': (c) => const NewPage(),  // Add here
   }
   ```

2. **Protect with Auth**: Routes like `/dashboard` are checked in `onGenerateRoute`
   ```dart
   onGenerateRoute: (settings) {
     if ((settings.name == '/dashboard' || settings.name == '/new-page') && 
         Supabase.instance.client.auth.currentUser == null) {
       return MaterialPageRoute(builder: (c) => const SignInPage());
     }
     return null;
   }
   ```

3. **Add to Bottom Nav** (if needed in HomePage)

## Critical Implementation Patterns

### Secure API Calls via Edge Functions (CRITICAL)
**Pattern**: Never expose API keys on frontend. Always use Supabase Edge Functions as a proxy:

```dart
// ✅ CORRECT: Call Edge Function (key hidden in Supabase Secrets)
final result = await supabase.functions.invoke(
  'supplier-ai-agent',
  body: {'input': userInput, 'language': 'en'},
);

// ❌ WRONG: Never do this
const groqKey = 'gsk_...';  // EXPOSED! Anyone can reverse-engineer
await fetch('https://api.groq.com/...', headers: {'Authorization': 'Bearer $groqKey'})
```

**Implementation**: Each external API (Groq, Resend, Stripe, etc.) has an Edge Function wrapper:
- `supabase/functions/supplier-ai-agent/` - Groq LLM (uses `Deno.env.get('GROQ_API_KEY')`)
- `supabase/functions/send-email/` - Resend email (uses `Deno.env.get('RESEND_API_KEY')`)
- API keys stored securely in Supabase → Settings → Secrets (encrypted at rest)

**Services using this pattern**: `aura_ai_service.dart`, `email_service.dart`, `backend_api_proxy.dart`

### Multi-tenancy & Security
1. **ALWAYS filter by `org_id`**: RLS policies depend on it
   ```dart
   final data = await supabase
       .from('invoices')
       .select()
       .eq('org_id', currentOrgId)  // NEVER SKIP
       .eq('status', 'sent');
   ```
   All tables enforce RLS: queries missing `org_id` fail at DB layer.

2. **API Keys**: NEVER hardcode or load from env. Use Edge Functions + Supabase Secrets:
   - Frontend calls Edge Function via `supabase.functions.invoke()`
   - Edge Function retrieves key: `Deno.env.get('GROQ_API_KEY')`
   - Key never transmitted to client
   - See [backend_api_proxy.dart](../lib/services/backend_api_proxy.dart) for pattern

3. **Missing `org_id` = SECURITY BREACH** - audit all Supabase queries before deploying.

### Authentication on Protected Pages
Every protected page needs **both** `initState` check AND `build` guard:
```dart
@override
void initState() {
  super.initState();
  _checkAuth();
}

Future<void> _checkAuth() async {
  if (Supabase.instance.client.auth.currentUser == null) {
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}

@override
Widget build(BuildContext context) {
  if (Supabase.instance.client.auth.currentUser == null) {
    return const Scaffold(body: Center(child: Text('Unauthorized')));
  }
  // Page content
}
```
**Why both checks**: `initState` redirects on first load; `build` guards against async race conditions and hot reloads.

### Service Layer Responsibilities
- Business logic only (invoice calculations, payment processing, API calls)
- **Never**: UI code, navigation, context references, setState
- Always log with `_logger.i()`, `_logger.e()`, `_logger.w()`
- Use singleton pattern for all services

### Feature Personalization
Always check before rendering feature-heavy sections:
```dart
final features = await FeaturePersonalizationService()
    .getPersonalizedFeatures(userId: userId, deviceType: 'mobile');
final hasAI = features.any((f) => f['id'] == 'ai_agents');
```

### Real-Time & Offline
- **Real-time updates**: Use `realtime_service.dart` for live data (presence, subscriptions)
- **Offline sync**: `offline_service.dart` caches data locally and syncs on reconnect
- **Service worker support**: Web app caches assets for offline mode
- Don't implement real-time directly; use the service layer abstraction

## Code Style & Conventions

### File Naming
- Pages: `snake_case_page.dart` (e.g., `client_list_page.dart`)
- Services: `service_name_service.dart` (e.g., `invoice_service.dart`)
- Classes: PascalCase; private classes prefix `_` (e.g., `_HomePageState`)

### Error Handling
Always log descriptive errors with emoji; never silently catch:
```dart
try {
  // Logic
} catch (e) {
  print('❌ Failed to create invoice: $e');  // Emoji + context
  rethrow;  // Propagate unless intentionally handled
}
```

### Responsive Design
Breakpoints and feature limits per device type:
```dart
final width = MediaQuery.of(context).size.width;
final isMobile = width < 600;   // Max 8 features
final isTablet = width >= 600 && width < 1200;  // Max 12 features
final isDesktop = width >= 1200;  // Desktop web
```
Note: Feature personalization enforces max features per device type (see `FeaturePersonalizationService`)

### Internationalization (i18n)
Manual JSON-based i18n with 9 language support (en, fr, it, de, es, ar, mt, bg):
```dart
// Load locale JSON
final jsonString = await rootBundle.loadString('assets/i18n/$languageCode.json');
final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

// Access translations
final greeting = jsonData['greeting'] ?? 'Hello';  // Fallback to English key
final welcome = jsonData['dashboard']?['welcome'] ?? 'Welcome';  // Nested access
```
- JSON files in `assets/i18n/`
- Store user language in `user_preferences.language`
- Always provide fallback keys when accessing nested structures

## Permission & Subscription Model

### Roles
- **Owner**: Full access; manages team, billing, analytics, settings
- **Member/Technician**: Limited access; view assigned jobs, enter time, create expenses only

### Plans (via `organizations.plan`)
- **Solo**: 1 user, core features
- **Team**: Up to 3 users, advanced features
- **Workshop**: Up to 7 users, all features + API access
- **Enterprise**: Custom limits, dedicated support

### Permission Checks
```dart
final org = await supabase.from('organizations')
    .select('plan, owner_id, stripe_status')
    .eq('id', orgId).single();

final isOwner = org['owner_id'] == currentUserId;
final canAccessBilling = isOwner && org['stripe_status'] != 'cancelled';
```

## Database Schema (Key Tables)

- `organizations` - Tenant root; `id, owner_id, plan, stripe_status, name, settings(JSONB)`
- `org_members` - Team users; `org_id, user_id, role, email`
- `clients` - Customer records; `org_id, name, phone, email, address, invoice_count, total_spent`
- `invoices` - Billing; `org_id, client_id, amount, currency, status, due_date, payment_link, reminder_sent_at`
- `jobs` - Work orders; `org_id, status, assigned_to, start_date, end_date, materials_needed, cost`
- `inventory` - Stock; `org_id, item_name, quantity, cost, low_stock_threshold, last_restocked`
- `expenses` - Cost tracking; `org_id, amount, category, receipt_url, created_by, created_at`
- `user_preferences` - Settings; `user_id, features(JSONB), business_type, language, theme`
- `whatsapp_numbers` - Org phone accounts; `org_id, phone, account_sid, auth_token`
- `integrations` - Third-party creds; `org_id, provider(stripe|paddle|hubspot), config(JSONB), active`

## Critical Implementation Patterns

### Secure API Calls via Edge Functions (CRITICAL)
**Pattern**: Never expose API keys on frontend. Always use Supabase Edge Functions as a proxy:

```dart
// ✅ CORRECT: Call Edge Function (key hidden in Supabase Secrets)
final result = await supabase.functions.invoke(
  'supplier-ai-agent',
  body: {'input': userInput, 'language': 'en'},
);

// ❌ WRONG: Never do this
const groqKey = 'gsk_...';  // EXPOSED! Anyone can reverse-engineer
await fetch('https://api.groq.com/...', headers: {'Authorization': 'Bearer $groqKey'})
```

**Implementation**: Each external API (Groq, Resend, Stripe, etc.) has an Edge Function wrapper:
- `supabase/functions/supplier-ai-agent/` - Groq LLM (uses `Deno.env.get('GROQ_API_KEY')`)
- `supabase/functions/send-email/` - Resend email (uses `Deno.env.get('RESEND_API_KEY')`)
- API keys stored securely in Supabase → Settings → Secrets (encrypted at rest)

**Services using this pattern**: `aura_ai_service.dart`, `email_service.dart`, `backend_api_proxy.dart`

### Multi-tenancy & Security
1. **ALWAYS filter by `org_id`**: RLS policies depend on it
   ```dart
   final data = await supabase
       .from('invoices')
       .select()
       .eq('org_id', currentOrgId)  // NEVER SKIP
       .eq('status', 'sent');
   ```
   All tables enforce RLS: queries missing `org_id` fail at DB layer.

2. **API Keys**: NEVER hardcode or load from env. Use Edge Functions + Supabase Secrets:
   - Frontend calls Edge Function via `supabase.functions.invoke()`
   - Edge Function retrieves key: `Deno.env.get('GROQ_API_KEY')`
   - Key never transmitted to client
   - See [backend_api_proxy.dart](../lib/services/backend_api_proxy.dart) for pattern

3. **Missing `org_id` = SECURITY BREACH** - audit all Supabase queries before deploying.

### Authentication on Protected Pages
Every protected page needs **both** `initState` check AND `build` guard:
```dart
@override
void initState() {
  super.initState();
  _checkAuth();
}

Future<void> _checkAuth() async {
  if (Supabase.instance.client.auth.currentUser == null) {
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}

@override
Widget build(BuildContext context) {
  if (Supabase.instance.client.auth.currentUser == null) {
    return const Scaffold(body: Center(child: Text('Unauthorized')));
  }
  // Page content
}
```
**Why both checks**: `initState` redirects on first load; `build` guards against async race conditions and hot reloads.

### Service Layer Responsibilities
- Business logic only (invoice calculations, payment processing, API calls)
- **Never**: UI code, navigation, context references, setState
- Always log with `_logger.i()`, `_logger.e()`, `_logger.w()`
- Use singleton pattern for all services

### Feature Personalization
Always check before rendering feature-heavy sections:
```dart
final features = await FeaturePersonalizationService()
    .getPersonalizedFeatures(userId: userId, deviceType: 'mobile');
final hasAI = features.any((f) => f['id'] == 'ai_agents');
```

### Real-Time & Offline
- **Real-time updates**: Use `realtime_service.dart` for live data (presence, subscriptions)
- **Offline sync**: `offline_service.dart` caches data locally and syncs on reconnect
- **Service worker support**: Web app caches assets for offline mode
- Don't implement real-time directly; use the service layer abstraction

### Key Audit Points
When modifying core tables, audit impacts in:
- `invoice_service.dart` - invoice calculations, reminders, payment status
- `trial_service.dart` - trial expiry, plan upgrades
- `integration_service.dart` - third-party syncs (HubSpot, QuickBooks, Slack)
- `stripe_service.dart` / `paddle_service.dart` - subscription webhooks

### Common Patterns to Follow
1. **Error messages**: Always include emoji + context: `print('❌ Failed to fetch invoices: $e')`
2. **Mounted checks**: Always `if (mounted)` before setState in catch/finally blocks
3. **Async loading state**: Use local `bool loading = true` state, set in try/finally
4. **Supabase errors**: Never silently catch; always log and optionally rethrow
5. **Route additions**: Add to `routes` map in main.dart → add auth check in `onGenerateRoute`
6. **org_id in queries**: Every Supabase query must filter by `org_id` (RLS enforced)
7. **Feature limits**: Enforce mobile (8 features) vs tablet (12 features) in [FeaturePersonalizationService](../lib/services/feature_personalization_service.dart)
8. **Edge Function calls**: Use `supabase.functions.invoke()` never direct API calls with keys

## Troubleshooting & Common Gotchas

### Auth Issues
- **Page shows "Unauthorized" then redirects**: Both `initState` check AND `build` guard are needed (see Auth Guard Pattern)
- **Hot reload loses session**: Use `AuthGate` pattern in main.dart for non-blocking auth checks
- **"setState after dispose"**: Always check `if (mounted)` before setState in catch/finally blocks

### Supabase Query Issues
- **RLS policy violation error**: Missing `.eq('org_id', orgId)` on your query
- **Query returns empty but data exists**: Check RLS policies + user permissions in `org_members`
- **Real-time subscriptions not updating**: Use [realtime_service.dart](../lib/services/realtime_service.dart) for presence/live data

### Edge Function Issues
- **"Function not found" error**: Ensure function deployed: `supabase functions list` should show it
- **"Secret not configured" error**: Secret not added to Supabase → Settings → Secrets, or function redeployment needed
- **CORS errors on web**: Edge functions return correct CORS headers (check [verify-secrets function](../supabase/functions/verify-secrets/index.ts))

### Build & Deployment
- **Web build size bloated**: Run `flutter build web --release` with `--tree-shake-icons`
- **Hot reload doesn't work**: Cold restart with `flutter clean && flutter run -d chrome`
- **Offline mode showing stale data**: Check `offline_service.dart` sync logic
