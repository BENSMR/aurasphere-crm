# Supabase Prepayment System - Implementation Checklist

## Pre-Deployment Verification

### Database Readiness
- [ ] Supabase project is created and accessible
- [ ] `users` table exists with auth integration
- [ ] Database is in good state (no pending migrations)
- [ ] Current user has ADMIN role to run migrations

### Code Readiness
- [ ] `lib/services/prepayment_code_service.dart` is complete
- [ ] `lib/prepayment_code_admin_page.dart` is complete
- [ ] `lib/prepayment_code_page.dart` is complete
- [ ] All files compile without errors (`flutter analyze`)
- [ ] Services import correctly in main.dart
- [ ] Routes are added to main.dart:
  - [ ] `/prepayment-codes` → prepayment_code_page
  - [ ] `/admin/code-generator` → prepayment_code_admin_page

---

## Deployment Steps

### Step 1: Run Migration on Supabase

- [ ] Open Supabase Dashboard
- [ ] Navigate to SQL Editor
- [ ] Copy `supabase_migrations/complete_prepayment_system.sql`
- [ ] Paste into query editor
- [ ] Execute migration
- [ ] Check for errors in console
- [ ] Note down any warnings

**Migration should create:**
- [ ] `prepayment_codes` table
- [ ] `prepayment_code_audit` table
- [ ] 8 indexes on prepayment_codes
- [ ] 4 indexes on prepayment_code_audit
- [ ] 5 RLS policies on prepayment_codes
- [ ] 2 RLS policies on prepayment_code_audit
- [ ] 2 trigger functions
- [ ] 2 triggers
- [ ] 4 columns added to users table

### Step 2: Verify Tables Exist

Run in Supabase SQL Editor:

```sql
-- Verify prepayment_codes table
SELECT 
  table_name,
  column_count,
  row_count
FROM information_schema.tables
WHERE table_name IN ('prepayment_codes', 'prepayment_code_audit');

-- Verify RLS is enabled
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename IN ('prepayment_codes', 'prepayment_code_audit');

-- Verify indexes
SELECT indexname, tablename
FROM pg_indexes
WHERE tablename IN ('prepayment_codes', 'prepayment_code_audit')
ORDER BY tablename;
```

- [ ] prepayment_codes table exists
- [ ] prepayment_code_audit table exists
- [ ] Both tables have RLS enabled
- [ ] All 12 indexes are created

### Step 3: Test RLS Policies

```sql
-- Test as admin (should work)
SELECT COUNT(*) FROM prepayment_codes;

-- Test as regular user (should show 0 or only own redeemed codes)
-- This requires switching auth context in dashboard

-- Verify policies exist
SELECT policyname, tablename, cmd
FROM pg_policies
WHERE tablename IN ('prepayment_codes', 'prepayment_code_audit');
```

- [ ] Policies are listed
- [ ] At least 5 policies on prepayment_codes
- [ ] At least 2 policies on prepayment_code_audit

### Step 4: Test Code Generation

```sql
-- Generate test code as admin
WITH admin_user AS (
  SELECT id FROM users WHERE role = 'admin' LIMIT 1
)
INSERT INTO prepayment_codes (
  code,
  plan_id,
  region,
  subscription_duration,
  created_by,
  valid_until
)
SELECT
  'AURA-TN-2024-TEST-VERIFICATION',
  'solo',
  'TN',
  1,
  id,
  NOW() + INTERVAL '30 days'
FROM admin_user;

-- Verify code was created
SELECT code, plan_id, region, subscription_duration, status
FROM prepayment_codes
WHERE code LIKE 'AURA-TN-2024-TEST%';
```

- [ ] Code inserted successfully
- [ ] Code visible in table
- [ ] Status is 'active'
- [ ] Audit log entry created

### Step 5: Test Redemption

```sql
-- Get test code
SELECT id, code FROM prepayment_codes 
WHERE code LIKE 'AURA-TN-2024-TEST%'
LIMIT 1;

-- Redeem as test user (use actual user ID)
UPDATE prepayment_codes
SET
  status = 'redeemed',
  redeemed_by = 'USER_ID_HERE',  -- Replace with actual UUID
  redeemed_at = NOW(),
  subscription_active_until = NOW() + INTERVAL '1 month'
WHERE code = 'AURA-TN-2024-TEST-VERIFICATION'
AND status = 'active';

-- Verify redemption
SELECT code, status, redeemed_by, redeemed_at, subscription_active_until
FROM prepayment_codes
WHERE code = 'AURA-TN-2024-TEST-VERIFICATION';

-- Check audit log
SELECT action, performed_by, performed_at, details
FROM prepayment_code_audit
WHERE code_id IN (
  SELECT id FROM prepayment_codes
  WHERE code = 'AURA-TN-2024-TEST-VERIFICATION'
)
ORDER BY performed_at DESC;
```

- [ ] Code successfully updated to 'redeemed'
- [ ] redeemed_by is set
- [ ] redeemed_at is set
- [ ] subscription_active_until calculated correctly
- [ ] At least 2 audit entries created (generated + redeemed)

### Step 6: Test Single-Use Enforcement

```sql
-- Try to redeem same code with different user (should fail with unique constraint)
UPDATE prepayment_codes
SET
  status = 'redeemed',
  redeemed_by = 'DIFFERENT_USER_ID',  -- Different user
  redeemed_at = NOW(),
  subscription_active_until = NOW() + INTERVAL '1 month'
WHERE code = 'AURA-TN-2024-TEST-VERIFICATION';

-- Expected error: "duplicate key value violates unique constraint"
```

- [ ] Constraint violation occurs (expected)
- [ ] Error message mentions unique constraint on redeemed_by
- [ ] ✅ Single-use enforcement confirmed

### Step 7: Test All Regions

```sql
-- Generate codes for different regions
WITH admin_user AS (
  SELECT id FROM users WHERE role = 'admin' LIMIT 1
)
INSERT INTO prepayment_codes (code, plan_id, region, subscription_duration, created_by, valid_until)
SELECT
  'AURA-' || region_code || '-2024-TEST',
  'team',
  region_code,
  3,
  admin.id,
  NOW() + INTERVAL '30 days'
FROM admin_user admin
CROSS JOIN (
  VALUES ('TN'), ('ML'), ('ET'), ('ZA'), ('CM')
) AS regions(region_code);

-- Verify all regions were created
SELECT DISTINCT region FROM prepayment_codes
WHERE code LIKE 'AURA-%-2024-TEST'
ORDER BY region;
```

- [ ] Codes created for TN (Tunisia)
- [ ] Codes created for ML (Mali)
- [ ] Codes created for ET (Ethiopia)
- [ ] Codes created for ZA (South Africa)
- [ ] Codes created for CM (Cameroon)
- [ ] All 5 continents represented in test data

---

## Application Testing

### In Flutter App

#### Test Admin Dashboard

1. Open app, login as admin
2. Navigate to `/admin/code-generator`
3. Check region selector loads all 54 countries
   - [ ] North Africa section visible
   - [ ] West Africa section visible
   - [ ] Central Africa section visible
   - [ ] East Africa section visible
   - [ ] Southern Africa section visible

4. Generate test codes:
   - [ ] Select "Solo" plan
   - [ ] Select a region (e.g., Tunisia)
   - [ ] Select "3 Months" duration
   - [ ] Enter quantity: 5
   - [ ] Click "Generate Codes"
   - [ ] Codes appear in list

5. Check statistics display:
   - [ ] Total codes count
   - [ ] Active vs Redeemed breakdown
   - [ ] Plan breakdown (Solo/Team/Workshop)
   - [ ] Region breakdown (all 54 countries available)
   - [ ] Duration breakdown (1M/3M/6M/1Y)

#### Test User Code Entry Page

1. Open app, go to signup/code entry
2. Navigate to `/prepayment-codes`
3. Check code input:
   - [ ] Input field accepts 50 characters
   - [ ] Auto-formats code as you type
   - [ ] Case-insensitive (auto converts to uppercase)

4. Enter a valid code:
   - [ ] Code input shows formatted version
   - [ ] Validation button enables
   - [ ] Click "Validate Code"
   - [ ] Code details card appears

5. Code details card shows:
   - [ ] Plan name and price
   - [ ] Region name with flag emoji (e.g., 🇹🇳 Tunisia)
   - [ ] Duration (e.g., "3 Months subscription")
   - [ ] Expiry date
   - [ ] "Activate Plan" button

6. Redeem code:
   - [ ] Click "Activate Plan"
   - [ ] Success message appears
   - [ ] User is subscribed
   - [ ] Subscription active until date is correct

#### Test Error Handling

1. Invalid code:
   - [ ] Error message: "Code not found"

2. Expired code:
   - [ ] Error message: "Code has expired"

3. Already redeemed code:
   - [ ] Error message: "Code has already been used"

4. Wrong format:
   - [ ] Code validation fails
   - [ ] User-friendly error message

---

## Production Rollout

### Pre-Launch

- [ ] Backup production Supabase database
- [ ] Test migration on staging first
- [ ] All team members notified of changes
- [ ] Documentation shared with admins

### Launch

1. **Maintenance Mode (optional)**
   - [ ] Put app in maintenance mode
   - [ ] Notify users if needed

2. **Run Migration**
   - [ ] Execute complete_prepayment_system.sql
   - [ ] Monitor for errors
   - [ ] Verify all tables and policies created

3. **Deploy App**
   - [ ] Deploy new Flutter app version
   - [ ] Update web server
   - [ ] Update mobile app

4. **Smoke Tests**
   - [ ] Admin can generate codes
   - [ ] User can enter and redeem code
   - [ ] Audit logs are created
   - [ ] RLS policies work correctly

5. **Open to Users**
   - [ ] Announce feature availability
   - [ ] Monitor error logs
   - [ ] Support team ready for questions

### Post-Launch

- [ ] Monitor code generation rates
- [ ] Check audit logs for anomalies
- [ ] Collect user feedback
- [ ] Watch for database performance issues

---

## Monitoring & Maintenance

### Regular Checks (Daily)

```sql
-- Check for any database errors
SELECT message FROM pg_logs 
WHERE timestamp > NOW() - INTERVAL '24 hours'
AND level = 'ERROR';

-- Monitor code usage
SELECT 
  status,
  COUNT(*) as count,
  plan_id,
  region
FROM prepayment_codes
GROUP BY status, plan_id, region;
```

### Weekly Audit

```sql
-- Codes expiring soon
SELECT code, plan_id, region, valid_until
FROM prepayment_codes
WHERE status = 'active'
AND valid_until < NOW() + INTERVAL '7 days'
AND valid_until > NOW();

-- Most active regions
SELECT region, COUNT(*) as codes_generated
FROM prepayment_codes
GROUP BY region
ORDER BY codes_generated DESC;
```

- [ ] Review expiring codes
- [ ] Check most active regions
- [ ] Verify no RLS errors

### Monthly Maintenance

```sql
-- Expired codes (mark and delete old audit entries)
UPDATE prepayment_codes
SET status = 'expired'
WHERE status = 'active'
AND valid_until < NOW();

-- Audit retention (optional - delete >90 days old)
DELETE FROM prepayment_code_audit
WHERE performed_at < NOW() - INTERVAL '90 days';
```

- [ ] Mark expired codes
- [ ] Archive old audit logs
- [ ] Verify database performance

---

## Rollback Plan

If critical issues arise:

```sql
-- Minimal rollback (disable prepayment system)
UPDATE users SET activation_method = 'stripe' 
WHERE activation_method = 'prepayment_code';

-- Revert policies (admins only)
DROP POLICY "users_redeem_codes" ON prepayment_codes;
DROP POLICY "users_view_own_redeemed" ON prepayment_codes;

-- Full rollback (see SUPABASE_PREPAYMENT_DEPLOYMENT.md)
```

- [ ] Rollback procedure documented
- [ ] Team trained on rollback steps
- [ ] Communication plan ready

---

## Sign-Off

- [ ] Database Admin: _________________ Date: _______
- [ ] App Developer: _________________ Date: _______
- [ ] QA/Tester: _________________ Date: _______
- [ ] Product Manager: _________________ Date: _______

---

**Checklist Status:** Ready for Deployment
**Last Updated:** January 4, 2026
**Version:** 1.0
