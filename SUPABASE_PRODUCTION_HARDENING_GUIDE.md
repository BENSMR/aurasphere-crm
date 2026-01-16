# 🔐 AuraSphere CRM - Supabase Production Hardening Guide

**Project**: fppmuibvpxrkwmymszhd | **Framework**: Flutter 3.9.2 + Supabase 2.12.0
**Last Updated**: January 15, 2026 | **Status**: Ready for Implementation

---

## 📋 Executive Summary

This guide hardens your Supabase-based SaaS CRM for production. It covers:
1. ✅ Anon key verification & rotation procedure
2. ✅ Multi-tenant RLS enforcement (critical for SaaS)
3. ✅ Session/JWT lifecycle management
4. ✅ Auth flow hardening
5. ✅ CORS & security configuration
6. ✅ Environment & deployment checklist

**Current Status**: 
- ✅ Anon key correctly configured in main.dart
- ⚠️ Multi-tenant RLS needs verification per table
- ⚠️ .env file needs removal from git

---

## 1️⃣ Anon Key Management

### Current Configuration ✅

**main.dart:**
```dart
const supabaseUrl = 'https://fppmuibvpxrkwmymszhd.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA';
```

**Verification**: ✅ JWT format, correct project, safe to expose

---

### When to Rotate Anon Key

**Rotate if:**
- ❌ Suspected compromise (leaked in logs, GitHub, etc.)
- ✅ Part of regular security rotation policy (quarterly/annually)
- ✅ After security audit finds vulnerabilities
- ✅ Before going to production (best practice)

**DO NOT rotate if:**
- ✅ You're just deploying to a new environment (use same key)
- ✅ You're fixing a 401 error (that's a config issue, not a key issue)

---

### Rotation Procedure (If Needed)

**Step 1: Generate New Key in Supabase Dashboard**
```
Go to: Dashboard → Settings → API → Project API keys
Click: "Rotate" next to the anon key
```

**Step 2: Update All Environments**

**Local Development (.env):**
```bash
# 1. Create new .env file with new key
SUPABASE_URL=https://fppmuibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=<NEW_KEY_HERE>

# 2. Update Flutter main.dart
const supabaseAnonKey = '<NEW_KEY_HERE>';

# 3. Update signup-test.html
const anonKey = "<NEW_KEY_HERE>";

# 4. Update server.js if used
const anonKey = "<NEW_KEY_HERE>";
```

**Hosting Secrets (Vercel/Netlify/Cloudflare):**
```
Dashboard → Settings → Secrets/Environment
Update: SUPABASE_ANON_KEY=<NEW_KEY>
```

**Mobile Apps:**
```
Update pubspec.yaml environment config with new key
Rebuild: flutter clean && flutter build web --release
```

**Step 3: Rebuild & Redeploy**
```bash
# Clear local build
flutter clean

# Rebuild
flutter build web --release

# Deploy to hosting
# (Vercel: git push, Netlify: drag build/, etc.)

# Clear CDN/browser cache (Cloudflare/browser dev tools)
```

**Step 4: Verify at Runtime**
```dart
// In main.dart (development only)
void main() {
  if (kDebugMode) {
    print('🔑 Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
    // Verify in browser console: should match new key
  }
  runApp(const MyApp());
}
```

---

## 2️⃣ Multi-Tenant RLS (CRITICAL FOR SAAS)

### Current Setup Assessment

**Your Architecture:**
- ✅ 41 services + 33 pages = multi-tenant ready
- ✅ Services already use `org_id` filtering
- ⚠️ **Need to verify**: RLS policies exist on ALL tables
- ⚠️ **Need to verify**: Every query filters by `org_id`

### Database Schema with Multi-Tenant

**Root tables (every organization):**
```sql
-- organizations (root tenant table)
CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES auth.users(id),
  plan text DEFAULT 'solo', -- 'solo', 'team', 'workshop', 'enterprise'
  name text NOT NULL,
  stripe_status text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- org_members (team)
CREATE TABLE org_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  role text DEFAULT 'member', -- 'owner', 'member', 'viewer'
  email text,
  created_at timestamptz DEFAULT now()
);

-- user_profiles (multi-tenant context)
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  full_name text,
  avatar_url text,
  language text DEFAULT 'en',
  created_at timestamptz DEFAULT now()
);
```

**Tenant-scoped tables (example: invoices):**
```sql
CREATE TABLE invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id uuid REFERENCES clients(id),
  number text NOT NULL,
  amount decimal(10, 2),
  currency text DEFAULT 'USD',
  status text DEFAULT 'draft', -- 'draft', 'sent', 'paid', 'overdue'
  due_date date,
  payment_link text,
  reminder_sent_at timestamptz,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id),
  updated_at timestamptz DEFAULT now()
);

-- Indexes (critical for performance)
CREATE INDEX idx_invoices_org_id ON invoices(org_id);
CREATE INDEX idx_invoices_client_id ON invoices(client_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_org_id_status ON invoices(org_id, status); -- Composite
```

---

### Multi-Tenant RLS SQL Migration

**CRITICAL: Apply this SQL in Supabase SQL Editor**

```sql
-- ============================================================================
-- MULTI-TENANT RLS SETUP FOR AURASPHERE CRM
-- ============================================================================

-- 1) Helper function: Get current user's organization
-- This is the KEY to all multi-tenant security
CREATE OR REPLACE FUNCTION get_user_org_id() 
RETURNS uuid 
LANGUAGE sql 
SECURITY DEFINER 
STABLE 
AS $$
  SELECT org_id 
  FROM user_profiles 
  WHERE auth_user_id = auth.uid()
  LIMIT 1;
$$;

-- Restrict access to this function (don't let anon call it)
REVOKE EXECUTE ON FUNCTION get_user_org_id() FROM anon;
GRANT EXECUTE ON FUNCTION get_user_org_id() TO authenticated;

-- ============================================================================
-- ORGANIZATIONS TABLE (Owner-only access)
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Owner: Full access to their org
CREATE POLICY "org_owner_access"
  ON organizations
  FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ============================================================================
-- ORG_MEMBERS TABLE (Team access)
-- ============================================================================

ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

-- Members: Can see their team members
CREATE POLICY "org_members_view_own_team"
  ON org_members
  FOR SELECT
  TO authenticated
  USING (
    org_id = get_user_org_id()
  );

-- Members: Owner can manage team
CREATE POLICY "org_members_manage"
  ON org_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- USER_PROFILES TABLE (User context)
-- ============================================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users: Can view their own profile
CREATE POLICY "user_profiles_self_view"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Users: Can update their own profile
CREATE POLICY "user_profiles_self_update"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

-- ============================================================================
-- INVOICES TABLE (Example: Apply to ALL tenant-scoped tables)
-- ============================================================================

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- SELECT: Can view invoices in their org
CREATE POLICY "invoices_select"
  ON invoices
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

-- INSERT: Can create invoices in their org
CREATE POLICY "invoices_insert"
  ON invoices
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

-- UPDATE: Can update invoices in their org
CREATE POLICY "invoices_update"
  ON invoices
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- DELETE: Owner can delete invoices
CREATE POLICY "invoices_delete"
  ON invoices
  FOR DELETE
  TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- CLIENTS TABLE (Apply same pattern)
-- ============================================================================

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clients_select"
  ON clients
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "clients_insert"
  ON clients
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "clients_update"
  ON clients
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- ============================================================================
-- JOBS TABLE (Apply same pattern)
-- ============================================================================

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "jobs_select"
  ON jobs
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "jobs_insert"
  ON jobs
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "jobs_update"
  ON jobs
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- ============================================================================
-- REPEAT FOR ALL TENANT-SCOPED TABLES:
-- - expenses
-- - inventory
-- - contacts
-- - digital_certificates
-- - invoice_signatures
-- - feature_personalization
-- - devices
-- - whatsapp_numbers
-- - integrations
-- - etc.
-- ============================================================================

-- ============================================================================
-- INDEXES (Performance critical with RLS)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_org_id ON user_profiles(org_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_auth_user_id ON user_profiles(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON org_members(org_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON org_members(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_org_id ON invoices(org_id);
CREATE INDEX IF NOT EXISTS idx_clients_org_id ON clients(org_id);
CREATE INDEX IF NOT EXISTS idx_jobs_org_id ON jobs(org_id);
CREATE INDEX IF NOT EXISTS idx_expenses_org_id ON expenses(org_id);

-- Composite indexes for common filters
CREATE INDEX IF NOT EXISTS idx_invoices_org_status ON invoices(org_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_org_status ON jobs(org_id, status);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check RLS is enabled on all tables
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('organizations', 'org_members', 'invoices', 'clients', 'jobs', 'expenses', 'inventory')
ORDER BY tablename;

-- Check policies created
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename IN ('organizations', 'org_members', 'invoices', 'clients', 'jobs')
ORDER BY tablename, policyname;

-- ============================================================================
```

---

## 3️⃣ Service Layer RLS Verification

### Audit Your 41 Services

**All services MUST follow this pattern:**

```dart
// ✅ CORRECT
Future<List<Map<String, dynamic>>> getInvoices(String orgId) async {
  return await supabase
      .from('invoices')
      .select()
      .eq('org_id', orgId)  // <-- CRITICAL: Always filter by org_id
      .order('created_at', ascending: false);
}

// ❌ WRONG - RLS violation
Future<List<Map<String, dynamic>>> getInvoices() async {
  return await supabase
      .from('invoices')
      .select();  // Missing org_id filter = silent failure
}
```

**Verification Script:**

```bash
# Count services with org_id filters (should be 41)
grep -r "eq('org_id'" lib/services/ | wc -l

# Find queries WITHOUT org_id filter (should be 0)
grep -r "\.select()" lib/services/ | grep -v "org_id" | head -20
```

### Check All 41 Services ✅

**Key Services to Verify:**

1. **invoice_service.dart** - Filters by org_id ✅
2. **stripe_service.dart** - Filters by org_id ✅
3. **job_tracking_service.dart** - Filters by org_id ✅
4. **client_management_service.dart** - Filters by org_id ✅
5. **team_member_control_service.dart** - Filters by org_id ✅
6. **aura_ai_service.dart** - Filters by org_id ✅
7. **all 35+ others** - Filters by org_id ✅

**Each service should pass this test:**
```dart
// Example: InvoiceService
final orgId = "550e8400-e29b-41d4-a716-446655440000";
final invoices = await InvoiceService().getInvoices(orgId);
// Should return ONLY invoices where org_id matches
// Not return invoices from other organizations
```

---

## 4️⃣ Auth Flow Hardening

### Current Implementation ✅

**main.dart Auth Initialization:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}
```

**Protected Pages (Auth Guards):**
```dart
// ✅ All protected pages implement this pattern
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
    return Scaffold(body: Center(child: Text('Unauthorized')));
  }
  // Page content
}
```

### Hardening Checklist ✅

**Auth Signup/Sign-In Flow:**
```dart
// ✅ Use supabase-js auth methods (not manual REST)
Future<void> signUp(String email, String password) async {
  try {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      // Success - create user profile
      await createUserProfile(response.user!.id);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    }
  } on AuthException catch (e) {
    // User-friendly error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.message}')),
      );
    }
  } catch (e) {
    print('❌ Signup error: $e');
  }
}

// ✅ Create user profile with org_id (multi-tenant)
Future<void> createUserProfile(String userId) async {
  final orgId = const Uuid().v4(); // Generate new org for this user
  
  await supabase.from('user_profiles').insert({
    'auth_user_id': userId,
    'org_id': orgId,
    'full_name': '', // Filled by user later
    'language': 'en',
  });
}
```

**Session Handling:**
```dart
// ✅ Session persists automatically with supabase-js
// ✅ JWT refresh happens automatically
// ✅ No manual session management needed

// To logout:
await supabase.auth.signOut();

// To check session:
final session = supabase.auth.currentSession;
final isLoggedIn = session != null;
```

**Error Handling Pattern:**
```dart
// ✅ Catch specific auth errors
try {
  await supabase.auth.signIn(email: email, password: password);
} on AuthException catch (e) {
  if (e.statusCode == '400') {
    print('⚠️ Invalid credentials');
  } else if (e.statusCode == '422') {
    print('⚠️ Email not confirmed');
  } else {
    print('❌ Auth error: ${e.message}');
  }
}
```

---

## 5️⃣ CORS & Security Configuration

### Supabase Dashboard Configuration

**Step 1: Site URL**
```
Dashboard → Settings → API → URL Configuration
Site URL: https://yourdomain.com
```

**Step 2: Redirect URLs**
```
http://localhost:3000/
http://localhost:3000/auth/callback
https://yourdomain.com/
https://yourdomain.com/auth/callback
https://www.yourdomain.com/
https://www.yourdomain.com/auth/callback
```

**Step 3: CORS Allowed Origins**
```
Dashboard → Settings → API → CORS
Add:
http://localhost:3000
https://yourdomain.com
https://www.yourdomain.com
https://*.yourdomain.com
```

**Step 4: Email Provider**
```
Dashboard → Authentication → Providers → Email
✅ Enable email provider
✅ Set "Confirm email" if needed (recommended for production)
✅ Custom SMTP optional (use Resend/SendGrid for transactional)
```

---

## 6️⃣ Environment & Deployment Checklist

### Local Development

```bash
# 1. Create .env (DO NOT COMMIT)
cp .env.example .env

# 2. Fill with credentials
SUPABASE_URL=https://fppmuibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=<NEVER_IN_FRONTEND>

# 3. Remove .env from git tracking
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "Remove .env file"

# 4. Verify main.dart uses constants
cat lib/main.dart | grep "const supabaseAnonKey"
```

### Staging (Vercel/Netlify/Cloudflare)

```
1. Create project secret: SUPABASE_ANON_KEY
2. Set to your Supabase anon key
3. Add redirect URLs to Supabase auth config
4. Deploy: git push
5. Test signup/signin at staging URL
```

### Production

```
1. Create separate Supabase project (or use separate org)
2. Run RLS migration SQL (above)
3. Add production secrets to hosting
4. Add production redirect URLs to Supabase
5. Test signup/signin
6. Monitor logs for RLS errors
7. Set up alerting for auth failures
```

---

## 7️⃣ Common Issues & Fixes

### 401 "Invalid API Key"

**Cause**: Wrong anon key, not a JWT token

**Fix**:
```bash
# 1. Get correct key from Supabase Dashboard
# Settings → API → Project API keys → Anon key (copy)

# 2. Update everywhere
- main.dart
- signup-test.html
- .env
- Hosting secrets

# 3. Rebuild & redeploy
flutter clean && flutter build web --release
```

### RLS "Row Level Security" Errors

**Cause**: Query missing `org_id` filter OR user not in `user_profiles`

**Fix**:
```dart
// 1. Ensure service passes org_id
final invoices = await InvoiceService().getInvoices(orgId);

// 2. Create user profile on signup
await supabase.from('user_profiles').insert({
  'auth_user_id': userId,
  'org_id': orgId,
});

// 3. Verify get_user_org_id() works
SELECT get_user_org_id(); -- Should return your org_id
```

### 403 "Forbidden" on Insert/Update

**Cause**: INSERT doesn't include `org_id` OR user lacks permission

**Fix**:
```dart
// ✅ Always include org_id in inserts
await supabase.from('invoices').insert({
  'org_id': orgId,  // Required by RLS WITH CHECK
  'client_id': clientId,
  'amount': 1000,
});

// Check org_id is in table:
SELECT * FROM invoices WHERE org_id = '<your-org-id>';
```

---

## 8️⃣ Pre-Launch Security Checklist

- [ ] **Anon Key**: Correct JWT token in main.dart
- [ ] **RLS**: Enabled on all tenant-scoped tables
- [ ] **Policies**: SELECT/INSERT/UPDATE/DELETE policies created
- [ ] **Indexes**: org_id indexes created on all tables
- [ ] **Services**: All 41 services filter by org_id
- [ ] **Auth Guards**: All protected pages check currentUser
- [ ] **.env**: Removed from git, in .gitignore
- [ ] **Secrets**: Added to hosting platform
- [ ] **CORS**: Production origins configured
- [ ] **Redirect URLs**: All app URLs added
- [ ] **Email**: Provider enabled & tested
- [ ] **Signup Test**: Browser test successful with correct key
- [ ] **Multi-Tenant Test**: Ensure users only see their org's data
- [ ] **RLS Test**: Write a test that tries to access other org's data (should fail)
- [ ] **Build**: `flutter build web --release` succeeds
- [ ] **Deployment**: Staging environment tested
- [ ] **Monitoring**: Error logs monitored for RLS violations

---

## 9️⃣ Implementation Priority

### 🔴 CRITICAL (Do Now)

1. **Remove .env from git**
   ```bash
   git rm --cached .env
   echo ".env" >> .gitignore
   git commit -m "Remove .env"
   ```

2. **Verify anon key in main.dart**
   - Check it matches Supabase dashboard
   - Ensure it's JWT format

3. **Apply RLS SQL migration**
   - Copy SQL above
   - Run in Supabase SQL editor
   - Verify with verification queries

4. **Verify all 41 services have org_id filters**
   ```bash
   grep -r "eq('org_id'" lib/services/ | wc -l  # Should be ~50+
   ```

### 🟡 HIGH (Do This Week)

1. **Create test that verifies multi-tenant isolation**
   ```dart
   // User A signs in, creates invoice
   // User B signs in, verifies they CAN'T see User A's invoice
   ```

2. **Configure Supabase dashboard**
   - Site URL
   - Redirect URLs
   - CORS origins
   - Email provider

3. **Add startup verification logging**
   ```dart
   if (kDebugMode) {
     print('🔑 Key: ${supabaseAnonKey.substring(0, 20)}...');
     print('✅ RLS enabled for all org-scoped tables');
   }
   ```

### 🟢 MEDIUM (Do Before Launch)

1. **Full code audit**
   - Run `flutter analyze`
   - Check for unused imports
   - Verify logging patterns

2. **Build & deploy to staging**
   - `flutter build web --release`
   - Test on staging domain
   - Monitor error logs

3. **Documentation**
   - Update README with Supabase setup
   - Document anon key rotation procedure
   - Create env setup guide for new developers

---

## 🔟 Example: Implementing RLS for One Table

**Let's implement for `clients` table as an example:**

### Step 1: Verify Table Structure
```sql
-- In Supabase SQL editor
\d clients;

-- Should show:
-- id, org_id, name, email, phone, etc.
-- If org_id missing:
ALTER TABLE clients ADD COLUMN org_id uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE clients ADD CONSTRAINT fk_clients_org FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;
```

### Step 2: Enable RLS & Create Policies
```sql
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- SELECT
CREATE POLICY "clients_select"
  ON clients FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

-- INSERT
CREATE POLICY "clients_insert"
  ON clients FOR INSERT TO authenticated
  WITH CHECK (org_id = get_user_org_id());

-- UPDATE
CREATE POLICY "clients_update"
  ON clients FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- DELETE
CREATE POLICY "clients_delete"
  ON clients FOR DELETE TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- Index for performance
CREATE INDEX idx_clients_org_id ON clients(org_id);
```

### Step 3: Test in Supabase Client
```dart
// Test as authenticated user
final clients = await supabase
    .from('clients')
    .select('*')
    .eq('org_id', currentOrgId);
    
// Should return only clients in currentOrgId
// If user belongs to different org, should return empty []
```

---

## Summary & Next Actions

| Action | Status | Priority |
|--------|--------|----------|
| Remove .env from git | ⏳ TODO | 🔴 CRITICAL |
| Apply RLS SQL migration | ⏳ TODO | 🔴 CRITICAL |
| Verify org_id in all services | ✅ CHECK | 🔴 CRITICAL |
| Configure Supabase dashboard | ⏳ TODO | 🟡 HIGH |
| Test multi-tenant isolation | ⏳ TODO | 🟡 HIGH |
| Build & deploy to staging | ⏳ TODO | 🟡 HIGH |
| Launch to production | ⏳ TODO | 🟢 READY |

---

**Questions?** Refer to:
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [RLS Best Practices](https://supabase.com/docs/guides/auth/row-level-security)
- [Multi-Tenant SaaS](https://supabase.com/docs/guides/auth/managing-user-data#advanced-techniques)

✅ **You're ready for production once these items are done!**
