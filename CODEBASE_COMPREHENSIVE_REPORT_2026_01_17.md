# 📊 AuraSphere CRM - Comprehensive Codebase Report
**Date**: January 17, 2026  
**Status**: ✅ Production Ready  
**Last Update**: Owner Feature Control + Audit Logging deployed

---

## 📋 Executive Summary

AuraSphere is a **Flutter + Supabase multi-tenant SaaS CRM** for tradespeople with:
- **30+ feature pages** for jobs, invoices, clients, team management
- **43 business logic services** (singleton pattern, all in `/lib/services/`)
- **Strict architecture enforcement**: SetState-only, service layer isolation, RLS on every query
- **Advanced features**: AI agents (Groq), digital signatures (XAdES-B), prepayment codes, cloud expense tracking
- **Multi-language support**: 9 languages (en, fr, it, de, es, ar, mt, bg) via JSON i18n

---

## 🏗️ Architecture Overview

### **Core Technology Stack**
| Component | Technology | Version | Notes |
|-----------|-----------|---------|-------|
| **Frontend** | Flutter (Dart) | 3.9.2 | Web/Mobile/Tablet support |
| **Backend** | Supabase | 2.12.0 | PostgreSQL + Auth + Storage + Edge Functions |
| **State Management** | SetState-only | N/A | No Provider/Riverpod/BLoC |
| **Database** | PostgreSQL | N/A | Multi-tenant with RLS |
| **Authentication** | Supabase Auth | JWT | Multi-org support via JWT claims |
| **API Proxies** | Deno Edge Functions | N/A | Secure API key management |
| **Payments** | Stripe + Paddle | N/A | Via `stripe_payment_service.dart`, `paddle_payment_service.dart` |
| **AI/LLM** | Groq API | mixtral-8x7b | Via Edge Function proxy (never direct) |
| **Email** | Resend | N/A | Via `resend_email_service.dart` or `email_service.dart` |
| **Messaging** | WhatsApp (Twilio) | N/A | Via `whatsapp_service.dart` |

### **Critical Architectural Rules** (Non-Negotiable)

| Rule | Why | Violation Impact |
|------|-----|------------------|
| **Every query filters by `org_id`** | RLS enforcement | Security breach + silent failures |
| **Two-part auth checks** (initState + build) | Hot reload bypass prevention | Pages accessible without login |
| **`if (mounted)` before setState** | Prevent widget lifecycle errors | "setState after dispose" crashes |
| **NO API keys in code** | Security & compliance | Exposed credentials, account takeover |
| **Services = business logic ONLY** | Separation of concerns | Tangled code, hard to test, tight coupling |
| **Singleton pattern for services** | Single instance across app | Multiple instances cause state conflicts |

---

## 📂 Directory Structure & Responsibilities

```
aura_crm/
├── lib/
│   ├── main.dart                          # App entry, routes, auth guards
│   ├── *_page.dart (30+ files)            # UI pages, local state management
│   ├── services/ (43 files)               # Business logic, singletons
│   ├── widgets/                           # Reusable UI components
│   ├── theme/                             # Material Design 3 + custom colors
│   ├── core/                              # Auth helpers, env loader
│   ├── validators/                        # Input validation
│   └── features/                          # Feature-specific UI modules
├── supabase/
│   ├── migrations/ (20260111_*, etc)      # SQL schema changes
│   └── functions/ (Deno Edge Functions)   # API proxies, webhooks
├── assets/
│   └── i18n/                              # 9 language JSON files
├── pubspec.yaml                           # Flutter dependencies
└── README.md
```

---

## 🔑 Key Services (40+ files)

### **Core Business Logic**
| Service | Purpose | Key Methods |
|---------|---------|------------|
| `invoice_service.dart` | Invoice CRUD, payment reminders | `getInvoices()`, `sendReminders()`, `updateStatus()` |
| `recurring_invoice_service.dart` | Auto-billing setup | `createRecurringInvoice()`, `processSchedule()` |
| `job_service.dart` | Job management | `getJobs()`, `assignJob()`, `completeJob()` |
| `client_service.dart` | Client CRM | `getClients()`, `importLeads()`, `trackMetrics()` |
| `invoice_service.dart` | Core invoicing | Overdue reminders, payment tracking |
| `tax_service.dart` | 40+ country tax rates | `calculateTax()`, `getSupportedCountries()` |
| `digital_signature_service.dart` | XAdES-B invoice signing | `signInvoice()`, `validateSignature()` |

### **AI & Automation**
| Service | Purpose | Key Methods |
|---------|---------|------------|
| `aura_ai_service.dart` | Groq LLM command parsing | `parseCommand()`, `executeAiAction()` |
| `autonomous_ai_agents_service.dart` | CEO/COO/CFO agents | Auto job completion, lead scoring, budget optimization |
| `lead_agent_service.dart` | Lead follow-up automation | `getFlaggedLeads()`, `sendFollowUp()` |
| `supplier_ai_agent.dart` | Cost optimization | `detectWaste()`, `suggestOptimization()` |
| `waste_detection_service.dart` | Cloud cost analysis | `scanExpenses()`, `reportFindings()` |

### **Payments & Subscriptions**
| Service | Purpose | Status |
|---------|---------|--------|
| `stripe_payment_service.dart` | ✅ **USE THIS** | Stripe payments via Edge Function proxy |
| `stripe_service.dart` | ❌ **DEPRECATED** | Contains invalid hardcoded keys - DO NOT USE |
| `paddle_payment_service.dart` | ✅ **USE THIS** | Paddle payments via Edge Function proxy |
| `paddle_service.dart` | ❌ **DEPRECATED** | Legacy implementation |
| `trial_service.dart` | Trial lifecycle, expiry tracking | Trial creation, reminder logic, upsell |
| `prepayment_code_service.dart` | Prepaid codes (African markets) | Code redemption, activation |

### **Feature Control & Device Management**
| Service | Purpose | NEW Features |
|---------|---------|--------------|
| `feature_personalization_service.dart` | User feature preferences | ✅ **Owner control layer added Jan 17** |
| `device_management_service.dart` | Mobile/tablet registration | Device limits by subscription tier |
| `feature_personalization_helper.dart` | Mobile/tablet helpers | Feature limit validation |

**NEW Owner Control Methods** (Jan 17, 2026):
```dart
service.forceEnableAllFeaturesOnDevice()     // Override user prefs on specific device
service.disableFeaturesOnDevice()             // Granular feature disabling
service.lockFeaturesOrgWide()                 // Compliance-wide feature lock
service.getFeatureAuditLog()                  // View all feature changes
service.getOwnerControlStatus()               // Check enforcement status
```

### **Integrations**
| Service | Purpose | Key Methods |
|---------|---------|------------|
| `whatsapp_service.dart` | WhatsApp messaging | `sendMessage()`, `uploadMedia()` |
| `integration_service.dart` | HubSpot, Slack, Zapier | `syncHubSpot()`, `notifySlack()` |
| `quickbooks_service.dart` | QuickBooks sync | `syncInvoices()`, `syncExpenses()` |
| `email_service.dart` | Email via Resend | `sendEmail()` with templating |
| `resend_email_service.dart` | **Alternative** email service | Backup email provider |

### **Infrastructure & Utilities**
| Service | Purpose | 
|---------|---------|
| `realtime_service.dart` | Supabase subscriptions, presence | Live job/invoice updates, team activity |
| `notification_service.dart` | In-app + email notifications | Preference management, delivery tracking |
| `backup_service.dart` | Scheduled org backups | Cold storage archival |
| `reporting_service.dart` | Custom reports + export | Data analytics, PDF generation |
| `rate_limit_service.dart` | API throttling + cost control | Prevent runaway API costs |
| `backend_api_proxy.dart` | Middleware for secure API calls | Pattern example for Edge Functions |
| `aura_security.dart` | PKI key rotation, encryption | Security infrastructure |
| `offline_service.dart` | Cached data + sync on reconnect | Works without internet |
| `whitelabel_service.dart` | Tenant branding customization | Multi-tenant theming |
| `cloud_expense_service.dart` | AWS/Azure/GCP cost tracking | CloudGuard integration |
| `ocr_service.dart` | Receipt image → JSON | Via Edge Function OCR proxy |
| `pdf_service.dart` | Invoice PDF generation | Templating + branding support |

---

## 📊 Database Schema (Latest)

### **Multi-Tenant Core**
```sql
organizations           # Root tenant (id, owner_id, plan, stripe_status)
org_members            # Team members (org_id, user_id, role, email)
user_profiles          # User metadata (auth_user_id, org_id, language)
```

### **Business Data** (all have `org_id` + RLS)
```sql
clients                # Customer records
invoices               # Billing records (status tracking, payment links)
jobs                   # Work orders (assignments, scheduling)
expenses               # Cost tracking (receipts, categories)
inventory              # Stock management (low stock alerts)
whatsapp_numbers       # Org phone accounts
integrations           # Third-party credentials (Stripe, HubSpot, etc)
```

### **Feature Control** (NEW Jan 11, 2026)
```sql
feature_personalization        # User feature preferences per device
feature_audit_log              # Owner control audit trail (NEW)
devices                        # Mobile/tablet registration
feature_personalization_audit  # Feature change tracking (trigger-based)
```

### **Advanced Features**
```sql
digital_certificates          # X.509 for XAdES-B signing
invoice_signatures             # Signed invoices with XAdES XML
trial_management               # Trial tracking with expiry
subscriptions                  # Subscription with discounts
pricing_plans                  # Plan definitions (features, pricing)
trial_reminders                # Auto-reminder schedule
trial_usage                    # Feature access tracking per trial
prepayment_codes               # Offline payment codes (54 countries)
prepayment_code_audit          # Code redemption history
cloud_connections              # AWS/Azure/GCP auth
cloud_expenses                 # Cloud infrastructure costs
waste_findings                 # Cost optimization discoveries
partner_accounts               # Partner integrations
partner_resources              # Learning materials
partner_commissions            # Revenue tracking
```

### **RLS Enforcement**
- **Every table** has RLS enabled
- **Queries without `org_id`** = silent failure (0 rows returned)
- **Cross-org access attempts** = RLS blocks at DB layer
- **Service role** can bypass for batch operations (backend only)

---

## 🛣️ Routes & Navigation

All routes defined in `lib/main.dart`:

```dart
routes: {
  '/': LandingPageAnimated,
  '/sign-in': SignInPage,
  '/sign-up': SignUpPage,
  '/forgot-password': ForgotPasswordPage,
  '/dashboard': DashboardPage,  // Auth protected
  '/home': HomePage,             // Auth protected
  '/invoice-list': InvoiceListPage,
  '/job-list': JobListPage,
  '/client-list': ClientListPage,
  '/team': TeamPage,
  '/dispatch': DispatchPage,
  '/cloudguard': CloudGuardPage,       // NEW Jan 15
  '/partner-portal': PartnerPortalPage, // NEW Jan 15
  '/suppliers': SupplierManagementPage, // NEW Jan 15
  // ... 20+ more
}
```

Protected routes checked in `onGenerateRoute()`:
```dart
if (isProtectedRoute && auth.currentUser == null) {
  return MaterialPageRoute(builder: (_) => SignInPage());
}
```

---

## 🔐 Security Architecture

### **Multi-Tenancy**
1. **JWT Claims**: User's `org_id` stored in Supabase JWT
2. **RLS Policies**: Filter by `org_id` at database layer
3. **Every query**: Must include `.eq('org_id', currentOrgId)`
4. **No cross-org access**: RLS policies prevent it even with direct attempts

### **API Key Management**
| API | Storage | Access | Method |
|-----|---------|--------|--------|
| Stripe | Supabase Secrets | Edge Function only | `stripe-proxy` function |
| Paddle | Supabase Secrets | Edge Function only | `paddle-proxy` function |
| Groq LLM | Supabase Secrets | Edge Function only | `groq-proxy` or `supplier-ai-agent` |
| Resend Email | Supabase Secrets | Edge Function only | `send-email` function |
| OCR | Supabase Secrets | Edge Function only | `scan-receipt` function |
| **NEVER in Flutter** | ✅ Best practice | ✅ Secure | ✅ Compliant |

### **Feature Control & Audit**
- Owners can **lock features org-wide** for compliance
- All changes logged in **`feature_audit_log`** with timestamp, performer, details
- **Immutable audit trail** (can view, not edit)
- **RLS**: Only org owner can view their audit logs

---

## 📱 Page Lifecycle Pattern

Every page follows this structure (see `invoice_list_page.dart`, `dashboard_page.dart`):

```dart
class MyPage extends StatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> items = [];
  
  @override
  void initState() {
    super.initState();
    _checkAuth();              // ✅ Check auth FIRST
    _loadData();               // ✅ Then load data
    _setupRealtimeListeners(); // ✅ Optional: setup real-time
  }
  
  @override
  void dispose() {
    RealtimeService().unsubscribeAll(); // Clean up subscriptions
    super.dispose();
  }
  
  Future<void> _checkAuth() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }
  
  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      items = await supabase
          .from('invoices')
          .select()
          .eq('org_id', orgId)        // ✅ ALWAYS filter by org_id
          .eq('status', 'sent')
          .order('due_date');
    } catch (e) {
      print('❌ Error loading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ${e.toString().split('\n').first}')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false); // ✅ Check mounted
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentUser == null) {
      return Scaffold(body: Center(child: Text('Unauthorized')));
    }
    
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Items')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Items')),
        body: const Center(child: Text('No items yet')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Items')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) => ListTile(title: Text(items[i]['name'])),
      ),
    );
  }
}
```

**Key Rules**:
1. `initState` order: Auth → Data → Real-time
2. Always `if (mounted)` before setState in catch/finally
3. Local state only (no global managers)
4. Clean up listeners in `dispose()`

---

## 🧠 Service Singleton Pattern

All services use lazy singleton with private constructor:

```dart
final _logger = Logger();

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  final supabase = Supabase.instance.client;
  
  InvoiceService._internal();  // Private constructor
  
  factory InvoiceService() => _instance;  // Always returns same instance
  
  Future<void> sendReminders() async {
    _logger.i('🔄 Sending reminders...');
    try {
      // Business logic
    } catch (e) {
      _logger.e('Failed: $e');
      rethrow;
    }
  }
}

// Usage: InvoiceService().sendReminders() - always same instance
```

---

## 🌐 API Proxying via Edge Functions

**Pattern**: Never expose API keys to frontend. Always use Edge Functions.

```dart
// ✅ CORRECT: Flutter calls Edge Function (key hidden in Supabase Secrets)
final result = await supabase.functions.invoke(
  'groq-proxy',
  body: {'message': userInput, 'language': 'en'},
);

// ❌ WRONG: API key exposed to reverse-engineers
const groqKey = 'gsk_...';
final response = await http.post(..., headers: {'Authorization': 'Bearer $groqKey'});
```

**Edge Function Structure** (Deno):
```typescript
// supabase/functions/groq-proxy/index.ts
const groqKey = Deno.env.get('GROQ_API_KEY');  // From Supabase Secrets

export const handler = async (req: Request) => {
  const { message, language } = await req.json();
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${groqKey}` },
    body: JSON.stringify({ messages: [{ role: 'user', content: message }] }),
  });
  return new Response(await response.text());
};
```

**Available Proxy Functions**:
- `groq-proxy` - Groq LLM
- `stripe-proxy` - Stripe payments
- `paddle-proxy` - Paddle payments
- `send-email` - Resend email
- `scan-receipt` - OCR
- `send-whatsapp` - WhatsApp messages

---

## 🔄 Real-Time Updates (Optional)

Real-time is **optional** - app works without it. Used for auto-refresh when team members make changes.

```dart
void _setupRealtimeListeners() {
  try {
    print('📡 Setting up real-time listeners');
    
    // Listen for invoice changes
    RealtimeService().listenToInvoices(orgId, (data, action) {
      print('✅ Invoice ${action}: ${data['id']}');
      if (mounted) setState(() { invoices = [...invoices]; });
    });
    
  } catch (e) {
    print('⚠️ Real-time failed (non-critical): $e');
    // Real-time is optional; fail gracefully
  }
}

@override
void dispose() {
  RealtimeService().unsubscribeAll();
  super.dispose();
}
```

---

## 🎨 Theme & Styling

All design uses `ModernTheme` from `lib/theme/modern_theme.dart`:

```dart
Color primaryBlue = ModernTheme.electricBlue;        // #007BFF (enforced)
Color secondaryGreen = ModernTheme.secondaryGreen;   // #BFFF00
TextStyle heading = ModernTheme.headline3;           // Manrope font
List<BoxShadow> shadow = ModernTheme.cardShadow;     // Drop shadow

Container(
  decoration: BoxDecoration(
    color: ModernTheme.cardWhite,
    boxShadow: ModernTheme.cardShadow,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text('Hello', style: ModernTheme.headline4),
)
```

**Color Tokens**:
- Primary: `#007BFF` (Electric Blue)
- Secondary: `#BFFF00` (Green-Yellow)
- Fonts: Manrope (headlines), system (body)
- Shadows: Card, Glassmorphism, Hover variants

---

## 🌍 Internationalization (i18n)

Manual JSON-based i18n with 9 languages:

```dart
// Load locale JSON
final jsonString = await rootBundle.loadString('assets/i18n/$languageCode.json');
final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

// Access translations
final greeting = jsonData['greeting'] ?? 'Hello';
final welcome = jsonData['dashboard']?['welcome'] ?? 'Welcome';
```

**Supported Languages**: en, fr, it, de, es, ar, mt, bg

**Files**: `assets/i18n/{languageCode}.json`

**Storage**: User language stored in `user_preferences.language`

---

## 🚀 Developer Workflows

### **Local Development**
```bash
# Install dependencies
flutter pub get

# Run on Chrome (web) with hot reload
flutter run -d chrome

# Hot reload shortcuts
r                    # Hot reload (quick)
R                    # Full restart (slower)
q                    # Quit app
```

### **Code Quality**
```bash
# Lint check (uses analysis_options.yaml)
flutter analyze

# Auto-fix formatting + common issues
dart fix --apply

# Format all Dart files
flutter format .

# Check for unused imports
dart fix --apply source.unusedImports
```

### **Build & Deploy**
```bash
# Clean build for web (release mode, optimized)
flutter clean && flutter build web --release

# With icon tree-shaking for smaller bundle
flutter build web --release --tree-shake-icons

# Local web server
cd build/web && python -m http.server 8000
# Visit http://localhost:8000
```

### **Testing**
```bash
# Unit tests
flutter test

# Specific test file
flutter test test/services/invoice_service_test.dart

# Coverage report
flutter test --coverage
```

---

## 🔍 Debugging Tips

### **Common Issues**

| Issue | Root Cause | Solution |
|-------|-----------|----------|
| Page shows "Unauthorized" then redirects | Missing `initState` or `build` check | Add both auth checks per pattern |
| Hot reload loses session | Non-blocking auth check needed | Use `AuthGate` pattern in main.dart |
| "setState after dispose" crash | Missing `if (mounted)` check | Always check before setState in catch/finally |
| Supabase query returns empty | Missing `org_id` filter | RLS blocks queries without org_id |
| "relation does not exist" error | RLS policy references missing table | Run complete schema migration |
| Web build size bloated | Assets not tree-shaken | Use `--tree-shake-icons` flag |
| Hot reload doesn't work | Dart VM cache stale | Run `flutter clean && flutter run -d chrome` |
| Offline mode shows stale data | Sync logic error | Check `offline_service.dart` reconciliation |

---

## 📈 Deployment Checklist

- [ ] Code quality: `flutter analyze` (0 errors)
- [ ] Tests pass: `flutter test`
- [ ] Build succeeds: `flutter build web --release`
- [ ] All routes registered in `main.dart`
- [ ] Auth guards on protected routes
- [ ] Database migrations applied (`supabase db push`)
- [ ] RLS policies verified on all tables
- [ ] Edge Functions deployed (`supabase functions deploy`)
- [ ] API keys in Supabase Secrets (not code)
- [ ] Stripe/Paddle webhook endpoints configured
- [ ] Email templates tested
- [ ] i18n files complete for all 9 languages

---

## 📚 Key Files Reference

| File | Purpose | Key Patterns |
|------|---------|-------------|
| `lib/main.dart` | App setup, routes, auth | Route definitions, auth guards |
| `lib/services/*.dart` | Business logic | Singleton pattern, Logger, Supabase queries with org_id |
| `lib/*_page.dart` | UI + local state | Two-part auth checks, setState lifecycle, mounted checks |
| `lib/theme/modern_theme.dart` | Design tokens | Colors, fonts, shadows |
| `supabase/migrations/*.sql` | Schema versions | RLS policies, constraints |
| `supabase/functions/*/index.ts` | API proxies | Deno, Supabase secrets, request/response handling |
| `assets/i18n/*.json` | Translations | One file per language, nested keys |
| `pubspec.yaml` | Dependencies | supabase_flutter 2.12.0, logger, http |

---

## ✅ Summary

**AuraSphere CRM** is a **production-ready Flutter + Supabase SaaS** with:
- ✅ Multi-tenant architecture (RLS on every query)
- ✅ 40+ services with singleton pattern
- ✅ Strict state management (SetState-only)
- ✅ Secure API key management (Edge Functions)
- ✅ Advanced features (AI agents, digital signatures, prepayment codes)
- ✅ Owner feature control with audit logging (NEW Jan 17)
- ✅ CloudGuard + Partner Portal (NEW Jan 15)
- ✅ Complete trial/subscription system
- ✅ 9-language i18n support
- ✅ Comprehensive test coverage framework

**Next priorities**:
1. Deploy CloudGuard waste detection on production
2. Enhance AI agent autonomy (lead scoring, budget optimization)
3. Expand prepayment code regions beyond African markets
4. Implement advanced analytics in Partner Portal
5. Complete digital signature integration for enterprise clients

---

**Generated**: January 17, 2026  
**For**: AI Coding Agents  
**Reference**: `.github/copilot-instructions.md`
