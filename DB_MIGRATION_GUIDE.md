# 🔧 Database Migration Troubleshooting

**Issue**: `supabase db push` exited with code 1  
**Date**: January 15, 2026

---

## ✅ What We Fixed

### **Routes Added to main.dart**
```dart
'/cloudguard': (c) => const CloudGuardPage(),
'/partner-portal': (c) => const PartnerPortalPage(),
'/suppliers': (c) => const SupplierManagementPage(),
```

---

## 🔍 Diagnosing the db push Error

### **Step 1: Check Supabase CLI Installation**

```bash
supabase --version
```

**Expected Output**: `Supabase CLI 1.X.X`

**If Error**: Install CLI
```bash
# On Windows with Scoop
scoop install supabase

# Or with Chocolatey
choco install supabase-cli

# Or manual download
# https://github.com/supabase/cli/releases
```

### **Step 2: Verify Supabase Project Link**

```bash
# In project directory
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Check if linked
supabase projects list
```

**Expected Output**: Shows your AuraSphere project

**If No Projects**: Link your project
```bash
supabase link --project-ref fppmuibvpxrkwmymszhd
# Will prompt for DB password (from Supabase dashboard)
```

### **Step 3: Check Migration File Syntax**

```bash
# Validate SQL syntax
supabase migration list

# Should show:
# 20260114_add_cloudguard_finops
```

### **Step 4: Run Migration with Verbose Output**

```bash
# Push with debug output
supabase db push --debug

# Or dry-run first
supabase db push --dry-run
```

---

## 🛠️ Alternative: Manual SQL Execution

If CLI push fails, execute migration manually:

### **Via Supabase Dashboard (Easiest)**

1. Go to https://app.supabase.com
2. Select your project (AuraSphere)
3. Click **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy entire contents of:
   ```
   supabase/migrations/20260114_add_cloudguard_finops.sql
   ```
6. Click **Run** (or Ctrl+Enter)
7. Verify success (no errors shown)

### **Via psql (Command Line)**

```bash
# Get connection string from Supabase dashboard
# Settings → Database → Connection Pooling → Copy Connection String

psql "postgresql://postgres:[PASSWORD]@db.fppmuibvpxrkwmymszhd.supabase.co:5432/postgres" \
  -f supabase/migrations/20260114_add_cloudguard_finops.sql

# Should complete without errors
```

---

## ✅ Verify Migration Applied

### **Check Tables Created**

In Supabase SQL Editor, run:

```sql
SELECT tablename 
FROM pg_tables 
WHERE schemaname='public' 
  AND (tablename LIKE 'cloud_%' OR tablename LIKE 'partner_%' OR tablename LIKE 'waste_%');
```

**Expected Output** (8 tables):
```
cloud_connections
cloud_expenses
waste_findings
partner_accounts
partner_demos
partner_resources
partner_commissions
```

### **Check RLS Policies**

```sql
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname='public'
  AND (tablename LIKE 'cloud_%' OR tablename LIKE 'partner_%' OR tablename LIKE 'waste_%')
ORDER BY tablename;
```

**Expected Output**: Should show RLS policies for all tables

---

## 🚀 Complete Setup Flow

### **Option A: CLI (Recommended)**
```bash
# 1. Verify CLI installed
supabase --version

# 2. Link to project (first time only)
supabase link --project-ref fppmuibvpxrkwmymszhd

# 3. Push migration
supabase db push

# 4. Verify
supabase migration list
```

### **Option B: Dashboard (Fastest)**
1. Supabase Dashboard → SQL Editor
2. Create new query
3. Copy & paste migration SQL
4. Run
5. Done ✅

### **Option C: Direct psql**
```bash
# Get password from Supabase Settings
psql [CONNECTION_STRING] -f supabase/migrations/20260114_add_cloudguard_finops.sql
```

---

## 🧪 Test After Migration

### **Test 1: Verify Tables Exist**

```bash
# In Supabase SQL Editor
SELECT COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('cloud_connections', 'cloud_expenses', 'waste_findings',
                     'partner_accounts', 'partner_demos', 'partner_resources',
                     'partner_commissions');
```

Expected: `7`

### **Test 2: Insert Test Data**

```sql
-- Get your org_id first (from organizations table)
SELECT id FROM organizations LIMIT 1;

-- Insert test cloud connection
INSERT INTO cloud_connections (
  org_id, provider, account_name, account_id,
  api_key_encrypted, api_secret_encrypted, is_active
) VALUES (
  '[YOUR_ORG_ID]',
  'aws',
  'Test Account',
  '123456789012',
  'test_key',
  'test_secret',
  true
);

-- Should return: INSERT 0 1
```

### **Test 3: Verify RLS Works**

```sql
-- This should only return your org's data
SELECT * FROM cloud_connections;

-- If it shows multiple orgs, RLS isn't working correctly
```

---

## 🆘 Common Errors & Solutions

### **Error: "Migration file not found"**
**Solution**: Ensure file exists at:
```
c:\Users\PC\AuraSphere\crm\aura_crm\supabase\migrations\20260114_add_cloudguard_finops.sql
```

### **Error: "Cannot connect to database"**
**Solution**: 
- Check Supabase project is running
- Verify password in connection string
- Check firewall/network access

### **Error: "Permission denied" on table creation**
**Solution**: 
- Ensure using correct Supabase project
- Verify auth user has CREATE TABLE privilege
- Check role permissions in Supabase

### **Error: "Syntax error in SQL statement"**
**Solution**:
- Check migration file for typos
- Run `supabase db push --dry-run` to see exact error
- Copy exact error and search in migration file

### **Error: "Relation already exists"**
**Solution**: Tables were already created (migration ran before)
- This is safe - means migration already applied ✅

---

## 📋 Final Checklist

- [ ] Routes added to `main.dart` (CloudGuard, Partner Portal, Suppliers)
- [ ] Migration file exists: `20260114_add_cloudguard_finops.sql`
- [ ] Either:
  - [ ] `supabase db push` completed successfully, OR
  - [ ] Manual SQL execution via Supabase Dashboard completed
- [ ] 8 tables visible in Supabase dashboard
- [ ] RLS policies applied
- [ ] Test data inserted successfully
- [ ] App compiles without errors: `flutter pub get`
- [ ] Pages accessible:
  - [ ] `/cloudguard` loads
  - [ ] `/partner-portal` loads
  - [ ] `/suppliers` loads

---

## 🎯 Next Steps

Once migration is applied:

1. **Run Flutter app**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

2. **Test routes**
   - Navigate to http://localhost:8080/cloudguard
   - Navigate to http://localhost:8080/partner-portal
   - Navigate to http://localhost:8080/suppliers

3. **Verify pages load** (should see dashboard components)

4. **Check console for errors** (F12 → Console)

---

## 📞 Support

If migration still fails after trying all options:

1. **Check Supabase Status**: https://status.supabase.com
2. **Review error message** carefully - it usually indicates exact problem
3. **Try Dashboard approach** instead of CLI
4. **Contact Supabase support** if database connection issue

---

**Status**: Routes ✅ Added | Migration needs manual push ⏳

**Recommendation**: Use Supabase Dashboard SQL Editor (Option B) - it's the fastest and most reliable.
