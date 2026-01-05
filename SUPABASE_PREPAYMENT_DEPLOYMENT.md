# Supabase Deployment Guide - Prepayment Code System

## Quick Start

### 1. Deploy the Migration

#### Option A: Via Supabase Dashboard (Recommended for first-time)

1. Open [Supabase Dashboard](https://app.supabase.com)
2. Select your AuraSphere CRM project
3. Go to **SQL Editor** → **+ New Query**
4. Copy the entire content from `supabase_migrations/complete_prepayment_system.sql`
5. Paste into SQL Editor
6. Click **Run** (⌘ + Enter or Ctrl + Enter)
7. Wait for success message

#### Option B: Via Migrations (for CI/CD)

```bash
# Ensure Supabase CLI is installed
supabase db push

# Or manually:
supabase migration new "create_prepayment_codes"
# Then copy complete_prepayment_system.sql content into the migration file
supabase db push
```

### 2. Verify Deployment

After running the migration, verify everything is set up:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('prepayment_codes', 'prepayment_code_audit');

-- Check columns added to users table
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('prepayment_code_id', 'activation_method', 'subscription_plan', 'subscription_active_until');

-- Check indexes
SELECT indexname FROM pg_indexes WHERE tablename = 'prepayment_codes';

-- Check RLS is enabled
SELECT relname, relrowsecurity FROM pg_class 
WHERE relname IN ('prepayment_codes', 'prepayment_code_audit');
```

---

## Database Schema Overview

### Tables Created/Modified

#### 1. `prepayment_codes` (NEW)
Main table for prepayment code management.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| code | VARCHAR(50) | UNIQUE, code like `AURA-TN-2024-1M-ABC123` |
| plan_id | VARCHAR(20) | solo, team, workshop |
| region | VARCHAR(5) | ISO 3166-1 alpha-2 (54 African countries) |
| subscription_duration | INTEGER | 1, 3, 6, or 12 months |
| status | VARCHAR(20) | active, redeemed, or expired |
| created_by | UUID | Admin who generated code |
| created_at | TIMESTAMP | When code was generated |
| valid_until | TIMESTAMP | Expiration date |
| redeemed_by | UUID | UNIQUE - User who redeemed (single-use) |
| redeemed_at | TIMESTAMP | When code was redeemed |
| subscription_active_until | TIMESTAMP | When subscription expires |

**Key Constraints:**
- `redeemed_by` has UNIQUE constraint = single-use enforcement at database level
- All status changes validated by constraints
- Region codes validated against 54 African countries

#### 2. `prepayment_code_audit` (NEW)
Complete audit trail of all code operations.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key |
| code_id | UUID | FK to prepayment_codes |
| action | VARCHAR(50) | generated, validated, redeemed, expired |
| performed_by | UUID | User who performed action |
| performed_at | TIMESTAMP | When action occurred |
| ip_address | INET | IP address of requester (optional) |
| user_agent | TEXT | Browser/client info (optional) |
| details | JSONB | Additional context |

#### 3. `users` (MODIFIED)
Added prepayment support columns:

| Column | Type | Notes |
|--------|------|-------|
| prepayment_code_id | UUID | FK to redeemed code |
| activation_method | VARCHAR(20) | stripe, paddle, prepayment_code |
| subscription_plan | VARCHAR(20) | solo, team, workshop |
| subscription_active_until | TIMESTAMP | When subscription expires |

---

## Security & RLS Policies

### Prepayment Codes RLS

| Policy | Role | Operation | Condition |
|--------|------|-----------|-----------|
| admins_view_all_codes | Admin | SELECT | View all codes |
| admins_insert_codes | Admin | INSERT | Generate new codes |
| admins_update_codes | Admin | UPDATE | Update code status |
| users_view_own_redeemed | User | SELECT | View only own redeemed codes |
| users_redeem_codes | User | UPDATE | Redeem active codes |

### Audit Log RLS

| Policy | Role | Operation | Condition |
|--------|------|-----------|-----------|
| admins_view_audit | Admin | SELECT | View all audit logs |
| admins_insert_audit | Admin | INSERT | Create audit entries |

---

## Triggers & Functions

### `log_code_generation()`
Automatically logs code generation to audit table.

**Triggered on:** INSERT to prepayment_codes
**Logs:** plan_id, region, duration, valid_until

### `log_code_redemption()`
Automatically logs code redemption to audit table.

**Triggered on:** UPDATE to prepayment_codes (when status changes to 'redeemed')
**Logs:** plan_id, region, duration, subscription_active_until

---

## Indexes Created

For optimal query performance:

```
idx_prepayment_codes_code           (code)
idx_prepayment_codes_status         (status)
idx_prepayment_codes_region         (region)
idx_prepayment_codes_redeemed_by    (redeemed_by)
idx_prepayment_codes_valid_until    (valid_until)
idx_prepayment_codes_subscription_duration (subscription_duration)
idx_prepayment_codes_created_by     (created_by)
idx_prepayment_codes_created_at     (created_at)
idx_audit_code_id                   (code_id)
idx_audit_performed_by              (performed_by)
idx_audit_action                    (action)
idx_audit_performed_at              (performed_at)
```

---

## Supported Regions (54 African Countries)

### North Africa (7)
- TN: Tunisia
- EG: Egypt
- MA: Morocco
- DZ: Algeria
- LY: Libya
- SD: Sudan
- MR: Mauritania

### West Africa (14)
- ML: Mali
- BF: Burkina Faso
- SN: Senegal
- CI: Ivory Coast
- BJ: Benin
- TG: Togo
- NE: Niger
- GH: Ghana
- LR: Liberia
- SL: Sierra Leone
- GW: Guinea-Bissau
- GM: Gambia
- CV: Cape Verde
- MU: Mauritius

### Central Africa (9)
- CM: Cameroon
- GA: Gabon
- CG: Congo
- CD: DR Congo
- TD: Chad
- CF: Central African Republic
- ST: São Tomé & Príncipe
- GQ: Equatorial Guinea
- AO: Angola

### East Africa (11)
- ET: Ethiopia
- KE: Kenya
- UG: Uganda
- TZ: Tanzania
- RW: Rwanda
- BI: Burundi
- SO: Somalia
- DJ: Djibouti
- ER: Eritrea
- SC: Seychelles
- KM: Comoros

### Southern Africa (8)
- ZM: Zambia
- ZW: Zimbabwe
- MW: Malawi
- MZ: Mozambique
- NA: Namibia
- BW: Botswana
- LS: Lesotho
- SZ: Eswatini
- ZA: South Africa

---

## Troubleshooting

### Issue: "permission denied for schema public"
**Solution:** Ensure authenticated user has ADMIN role
```sql
-- Check user role
SELECT role FROM users WHERE id = auth.uid();
```

### Issue: "Relation 'users' does not exist"
**Solution:** Migration assumes users table exists. Run from main auth setup first.

### Issue: RLS blocking valid queries
**Solution:** Run as admin user to test policies:
```sql
-- Verify as admin
SELECT * FROM prepayment_codes LIMIT 1;
```

### Issue: Can't redeem same code twice
**Feature, not bug!** UNIQUE constraint on redeemed_by prevents this.
```sql
-- This will fail (intended):
UPDATE prepayment_codes SET redeemed_by = user_id WHERE code = 'AURA-TN-2024-1M-ABC123';
-- Second time: unique constraint violation
```

---

## Testing Queries

### Generate Test Codes
```sql
-- As admin, generate test code
INSERT INTO prepayment_codes (code, plan_id, region, subscription_duration, created_by, valid_until)
VALUES (
  'AURA-TN-2024-1M-TEST01',
  'solo',
  'TN',
  1,
  auth.uid(),  -- must be admin
  NOW() + INTERVAL '30 days'
);
```

### Redeem Test Code
```sql
-- As user, redeem code
UPDATE prepayment_codes 
SET 
  status = 'redeemed',
  redeemed_by = auth.uid(),
  redeemed_at = NOW(),
  subscription_active_until = NOW() + (subscription_duration || ' months')::INTERVAL
WHERE code = 'AURA-TN-2024-1M-TEST01'
AND status = 'active';
```

### View Audit Trail
```sql
-- As admin, view all code activity
SELECT 
  ca.action,
  ca.performed_by,
  ca.performed_at,
  ca.details
FROM prepayment_code_audit ca
JOIN prepayment_codes pc ON ca.code_id = pc.id
WHERE pc.code = 'AURA-TN-2024-1M-TEST01'
ORDER BY ca.performed_at DESC;
```

---

## Rollback Instructions

If you need to rollback the migration:

```sql
-- Drop triggers first (dependencies)
DROP TRIGGER IF EXISTS trigger_log_code_generation ON prepayment_codes;
DROP TRIGGER IF EXISTS trigger_log_code_redemption ON prepayment_codes;

-- Drop functions
DROP FUNCTION IF EXISTS log_code_generation();
DROP FUNCTION IF EXISTS log_code_redemption();

-- Drop tables
DROP TABLE IF EXISTS prepayment_code_audit;
DROP TABLE IF EXISTS prepayment_codes;

-- Remove columns from users (optional)
ALTER TABLE users DROP COLUMN IF EXISTS prepayment_code_id;
ALTER TABLE users DROP COLUMN IF EXISTS activation_method;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_plan;
ALTER TABLE users DROP COLUMN IF EXISTS subscription_active_until;
```

---

## Next Steps

1. ✅ Run migration on development Supabase project
2. ✅ Test code generation in admin dashboard
3. ✅ Test code redemption in user signup flow
4. ✅ Verify audit logs are created
5. ✅ Run on production when ready

---

## Related Files

- `lib/services/prepayment_code_service.dart` - Service layer
- `lib/prepayment_code_admin_page.dart` - Admin dashboard
- `lib/prepayment_code_page.dart` - User code entry
- `AFRICAN_REGIONAL_SUPPORT.md` - Regional documentation
- `PREPAYMENT_DURATION_UPDATE.md` - Duration feature docs

---

**Last Updated:** January 4, 2026
**Migration Version:** complete_prepayment_system.sql
**Status:** Ready for Production
