# AuraSphere CRM - AI Coding Agent Instructions

## Architecture Overview

**AuraSphere CRM** is a Flutter web/mobile app for tradespeople to manage jobs, invoices, clients, and teams. Multi-tenant SaaS with Supabase backend, 9-language i18n, and extensive integrations (Stripe, Paddle, WhatsApp, QuickBooks, HubSpot, Slack).

### Core Stack
- **Frontend**: Flutter (Dart) with Material Design 3 + seeded colors from `#007BFF` (Electric Blue)
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **State Management**: SetState-only (no Provider/Riverpod/BLoC)
- **Routing**: 30+ named routes in [lib/main.dart](../lib/main.dart#L70-L105)
- **i18n**: Manual JSON lookup in `assets/i18n/{en,fr,it,de,es,ar,mt,bg}.json`

### Key Directories
- `/lib/services/` (35 files) - Business logic, API integrations, AI/automation
- `/lib/` - Pages & widgets; one file per route
- `/lib/features/` - Modular features (clients, suppliers); legacy location
- `/lib/theme/` - Custom components (`ModernButton`, `ModernCard`, `ModernPageTransition`)
- `/lib/core/` - Auth helper, env loader, app theme config
- `/lib/widgets/` - Reusable widgets (trial banner, etc.)
- `/lib/validators/` - Input validation helpers
- `/supabase/` - Edge Functions (Groq AI, WhatsApp, payment webhooks)

### Critical Data Flows

1. **Multi-tenant Auth**: All queries filter by `org_id` + `auth.uid` (RLS enforced)
2. **AI Command Pipeline**: User input → `AuraAiService.parseCommand()` → Groq via Edge Function → Action dispatch
3. **Subscription Lifecycle**: Trial → Paddle/Stripe payment → org plan update → feature access control
4. **Automation**: Services run on schedule (backend) or via user triggers; NO cron in frontend

## Essential Patterns

### Auth Guard Pattern (Every Protected Page)
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
Use emoji prefixes for console clarity:
- `print('✅ Success: ...')` - Expected outcome
- `print('❌ ERROR: $e')` - Recoverable error
- `print('⚠️ Warning: ...')` - Unexpected but harmless
- `print('🔄 Processing: ...')` - Async work in progress
- `print('🤖 AI: ...')` - AI/LLM calls
- `print('📧 Email: ...')` - Notifications
- `print('💳 Payment: ...')` - Financial transactions

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

## Services Architecture (35+ files)

### Core Business Logic
- `invoice_service.dart` - Overdue reminders, payment status tracking
- `tax_service.dart` - 40+ country tax rates + calculation
- `ocr_service.dart` - Receipt image → JSON extraction
- `pdf_service.dart` - Invoice PDF generation + templating

### Payment & Subscriptions
- `stripe_service.dart` - Stripe checkout, invoice sync, webhook handling
- `paddle_service.dart`, `paddle_payment_service.dart` - Paddle integration
- `trial_service.dart` - Trial creation, expiry tracking, upsell logic
- `prepayment_code_service.dart` - Prepaid code redemption (gift cards)

### AI & Automation
- `aura_ai_service.dart` - Groq LLM command parsing (SECURE: via Edge Function only)
- `ai_automation_service.dart` - Budget alerts, rate limiting, cost tracking
- `autonomous_ai_agents_service.dart` - Auto job completion, lead scoring
- `lead_agent_service.dart` - Follow-up reminders, cold lead flagging
- `supplier_ai_agent.dart` - Supplier cost optimization
- `marketing_automation_service.dart` - Email campaigns, engagement tracking

### Integrations
- `whatsapp_service.dart` - Message dispatch, media upload, delivery logs
- `integration_service.dart` - HubSpot deals, Slack notifications, Zapier webhooks, Google Calendar sync, QuickBooks sync
- `email_service.dart`, `resend_email_service.dart` - Email via Resend
- `quickbooks_service.dart` - OAuth + invoice/expense sync

### Infrastructure
- `realtime_service.dart` - Supabase subscriptions (presence, live updates)
- `notification_service.dart` - In-app + email notifications, preference management
- `backup_service.dart` - Scheduled org backups to cold storage
- `reporting_service.dart` - Custom reports + data export
- `rate_limit_service.dart` - API throttling + cost control
- `backend_api_proxy.dart` - Middleware for secure API calls
- `aura_security.dart` - PKI key rotation, encryption
- `offline_service.dart` - Cached data + sync on reconnect
- `whitelabel_service.dart` - White-label tenant customization

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
All routes defined in [lib/main.dart](../lib/main.dart#L70-L105). When adding new page:
1. Import page class at top of main.dart
2. Add to `routes` map with path
3. Add to bottom nav in `HomePageNav` if needed
4. Protect with auth check in `onGenerateRoute`

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
```dart
final width = MediaQuery.of(context).size.width;
final isMobile = width < 600;
final isTablet = width >= 600 && width < 1200;
final isDesktop = width >= 1200;
```

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

## AI Agent Tips

1. **API Keys**: NEVER hardcode. All keys stored in Supabase Secrets → Edge Functions. Frontend calls Edge Function, not API.
2. **Multi-tenancy**: Always filter queries by `org_id`. RLS policies assume this. Missing it = security breach.
3. **Mounted checks**: Before setState in catch/finally blocks; prevents "setState after dispose" crashes.
4. **Supabase errors**: Never silently catch. Log with emoji, show user-facing message, then optionally rethrow.
5. **New routes**: Update [lib/main.dart](../lib/main.dart), import page, add to routes map, add auth check.
6. **Feature flags**: Check `user_preferences.features` before expensive operations.
7. **Breaking changes**: Touching schema → audit `invoice_service.dart`, `trial_service.dart`, `integration_service.dart` for impacts.
8. **Offline state**: Check `Supabase.instance.client.auth.currentUser` (null = disconnected or logged out).
9. **Tests**: No test fixtures yet; use real Supabase dev project or SQL seeds from `database/jobs_schema.sql`.
10. **Logging**: Use emoji prefixes in ALL prints; grep for them during debugging (e.g., `grep "❌" app.log`).
