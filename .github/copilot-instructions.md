# AuraSphere CRM - AI Coding Agent Instructions

## Architecture Overview

**AuraSphere CRM** is a Flutter web/mobile app for tradespeople (electricians, plumbers, etc.) to manage jobs, invoices, clients, and teams. Built with Supabase backend and multi-language support (9 languages).

### Core Stack
- **Frontend**: Flutter (Dart) with Material Design 3
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Routing**: Named routes via `main.dart` (16 routes total)
- **State Management**: SetState-based (no Provider/Riverpod)
- **i18n**: Assets-based JSON files in `assets/i18n/`

### Key Components

**Entry Point** → `lib/main.dart` (735 lines)
- Initializes Supabase via `EnvLoader` (fallback hardcoded credentials for web)
- Defines all 16 routes and theme (ColorScheme with Electric Blue #007BFF)
- Error boundary with `ErrorFallbackApp` fallback

**Feature Pages** (15 pages in `/lib`)
- **Public**: `landing_page_animated.dart`, `pricing_page.dart`, `sign_in_page.dart`
- **Protected**: All others check `supabase.auth.currentUser` and redirect to `/` if null
- **Navigation Hub**: `HomePageNav` (bottom nav with 5 tabs) for authenticated users

**Services Layer** (`/lib/services/` - 12 files)
- `aura_ai_service.dart` - Groq LLM integration for command parsing (multi-language prompts)
- `invoice_service.dart`, `pdf_service.dart`, `email_service.dart` - Business logic
- `tax_service.dart` - 40+ country tax calculations
- `ocr_service.dart` - Receipt scanning (image → JSON via API)

**Core Infrastructure** (`/lib/core/`)
- `env_loader.dart` - Loads `.env` with fallback hardcoded values
- `app_theme.dart` - Dark theme (not used yet; main.dart has inline theme)

## Critical Development Patterns

### 1. **Auth Guards**
Every protected page checks auth in `initState()` + `build()`:
```dart
if (supabase.auth.currentUser == null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.pushReplacementNamed(context, '/');
  });
}
```
**Why double-check**: Race condition during hot reload. Always do both.

### 2. **Supabase Data Fetching**
```dart
final org = await supabase.from('organizations').select('id').single();
final data = await supabase.from('table_name').select('*').eq('user_id', userId);
```
- Never catch all exceptions silently (logs errors to console)
- Use `.select()` then `.single()` or `.maybeSingle()` for optional data
- Check `supabase.auth.currentUser!.id` for user_id field

### 3. **State Management** (SetState only - no Redux/BLoC)
```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool loading = true;
  List<Map<String, dynamic>> items = [];
  
  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      items = await supabase.from('items').select();
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);  // Check mounted!
    }
  }
}
```
**Key**: Always check `if (mounted)` before `setState()` in finally blocks.

### 4. **Internationalization**
- **9 languages**: EN, FR, IT, AR, MT, DE, ES, BG (assets in `assets/i18n/en.json`, etc.)
- **Usage**: Manual JSON lookup (no i18n package yet)
- **Future**: Implement `app_localizations.dart` for centralized i18n

### 5. **Feature Flags**
Pages check `user_preferences` table for boolean flags:
```dart
final prefs = await supabase.from('user_preferences')
    .select('features')
    .eq('user_id', userId)
    .maybeSingle();
final featureEnabled = prefs?['features']?['behavioral_onboarding'] == true;
```

## Workflow & Build Commands

### Development
```bash
flutter pub get              # Install dependencies
flutter run -d chrome        # Run on web (Chrome)
flutter analyze              # Lint check (uses analysis_options.yaml)
```

### Build & Deploy
```bash
flutter clean                           # Full rebuild
flutter build web --release             # Optimized bundle → build/web/
# Serve locally (for testing)
cd build/web && python -m http.server 8000
```

**Build Output**: Optimized ~12-15MB bundle in `build/web/`
**Deployment Options**: Vercel, Netlify, Firebase Hosting (drag & drop `build/web/`)

## Project-Specific Conventions

### File Naming
- Pages: `snake_case_page.dart` (e.g., `client_list_page.dart`)
- Services: `service_name_service.dart` (e.g., `invoice_service.dart`)

### Error Handling Pattern
```dart
try {
  // Logic
} catch (e) {
  print('❌ ERROR: $e');  // Always log with emoji prefix
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}'))
  );
} finally {
  if (mounted) setState(() => loading = false);
}
```

### Permission Model
- **Owner**: Can manage team, view all analytics, access admin settings
- **Technician**: Can only view assigned jobs (no billing access)
- **Solo Plan**: Only 1 user allowed
- **Team Plan**: Up to 3 users; Workshop Plan: 7 users
- **Check via**: `organizations.plan` + `organizations.owner_id` == `currentUser.id`

### Responsive Design Breakpoints
```dart
final screenWidth = MediaQuery.of(context).size.width;
final isMobile = screenWidth < 600;
final isTablet = screenWidth >= 600 && screenWidth < 1000;
```

## Database Schema Reference

Key tables:
- `organizations` - Multi-tenant root; fields: `id, owner_id, plan, name, stripe_status`
- `users` - Team members; fields: `id, org_id, email, role`
- `clients` - Customer records; fields: `id, org_id, name, phone, email`
- `invoices` - Billing; fields: `id, org_id, client_id, amount, status, due_date`
- `jobs` - Work items; fields: `id, org_id, status, assigned_to, start_date, materials_needed`
- `inventory` - Stock; fields: `id, org_id, item_name, quantity, low_stock_threshold`
- `expenses` - Cost tracking; fields: `id, org_id, amount, category, receipt_url`
- `user_preferences` - Feature flags; fields: `user_id, features (JSONB), onboarding_completed`

## AI Agent Tips

1. **Always reference file paths** when modifying code (helps debugging)
2. **Test auth flows** by clearing browser cache (removes session)
3. **Check `mounted` flag** before any `setState()` to prevent crashes
4. **Run `flutter analyze`** after major changes
5. **For new features**: Create in `lib/features/{feature}/` folder if module grows beyond 300 lines
6. **Error messages**: Use emoji prefixes (✅, ❌, ⚠️, 🔄) for console clarity
7. **When adding routes**: Update both the routes map in `main.dart` AND `HomePageNav` tab list
8. **Supabase RLS**: All queries assume RLS policies exist (org_id + auth.uid checks)
9. **Mock data**: No fixtures yet—use real Supabase dev project or SQL seeds from `database/jobs_schema.sql`
10. **Breaking changes**: Before modifying schemas, check dependent services (e.g., changing `invoices.amount` type affects `invoice_service.dart`)

