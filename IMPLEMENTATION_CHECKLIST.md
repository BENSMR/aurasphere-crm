# ✅ AuraSphere CRM - Implementation Checklist

**Project**: fppmuibvpxrkwmymszhd | **Status**: Production Hardening
**Date**: January 15, 2026 | **Target**: Launch Ready

---

## 🔴 CRITICAL - Do These First

### 1. Remove .env from Git History

**Why**: .env contains secrets that should never be in version control

**Steps**:
```bash
# Step 1: Remove from git tracking (but keep local file)
git rm --cached .env

# Step 2: Ensure .gitignore has .env
echo ".env" >> .gitignore

# Step 3: Commit the removal
git commit -m "Remove .env file from git (contains secrets)"

# Step 4: Verify
git status  # Should NOT show .env
cat .gitignore | grep ".env"  # Should show .env

# Step 5: If already pushed, force push
# WARNING: Only do this if you haven't shared the history
# git push --force-with-lease
```

**Verification**: 
- [ ] .env file still exists locally
- [ ] .env is in .gitignore
- [ ] git status doesn't show .env
- [ ] .env.example exists (template for others)

---

### 2. Verify Anon Key is Correct

**Current Key in main.dart**:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA
```

**Verification Steps**:
```bash
# 1. Go to Supabase Dashboard
# https://app.supabase.com/project/fppmuibvpxrkwmymszhd/settings/api

# 2. Check Project API keys → Anon key
# Compare with main.dart value above

# 3. Verify in code
grep "const supabaseAnonKey" lib/main.dart

# 4. Check format (should start with eyJ)
# This indicates JWT encoding ✅
```

**Checklist**:
- [ ] Key matches Supabase Dashboard
- [ ] Key is JWT format (starts with `eyJ`)
- [ ] Key is in main.dart (not in .env)
- [ ] Same key in signup-test.html
- [ ] Same key in server.js (if used)

---

### 3. Apply RLS SQL Migration

**⚠️ CRITICAL FOR MULTI-TENANT SECURITY**

**Steps**:

1. **Open Supabase SQL Editor**
   ```
   Dashboard → SQL Editor → New Query
   ```

2. **Paste This Block** (from SUPABASE_PRODUCTION_HARDENING_GUIDE.md, section 2)
   ```sql
   -- Create get_user_org_id() helper function
   CREATE OR REPLACE FUNCTION get_user_org_id() 
   RETURNS uuid 
   LANGUAGE sql 
   SECURITY DEFINER 
   STABLE 
   AS $$
     SELECT org_id FROM user_profiles 
     WHERE auth_user_id = auth.uid()
     LIMIT 1;
   $$;
   
   REVOKE EXECUTE ON FUNCTION get_user_org_id() FROM anon;
   GRANT EXECUTE ON FUNCTION get_user_org_id() TO authenticated;
   
   -- Enable RLS on organizations
   ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
   
   -- Enable RLS on org_members
   ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
   
   -- (Paste all policies from the guide...)
   ```

3. **Run Query** → Should complete with no errors

4. **Verify with This**:
   ```sql
   -- Check RLS is enabled
   SELECT schemaname, tablename, rowsecurity
   FROM pg_tables
   WHERE tablename IN ('organizations', 'org_members', 'invoices', 'clients', 'jobs', 'expenses')
   ORDER BY tablename;
   
   -- Should show: rowsecurity = t (true) for all tables
   ```

**Checklist**:
- [ ] get_user_org_id() function created
- [ ] RLS enabled on organizations
- [ ] RLS enabled on org_members
- [ ] RLS enabled on invoices
- [ ] RLS enabled on clients
- [ ] RLS enabled on jobs
- [ ] RLS enabled on expenses
- [ ] RLS enabled on inventory
- [ ] RLS enabled on digital_certificates
- [ ] RLS enabled on invoice_signatures
- [ ] RLS enabled on feature_personalization
- [ ] RLS enabled on devices
- [ ] Indexes created for performance
- [ ] Verification queries pass

---

## 🟡 HIGH - Do This Week

### 4. Verify All 41 Services Filter by org_id

**Why**: Missing org_id filter = security breach

**Check Script**:
```bash
# Count services WITH org_id filter
echo "Services WITH org_id filter:"
grep -r "eq('org_id'" lib/services/ | wc -l

# Show services WITH org_id
echo ""
echo "Sample services (should all have org_id):"
grep -l "eq('org_id'" lib/services/*.dart | head -5

# Find services WITHOUT org_id (should be 0)
echo ""
echo "Services WITHOUT org_id (should be empty):"
grep -r "\.select()" lib/services/ | grep -v "org_id" | head -10
```

**Expected Output**:
```
Services WITH org_id filter:
50+  (many filters, some services have multiple)

Sample services (should all have org_id):
lib/services/invoice_service.dart
lib/services/client_service.dart
lib/services/job_service.dart
...

Services WITHOUT org_id (should be empty):
(empty list)
```

**If Found Issues**:
```dart
// Fix this pattern:
❌ WRONG
final items = await supabase.from('invoices').select();

✅ CORRECT
final items = await supabase
    .from('invoices')
    .select()
    .eq('org_id', orgId);
```

**Checklist**:
- [ ] Run grep script above
- [ ] Verify 50+ org_id filters found
- [ ] Fix any missing org_id filters
- [ ] Verify all 41 services pass

---

### 5. Configure Supabase Dashboard

**Site URL**:
```
Dashboard → Settings → API → URL Configuration
Site URL: https://yourdomain.com
```

**Redirect URLs** (Add all):
```
http://localhost:3000/
http://localhost:3000/auth/callback
https://yourdomain.com/
https://yourdomain.com/auth/callback
https://www.yourdomain.com/
https://www.yourdomain.com/auth/callback
https://app.yourdomain.com/
```

**CORS Origins**:
```
Dashboard → Settings → API → CORS
Add:
http://localhost:3000
https://yourdomain.com
https://www.yourdomain.com
https://app.yourdomain.com
```

**Email Provider**:
```
Dashboard → Authentication → Providers → Email
✅ Enable
✅ Set "Confirm email" = true (for production)
```

**Checklist**:
- [ ] Site URL configured
- [ ] Redirect URLs added (all app URLs)
- [ ] CORS origins configured
- [ ] Email provider enabled
- [ ] Test signup at your domain

---

### 6. Test Multi-Tenant Isolation

**Why**: Ensure users can't access other orgs' data

**Test Steps**:

```dart
// Create test in test/ directory
// OR run manually in Firebase emulator/Supabase local

void main() async {
  // Setup
  final supabase = SupabaseClient(url, anonKey);
  
  // User A: Sign up and create invoice
  final signUpA = await supabase.auth.signUp(
    email: 'userA@test.com',
    password: 'password123',
  );
  final userAId = signUpA.user!.id;
  
  // Create user A's profile with orgA
  await supabase.from('user_profiles').insert({
    'auth_user_id': userAId,
    'org_id': 'org-a-uuid',
  });
  
  // Create invoice for orgA
  await supabase.from('invoices').insert({
    'org_id': 'org-a-uuid',
    'amount': 1000,
    'client_id': 'client-1',
  });
  
  // User B: Sign up and create invoice in different org
  final signUpB = await supabase.auth.signUp(
    email: 'userB@test.com',
    password: 'password456',
  );
  final userBId = signUpB.user!.id;
  
  await supabase.from('user_profiles').insert({
    'auth_user_id': userBId,
    'org_id': 'org-b-uuid',
  });
  
  await supabase.from('invoices').insert({
    'org_id': 'org-b-uuid',
    'amount': 2000,
    'client_id': 'client-2',
  });
  
  // Test 1: User B signs in
  await supabase.auth.signInWithPassword(
    email: 'userB@test.com',
    password: 'password456',
  );
  
  // Test 2: User B queries invoices (should ONLY see org-b-uuid)
  final invoices = await supabase
      .from('invoices')
      .select()
      .eq('org_id', 'org-b-uuid');  // If RLS works, this returns only their invoice
  
  // VERIFY
  assert(invoices.length == 1, 'Should see only 1 invoice');
  assert(invoices[0]['amount'] == 2000, 'Should see own invoice');
  
  // Test 3: Try to access User A's invoice (RLS should block)
  final unauthorizedAccess = await supabase
      .from('invoices')
      .select()
      .eq('org_id', 'org-a-uuid');  // RLS blocks this
  
  assert(unauthorizedAccess.length == 0, 'RLS should block access to other org');
  
  print('✅ Multi-tenant isolation verified!');
}
```

**Checklist**:
- [ ] Run multi-tenant test
- [ ] User A can't see User B's data
- [ ] User B can't see User A's data
- [ ] RLS properly isolates by org_id
- [ ] Insert/Update also respect RLS

---

### 7. Configure Hosting Secrets

**For Vercel**:
```bash
# 1. Go to: Vercel Dashboard → Project → Settings → Environment Variables
# 2. Add production secret:
Name: SUPABASE_ANON_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 3. Redeploy
git push
```

**For Netlify**:
```bash
# 1. Go to: Netlify Dashboard → Site → Settings → Build & deploy → Environment
# 2. Add:
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 3. Trigger deploy
```

**For Cloudflare Pages**:
```bash
# 1. Go to: Cloudflare Dashboard → Pages → Project → Settings → Environment variables
# 2. Add:
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 3. Redeploy
```

**Checklist**:
- [ ] Production secrets configured
- [ ] Staging secrets configured (different URL if separate project)
- [ ] Deployment successful
- [ ] Test signup at staging domain

---

## 🟢 MEDIUM - Do Before Launch

### 8. Code Quality Checks

**Run Analysis**:
```bash
flutter analyze
# Should show: 0 errors, 0 warnings (ideally)
```

**Format Code**:
```bash
dart format .
# Reformats all Dart files to standard
```

**Check Unused Imports**:
```bash
dart fix --apply source.unusedImports
# Removes unused imports
```

**Verify Logger Usage**:
```bash
# Count Logger usage (should be in all services)
grep -r "final _logger = Logger()" lib/services/ | wc -l

# Should be ~40+ (one per service)
# If less, some services use print() instead
```

**Checklist**:
- [ ] flutter analyze passes
- [ ] dart format . runs clean
- [ ] dart fix --apply source.unusedImports passes
- [ ] All services use Logger not print()
- [ ] No hardcoded API keys anywhere
- [ ] No hardcoded URLs (use environment variables)

---

### 9. Build & Test

**Clean Build**:
```bash
flutter clean
flutter pub get
```

**Build Web Release**:
```bash
flutter build web --release
# Optimizes and minifies code
```

**Check Build Size**:
```bash
du -sh build/web/
# Should be < 20 MB (ideally < 15 MB)

# If too large:
flutter build web --release --tree-shake-icons
```

**Test Locally**:
```bash
# Option 1: Serve locally
cd build/web
python -m http.server 8000

# Visit: http://localhost:8000
# Test signup/signin with correct anon key
```

**Checklist**:
- [ ] flutter clean succeeds
- [ ] flutter build web --release succeeds
- [ ] Build size < 20 MB
- [ ] Local test: Can sign up
- [ ] Local test: Can sign in
- [ ] Local test: Can access protected pages

---

### 10. Deployment Testing

**Staging Deployment**:
```bash
# Push to staging branch (if configured)
git checkout -b staging
git push origin staging

# Or deploy to Vercel/Netlify preview
# Should automatically trigger build

# Test at: https://staging-yourapp.vercel.app
```

**Staging Tests**:
- [ ] Signup works
- [ ] Email confirmation works
- [ ] Sign in works
- [ ] Dashboard loads
- [ ] Invoices display correctly
- [ ] Can create invoice
- [ ] Can see invoices only for own org
- [ ] Can't see other org's invoices
- [ ] Errors logged to console properly

**Production Deployment**:
```bash
# Merge to main
git checkout main
git merge staging
git push origin main

# Should automatically deploy to production
```

**Checklist**:
- [ ] Staging build succeeds
- [ ] Staging tests pass
- [ ] Production build succeeds
- [ ] Production login works
- [ ] Production data loads
- [ ] Monitor error logs

---

### 11. Monitoring & Documentation

**Error Monitoring**:
```
Dashboard → Settings → Logs
Watch for:
- RLS policy violations
- Auth failures
- Database errors
- API errors

If you see RLS errors, it means:
1. Query missing org_id filter, OR
2. User profile not created on signup
```

**Logging Setup**:
```dart
// In main.dart (development only)
void main() {
  if (kDebugMode) {
    print('🔑 Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
    print('🌍 URL: ${supabaseUrl}');
    print('✅ RLS: Enabled on all org-scoped tables');
  }
  runApp(const MyApp());
}
```

**Documentation**:
- [ ] README updated with Supabase setup
- [ ] Environment setup guide created
- [ ] Anon key rotation procedure documented
- [ ] Multi-tenant architecture explained
- [ ] RLS policies documented
- [ ] On-boarding guide for new developers

---

## ✅ Final Verification

**Before Launch Checklist**:

```
SECURITY
- [ ] .env removed from git
- [ ] Anon key correct (verified with Dashboard)
- [ ] RLS enabled on all tables
- [ ] All services filter by org_id
- [ ] No hardcoded API keys
- [ ] No service role key exposed
- [ ] Auth guards on all protected pages
- [ ] Multi-tenant isolation verified

CONFIGURATION
- [ ] Supabase URL correct
- [ ] Anon key correct
- [ ] Site URL configured
- [ ] Redirect URLs configured
- [ ] CORS origins configured
- [ ] Email provider enabled
- [ ] Secrets in hosting platform

CODE QUALITY
- [ ] flutter analyze passes
- [ ] dart format . passes
- [ ] No unused imports
- [ ] All services use Logger
- [ ] No console errors

BUILD & DEPLOYMENT
- [ ] flutter build web --release succeeds
- [ ] Build size < 20 MB
- [ ] Staging deployment works
- [ ] Staging tests pass
- [ ] Production deployment works
- [ ] Production tests pass

MONITORING
- [ ] Error logs configured
- [ ] Startup verification logging added
- [ ] Alert thresholds set
- [ ] Team knows how to monitor

DOCUMENTATION
- [ ] README updated
- [ ] Environment setup guide
- [ ] Anon key rotation procedure
- [ ] Multi-tenant architecture docs
- [ ] On-boarding guide for developers
```

---

## 📊 Progress Tracker

Use this to track your progress:

| Item | Status | Priority | Notes |
|------|--------|----------|-------|
| Remove .env from git | ⏳ TODO | 🔴 CRITICAL | Do first |
| Verify anon key | ⏳ TODO | 🔴 CRITICAL | Check Dashboard |
| Apply RLS SQL | ⏳ TODO | 🔴 CRITICAL | Use SQL Editor |
| Check org_id filters | ⏳ TODO | 🔴 CRITICAL | Run grep script |
| Configure Supabase | ⏳ TODO | 🟡 HIGH | Dashboard settings |
| Test multi-tenant | ⏳ TODO | 🟡 HIGH | Write test |
| Configure secrets | ⏳ TODO | 🟡 HIGH | Hosting platform |
| Code quality | ⏳ TODO | 🟢 MEDIUM | flutter analyze |
| Build & test | ⏳ TODO | 🟢 MEDIUM | flutter build |
| Deploy staging | ⏳ TODO | 🟢 MEDIUM | Test before prod |
| Documentation | ⏳ TODO | 🟢 MEDIUM | README update |
| Production launch | ⏳ TODO | ✅ READY | After all done |

---

## Next Step

**Start with Section 1: Remove .env from git** ✅

Run these commands:
```bash
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "Remove .env file (contains secrets)"
```

Then proceed to Section 2, 3, 4, etc.

**Questions?** See SUPABASE_PRODUCTION_HARDENING_GUIDE.md for detailed explanations.

✅ **You're on the path to a secure, production-ready SaaS CRM!**
