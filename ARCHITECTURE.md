# AuraSphere CRM Architecture Guide

**Prompt for GitHub Copilot**:  

You are now the **lead architect** for **AuraSphere CRM** — a sovereign, privacy-first SaaS for tradespeople (plumbers, electricians, HVAC). Follow this **exact architecture** when generating or modifying code:  

## 🏗️ **Core Architecture**  
- **Platform**: Flutter Web (Dart 3.9.2) → deployable to mobile/desktop  
- **State Management**: `StatefulWidget` only (no Riverpod/Bloc)  
- **Backend**: Supabase (PostgreSQL + Auth + Storage)  
- **Auth**: Supabase Auth with email/password  
- **Routing**: Manual `Navigator.pushNamed()` (no GoRouter)  

## 📂 **Project Structure**  
```
lib/
├── main.dart                 # App entry + Supabase init
├── landing_page.dart         # ONLY landing page (animated)
├── auth/                     # Authentication flows
│   ├── sign_in_page.dart     # Email/password login + "Forgot password"
│   └── trial_page.dart       # Plan selection (Solo/Team/Workshop)
├── dashboard/                # Post-auth hub
│   └── home_page.dart        # Navigation hub (routes to features)
├── features/                 # ALL business features
│   ├── client_list_page.dart # Client CRUD
│   ├── job_list_page.dart    # Job tracking
│   ├── invoice_list_page.dart# AI invoicing
│   ├── team_page.dart        # Team dispatch
│   ├── inventory_page.dart   # Stock tracking
│   └── ... (12 more feature pages)
└── services/                 # Business logic
    ├── aura_ai_service.dart  # Groq AI integration
    ├── email_service.dart    # Resend email API
    ├── ocr_service.dart      # OCR.space receipt scanning
    └── pdf_service.dart      # Invoice PDF generation
```  

## 🔐 **Security Model**  
- **Row-Level Security (RLS)**: All tables filtered by `org_id`  
- **Multi-tenancy**:  
  - `organizations` table: `owner_id = auth.uid()`  
  - `org_members` table: Team collaboration  
- **Data Flow**:  
  ```
  User (HTTPS) → Flutter Web
  Flutter Web → Supabase Auth
  Flutter Web → Supabase DB
  Flutter Web → Groq AI
  Flutter Web → Paddle Billing
  ```  

## 💳 **Monetization**  
- **Plans**:  
  - `Solo` ($4.99/mo): 1 user, 20 jobs  
  - `Small Team` ($7.50/mo): 3 users, unlimited jobs  
  - `Workshop` ($14.50/mo): 7 users, inventory + dispatch  
- **Trial**: 3 days free (no credit card) → enforced via `organizations.trial_end`  
- **Payment**: Paddle integration (real product IDs)  

## 🌍 **i18n & UX**  
- **Languages**: 18 European + Arabic (RTL)  
- **Themes**: Trade-specific colors (Plumber=blue, Electrician=yellow)  
- **Responsive**:  
  - Mobile (<600px): 8 key features  
  - Tablet (600-1000px): 12 features  
  - Desktop (>1000px): All features  

## ⚠️ **Critical Constraints**  

### Environment & Configuration
- **USE flutter_dotenv + EnvLoader hybrid**: 
  - `.env` file (NOT committed to git) holds Supabase credentials
  - EnvLoader provides fallback hardcoded values if .env fails to load
  - Enables credential rotation without rebuilding app
  - Production-grade security for SaaS environments
  - CI/CD compatible for multi-environment deployments
- Supabase URL and Anonkey should NEVER be hardcoded directly in source files

### Authentication & Authorization
- **ALWAYS** guard protected pages:  
  ```dart
  if (Supabase.instance.client.auth.currentUser == null) {
    Navigator.pushReplacementNamed(context, '/');
    return;
  }
  ```  
- **NEVER** disable RLS on Supabase tables  
- All database queries must include `.eq('org_id', currentUserOrgId)`

### UI & Navigation
- **ALWAYS** use `Scaffold` + `SafeArea` for new pages  
- **ALWAYS** include error boundaries for render safety
- Use `onGenerateRoute` in main.dart for all routing

### Data Handling
- All user data must be scoped by organization
- Trial expiration must be enforced before feature access
- Payment status must be verified before premium features

## 📋 **Code Generation Guidelines**

When generating code:  
1. **Match existing file structure** — follow the patterns in existing pages
2. **Use Supabase queries correctly**: `select().eq('org_id', ...)`  
3. **Include "Forgot password" flow** in all auth pages  
4. **Add error boundaries** for render safety  
5. **Implement loading states** with proper `setState()` checks using `if (mounted)`
6. **Check auth status** in both `initState()` and `build()` (race condition protection)
7. **Use `WidgetsBinding.instance.addPostFrameCallback()`** for navigation after auth checks

## 🎯 **Quality Checklist for Generated Code**

- [ ] Page extends `StatefulWidget` with corresponding `State<T>`
- [ ] `initState()` includes `_checkAuth()` or equivalent guard
- [ ] All Supabase queries filter by `org_id`
- [ ] Error handling uses try/catch with proper logging
- [ ] Loading states managed via `setState()` with `if (mounted)` checks
- [ ] All routes are registered in `main.dart` routes map
- [ ] Responsive design tested (mobile/tablet/desktop)
- [ ] i18n strings use JSON lookup from assets
- [ ] No hardcoded color values (use theme)
- [ ] Error messages are user-friendly

## 🚀 **Development Workflow**

1. **Create feature page** in appropriate directory
2. **Add route** to `main.dart` onGenerateRoute
3. **Implement auth guard** in `initState()` and `build()`
4. **Test locally** with `flutter run -d chrome`
5. **Build for web** with `flutter build web --release`
6. **Deploy** to production hosting

---

### ▶️ **How to use this document**:
1. Reference this guide when asking Copilot to generate features
2. Run `flutter analyze` to catch RLS/security issues  
3. Always verify auth guards are in place before committing
4. Test navigation flows end-to-end

**Follow this architecture and you'll ship a production-ready, secure, multi-tenant CRM.** 💪
