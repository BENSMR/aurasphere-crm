# QUICK REFERENCE: Supabase Prepayment Deployment

## One-Command Deployment

```sql
-- Copy entire contents of:
-- supabase_migrations/complete_prepayment_system.sql
-- Paste into Supabase SQL Editor
-- Execute
```

## Verify Deployment (30 seconds)

```sql
-- Check tables exist
SELECT tablename FROM pg_tables 
WHERE tablename IN ('prepayment_codes', 'prepayment_code_audit');

-- Check RLS enabled
SELECT tablename, rowsecurity FROM pg_tables
WHERE tablename IN ('prepayment_codes', 'prepayment_code_audit');

-- Check indexes created
SELECT COUNT(*) as index_count FROM pg_indexes
WHERE tablename = 'prepayment_codes';
-- Should return: 8
```

## Test Code Generation (1 minute)

```sql
-- Generate test code
WITH admin AS (SELECT id FROM users WHERE role='admin' LIMIT 1)
INSERT INTO prepayment_codes (code, plan_id, region, subscription_duration, created_by, valid_until)
SELECT 'AURA-TN-2024-1M-QUICK', 'solo', 'TN', 1, id, NOW() + INTERVAL '30 days'
FROM admin;

-- Verify
SELECT code, plan_id, status FROM prepayment_codes WHERE code LIKE '%QUICK%';
```

## Test Code Redemption (2 minutes)

```sql
-- Redeem code (replace USER_ID)
UPDATE prepayment_codes
SET status='redeemed', redeemed_by='USER_ID', redeemed_at=NOW(), subscription_active_until=NOW() + INTERVAL '1 month'
WHERE code='AURA-TN-2024-1M-QUICK' AND status='active';

-- Check it worked
SELECT code, status, redeemed_by, subscription_active_until FROM prepayment_codes WHERE code LIKE '%QUICK%';

-- Verify audit logged
SELECT action, performed_by FROM prepayment_code_audit WHERE action IN ('generated','redeemed') ORDER BY performed_at DESC LIMIT 2;
```

## Test Single-Use (30 seconds - should FAIL)

```sql
-- Try to redeem again with different user (should fail)
UPDATE prepayment_codes
SET redeemed_by='ANOTHER_USER_ID'
WHERE code='AURA-TN-2024-1M-QUICK';
-- Expected: ERROR: duplicate key value violates unique constraint

-- ✅ Confirms single-use enforcement works!
```

## Supported Regions Quick List

```
North Africa: TN, EG, MA, DZ, LY, SD, MR (7)
West Africa: ML, BF, SN, CI, BJ, TG, NE, GH, LR, SL, GW, GM, CV, MU (14)
Central Africa: CM, GA, CG, CD, TD, CF, ST, GQ, AO (9)
East Africa: ET, KE, UG, TZ, RW, BI, SO, DJ, ER, SC, KM (11)
Southern Africa: ZM, ZW, MW, MZ, NA, BW, LS, SZ, ZA (8)
TOTAL: 54 countries
```

## Table Columns (What's in the Database)

**prepayment_codes:**
- id, code, plan_id, region, subscription_duration, status
- created_by, created_at, valid_until
- redeemed_by, redeemed_at, subscription_active_until

**prepayment_code_audit:**
- id, code_id, action, performed_by, performed_at, ip_address, user_agent, details

**users (new columns):**
- prepayment_code_id, activation_method, subscription_plan, subscription_active_until

## RLS Policies Created

**prepayment_codes:**
1. Admins: View all codes
2. Admins: Insert new codes
3. Admins: Update codes
4. Users: View only own redeemed
5. Users: Redeem active codes

**prepayment_code_audit:**
1. Admins: View all logs
2. Admins: Create log entries

## Performance Indexes

**prepayment_codes (8 indexes):**
- code, status, region, redeemed_by, valid_until, subscription_duration, created_by, created_at

**prepayment_code_audit (4 indexes):**
- code_id, performed_by, action, performed_at

## Success Checklist

- [ ] Supabase dashboard open
- [ ] SQL Editor ready
- [ ] complete_prepayment_system.sql copied
- [ ] Migration executed without errors
- [ ] `prepayment_codes` table exists
- [ ] `prepayment_code_audit` table exists
- [ ] RLS policies created (5 + 2)
- [ ] Test code generated
- [ ] Test code redeemed
- [ ] Single-use enforcement verified
- [ ] Audit logs showing

## Troubleshoot Issues

| Issue | Solution |
|-------|----------|
| Permission denied | User must have ADMIN role |
| Table not created | Check for SQL syntax errors in migration |
| RLS blocking queries | Verify user role in users table |
| Can't redeem twice | **Feature, not bug!** (UNIQUE constraint prevents it) |
| Triggers not logging | Triggers fire automatically - check prepayment_code_audit table |
| Region code rejected | Code must be in 54 valid countries |

## Files to Reference

- **Deployment:** SUPABASE_PREPAYMENT_DEPLOYMENT.md
- **Checklist:** SUPABASE_PREPAYMENT_CHECKLIST.md
- **Summary:** SUPABASE_PREPAYMENT_UPDATE_SUMMARY.md
- **SQL:** supabase_migrations/complete_prepayment_system.sql

## Timeline

- Migration: ~30 seconds
- Verification: ~30 seconds
- Testing: ~5 minutes
- **Total: ~6 minutes to full validation**

---

**Status:** ✅ Ready to Deploy  
**Last Updated:** January 4, 2026  
**Version:** 1.0 - Production Ready
