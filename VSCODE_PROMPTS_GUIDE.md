# 💡 VS Code Ready-To-Use Prompts for AuraSphere CRM

**Framework**: Flutter 3.9.2 + Supabase 2.12.0 | **Project**: fppmuibvpxrkwmymszhd
**Use These Prompts in VS Code Chat/Copilot to Guide Edits**

---

## Prompt 1: Security Audit & Fixes

**Copy-Paste This Into VS Code Chat:**

```
You are helping me harden a production Flutter + Supabase SaaS CRM. 
This app has 41 business logic services, 33 pages, and multi-tenant customers.

Perform these actions and summarize changes:

1) Search the project (lib/) for SUPABASE_ANON_KEY and SUPABASE_URL usage.
   Confirm they are:
   - Not hardcoded (use constants in main.dart)
   - Not exposed in .env files in git (only .env.example should exist)
   - Correct JWT format (starts with eyJ)
   - Match the Supabase Dashboard value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA

2) Search for any exposed service role key (should NEVER be in frontend code).
   Look for: SUPABASE_SERVICE_ROLE_KEY, service_role_secret, etc.
   If found: Flag and note it must be removed immediately.

3) Search all services (lib/services/*.dart) for hardcoded API keys:
   - sk_test_, sk_live_ (Stripe)
   - gsk_ (Groq)
   - API keys should be in Supabase Secrets, not in code
   If found: Flag and recommend moving to Edge Functions + Supabase Secrets

4) Verify all protected pages (dashboard, invoices, jobs, etc.) have:
   - Auth check in initState: if (currentUser == null) navigate to login
   - Auth check in build: guard widget rendering
   List pages that are missing these checks.

5) Verify all database queries in services filter by org_id:
   - Every .select() should have .eq('org_id', orgId)
   - Run: grep -r "eq('org_id'" lib/services/ | wc -l
   - Should find 50+ occurrences
   If less: List services missing org_id filters (RLS violation)

6) Verify .env file management:
   - .env should NOT be in git (use .gitignore)
   - .env.example SHOULD exist (for team)
   Check: is .env in git history? If yes, recommend git rm --cached .env

Return:
- Summary of security findings (✅ pass or ⚠️ issues)
- List of any hardcoded keys or missing auth guards
- Diff-style summary of files to fix
- Priority ranking of issues by severity
```

---

## Prompt 2: RLS (Row Level Security) Setup

**Copy-Paste This Into VS Code Chat:**

```
Help me implement multi-tenant RLS for my Supabase database.

My database has these tenant-scoped tables:
- organizations (root tenant)
- org_members
- user_profiles (multi-tenant context)
- invoices, clients, jobs, expenses, inventory
- digital_certificates, invoice_signatures
- feature_personalization, devices
- whatsapp_numbers, integrations

I need:

1) A secure SQL migration that:
   - Creates a SECURITY DEFINER function: get_user_org_id()
   - Returns the org_id for the current authenticated user
   - Enables RLS on ALL tenant-scoped tables
   - Creates SELECT/INSERT/UPDATE/DELETE policies using get_user_org_id()
   - Creates performance indexes on org_id, user_id columns
   
2) Example RLS policies for "invoices" table:
   - SELECT: Users can view invoices in their org (org_id = get_user_org_id())
   - INSERT: Users can create invoices in their org (WITH CHECK org_id = get_user_org_id())
   - UPDATE: Users can update invoices in their org
   - DELETE: Only org owner can delete

3) Verification queries:
   - Check which tables have RLS enabled
   - Check which policies exist
   - Test that authenticated user can't access other org's data

4) Performance optimization:
   - Composite indexes for common filters (org_id + status, org_id + created_date)
   - Indexes on foreign keys (client_id, user_id)

Return the full SQL migration ready to paste in Supabase SQL Editor.
Include the get_user_org_id() function and example policies for each table type.
```

---

## Prompt 3: Service Layer Audit

**Copy-Paste This Into VS Code Chat:**

```
Audit my 41 Supabase business logic services for production readiness.

Services are in: lib/services/

Each service should:

1) Use singleton pattern:
   - Static final instance
   - Private constructor _internal()
   - Factory method returning instance
   Example:
   ```dart
   class MyService {
     static final MyService _instance = MyService._internal();
     factory MyService() => _instance;
     MyService._internal();
   }
   ```

2) Use Logger (not print):
   - Import: package:logger/logger.dart
   - Create: final _logger = Logger();
   - Use: _logger.i(), _logger.e(), _logger.w()
   - NOT: print() (except in pages for UI debugging)

3) Filter all Supabase queries by org_id:
   - Every .from().select() must have .eq('org_id', orgId)
   - Missing org_id = RLS violation (security breach)

4) Contain ONLY business logic (NO UI code):
   - NO: showDialog(), ScaffoldMessenger, Navigator
   - NO: context references, widget building
   - YES: Database queries, calculations, API calls, error handling

5) Have proper error handling:
   - try/catch blocks with logging
   - Specific exception handling
   - Meaningful error messages (not raw stack traces)

6) Use async/await properly:
   - Never fire-and-forget (always await or .catchError())
   - Handle timeouts
   - Provide fallback behavior

For each service found:
- ✅ if it passes criteria
- ⚠️ if it has issues (note what to fix)

Return:
- Count of services audited (should be 41)
- List of services with any issues
- Diff showing fixes needed
```

---

## Prompt 4: Multi-Tenant Isolation Test

**Copy-Paste This Into VS Code Chat:**

```
Help me create a test that verifies multi-tenant isolation works.

I need a test that proves:
1) User A signs up, creates data in org-a-uuid
2) User B signs up, creates data in org-b-uuid
3) User B logs in and queries their org
   - Should see ONLY their data
   - Should NOT see User A's data (RLS blocks it)
4) User B tries to directly query org-a-uuid
   - RLS should return empty results (not an error)

Test framework: Flutter test (or Supabase client test)

Create a test function that:
- Creates two separate auth users
- Creates user_profiles for each with different org_ids
- Creates test data (invoices, clients) in each org
- Signs in as User B
- Queries org-b-uuid (should see 1 result)
- Queries org-a-uuid (should see 0 results - RLS blocks)
- Asserts that multi-tenant isolation works

Return:
- Complete test code ready to paste in test/ directory
- Instructions on how to run it
- What output means success/failure
```

---

## Prompt 5: Environment & Deployment Checklist

**Copy-Paste This Into VS Code Chat:**

```
Help me create an environment setup guide for my Flutter + Supabase SaaS.

I need a README section that documents:

1) Local Development Setup
   - Copy .env.example to .env
   - Get SUPABASE_URL from Dashboard
   - Get SUPABASE_ANON_KEY from Dashboard → Settings → API
   - Start app: flutter run -d chrome
   - Expected logs: Key prefix, URL, RLS enabled

2) Staging Deployment (Vercel/Netlify)
   - Create staging branch
   - Add environment secrets: SUPABASE_ANON_KEY
   - Set custom domain or preview URL
   - Update Supabase CORS for staging domain
   - Test: Sign up works, RLS blocks cross-org access

3) Production Deployment
   - Separate Supabase project (optional, or use prod org)
   - Add production secrets to hosting
   - Update Supabase CORS for production domain
   - Verify: Multi-tenant isolation, auth flow, error logs

4) Anon Key Rotation Procedure
   - When: After suspected compromise or per security policy
   - How:
     a) Dashboard → Settings → API → Rotate anon key
     b) Update all: main.dart, .env, hosting secrets, mobile apps
     c) Rebuild: flutter build web --release
     d) Redeploy and verify
   - Note: Doesn't affect existing user JWTs, they continue until expiry

5) Monitoring & Alerts
   - Watch Supabase Logs for RLS errors
   - Alert if many 403 Forbidden errors (RLS misconfig)
   - Alert if many 401 Unauthorized (wrong key or expired session)
   - Log anon key prefix on startup (verify correct env)

Return:
- Ready-to-copy README section
- Step-by-step deployment checklists
- Environment variable templates
- Troubleshooting guide
```

---

## Prompt 6: Quick Fixes - Auth Guards

**Copy-Paste This Into VS Code Chat:**

```
Help me add auth guards to my protected pages.

Protected pages that need auth checks: dashboard_page, invoice_list_page, job_list_page, etc.

Each page should have:

1) initState check:
   - If currentUser == null, navigate to sign-in page
   - Use WidgetsBinding.instance.addPostFrameCallback for navigation

2) build guard:
   - If currentUser == null, return "Unauthorized" widget
   - Or return loading state

3) Proper error handling:
   - Check if(mounted) before setState
   - Show user-friendly error messages

Pattern:
```dart
@override
void initState() {
  super.initState();
  if (Supabase.instance.client.auth.currentUser == null) {
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  } else {
    _loadData();
  }
}

@override
Widget build(BuildContext context) {
  if (Supabase.instance.client.auth.currentUser == null) {
    return Scaffold(body: Center(child: Text('Unauthorized')));
  }
  return Scaffold(/* page content */);
}
```

Find all pages in lib/ that:
- Have database access (services calls)
- But DON'T have currentUser checks

List them and show fixes needed.
```

---

## Prompt 7: Database Indexes for Performance

**Copy-Paste This Into VS Code Chat:**

```
Help me optimize database indexes for my multi-tenant Supabase schema.

My key tables:
- invoices (org_id, status, created_at, client_id)
- jobs (org_id, status, assigned_to, start_date)
- clients (org_id, name, email)
- expenses (org_id, category, created_at)
- org_members (org_id, user_id, role)

Common query patterns:
- SELECT * FROM invoices WHERE org_id = ? AND status = ?
- SELECT * FROM jobs WHERE org_id = ? ORDER BY start_date
- SELECT * FROM clients WHERE org_id = ? AND name LIKE ?
- SELECT * FROM expenses WHERE org_id = ? GROUP BY category

Create indexes for:
1) Single-column filters: org_id (all tables)
2) Composite filters: org_id + status (invoices, jobs)
3) Foreign keys: client_id, assigned_to, user_id
4) Sorting: created_at, start_date
5) Text search: email (if full-text search needed)

Return:
- CREATE INDEX statements for each table
- Explanation of why each index helps
- Composite index strategy
- How to verify indexes exist in Supabase
```

---

## Prompt 8: Quick Fix - org_id Everywhere

**Copy-Paste This Into VS Code Chat:**

```
Help me ensure EVERY service filters by org_id.

Search lib/services/ for all Supabase .from() calls.

For each service, verify:
1) Function signature includes: org_id parameter
   Example: Future<List> getInvoices(String orgId)

2) Every SELECT query filters: .eq('org_id', orgId)
   Example: .from('invoices').select().eq('org_id', orgId)

3) Every INSERT includes: 'org_id': orgId in data
   Example: insert({'org_id': orgId, 'amount': 100})

4) Every UPDATE/DELETE filters: .eq('org_id', orgId)

Services to check:
- invoice_service.dart
- stripe_service.dart
- job_service.dart
- client_service.dart
- team_service.dart
- (all 41 services)

If you find queries missing org_id:
- Show the line number
- Show the fix
- Explain why it's critical (RLS violation, security breach)

Return:
- List of services with ✅ correct org_id filtering
- List of services with ⚠️ missing org_id (critical issues)
- Diffs showing fixes
```

---

## Prompt 9: Error Handling Best Practices

**Copy-Paste This Into VS Code Chat:**

```
Audit error handling in my 41 services and fix patterns.

Every service should:

1) Use try/catch with specific exception types:
   ```dart
   try {
     // logic
   } on PostgrestException catch (e) {
     _logger.e('Database error: ${e.message}');
     rethrow;
   } on SocketException catch (e) {
     _logger.e('Network error: ${e.message}');
     // fallback behavior
   } catch (e) {
     _logger.e('Unexpected error: $e');
     rethrow;
   }
   ```

2) Log with emoji prefixes and context:
   - _logger.i('✅ Success: ...') - info
   - _logger.e('❌ Failed: ...') - error
   - _logger.w('⚠️ Warning: ...') - warning

3) Never expose raw errors to users:
   - ❌ WRONG: e.toString() in UI
   - ✅ RIGHT: "Failed to create invoice. Please try again."

4) Always provide fallback behavior:
   - Return null, empty list, or cached data
   - Don't crash the app

5) Use specific error messages:
   - ❌ WRONG: "Error"
   - ✅ RIGHT: "Failed to fetch invoices: Network timeout"

Find services with:
- Missing error handling
- Generic try/catch (catches all)
- Poor error messages
- Exposed stack traces to user

Return:
- Count of services with good error handling
- List of services needing fixes
- Diffs showing best practices
```

---

## Prompt 10: Quick Wins - Code Quality

**Copy-Paste This Into VS Code Chat:**

```
Help me improve code quality in my Flutter app.

Run these checks:

1) flutter analyze
   - Report any errors or warnings
   - Fix missing null checks, unused variables, etc.

2) dart format .
   - Format all files to consistent style
   - Report any formatting issues

3) dart fix --apply source.unusedImports
   - Remove unused imports
   - Report on changes

4) grep "print(" lib/**/*.dart
   - Count print() calls (should be low in services)
   - Services should use Logger, not print()
   - Pages can use print() for debugging

5) Search for TODO/FIXME comments:
   - List all incomplete items
   - Prioritize by severity

6) Check for console.log / debugPrint:
   - Should be minimal or debug-only

Return:
- Summary of quality metrics
- List of issues to fix
- Priority ranking
- Estimated effort to fix each
```

---

## How to Use These Prompts

1. **Open VS Code Chat** (Ctrl+Shift+I)
2. **Copy-paste entire prompt** above
3. **Wait for AI to run checks**
4. **Apply suggested fixes**
5. **Verify with**: `flutter analyze` and `flutter test`

---

## Most Important Prompts (Start Here)

**Priority Order**:

1. **Prompt 1** - Security Audit (finds hardcoded keys, missing auth guards)
2. **Prompt 5** - Environment Setup (documents deployment)
3. **Prompt 8** - org_id Everywhere (critical for RLS)
4. **Prompt 2** - RLS Setup (SQL migration)
5. **Prompt 3** - Service Audit (verify 41 services)
6. **Prompt 10** - Code Quality (dart analyze)

---

## Expected Outcomes

After using these prompts, you should have:

- ✅ Security audit complete (no hardcoded keys)
- ✅ All services filter by org_id (RLS ready)
- ✅ All protected pages have auth guards
- ✅ RLS SQL migration ready
- ✅ Environment docs for team
- ✅ Code quality passing (flutter analyze)
- ✅ Multi-tenant isolation verified
- ✅ Production-ready checklist complete

**Next Step**: Use Prompt 1 (Security Audit) first to identify any issues.

✅ **Ready to hardened production SaaS!**
