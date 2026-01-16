⚠️  SCHEMA REPAIR: Missing org_id Column
================================================================================

ERROR: "column 'org_id' does not exist"

ROOT CAUSE: Your database has existing tables that were created WITHOUT the 
org_id column. The CREATE TABLE IF NOT EXISTS statements won't modify 
existing tables.

SOLUTION: Use the schema repair migration script.

================================================================================
✅ NEW FILE CREATED: SCHEMA_REPAIR_MIGRATION.sql
================================================================================

This script:
  ✅ STEP 1: Adds org_id column to ALL existing tables
  ✅ STEP 2: Adds FOREIGN KEY constraints to organizations table
  ✅ STEP 3: Creates/updates the get_user_org_id() function
  ✅ STEP 4: Enables RLS on all tables
  ✅ STEP 5: Drops old policies and creates new ones
  ✅ STEP 6: Creates all necessary indexes

This is SAFE because it uses:
  - ADD COLUMN IF NOT EXISTS (won't fail if column already exists)
  - DROP POLICY IF EXISTS (won't fail if policy doesn't exist)
  - CREATE INDEX IF NOT EXISTS (won't fail if index exists)

================================================================================
🎯 NEXT STEP (3 minutes):
================================================================================

1. Open Supabase SQL Editor:
   → https://app.supabase.com/project/fppmuibvpxrkwmymszhd/sql/new

2. Delete any failed queries

3. Copy ENTIRE SQL from: SCHEMA_REPAIR_MIGRATION.sql

4. Paste and click "Run"

5. Watch for success - should see completion with no errors

================================================================================
✓ WHAT HAPPENS:
================================================================================

BEFORE:
  • invoices table exists → but NO org_id column
  • clients table exists → but NO org_id column
  • Other tables similar situation

AFTER:
  • invoices → org_id column added ✅
  • clients → org_id column added ✅
  • All tables → org_id column exists ✅
  • All tables → RLS enabled ✅
  • All tables → org-level access control policies ✅
  • Database → multi-tenant secure ✅

================================================================================
🔐 VERIFICATION (After migration succeeds):
================================================================================

Run this query to verify org_id columns exist:

  SELECT table_name, column_name 
  FROM information_schema.columns 
  WHERE table_schema='public' AND column_name='org_id'
  ORDER BY table_name;

Expected: Should list 12 tables with org_id column

================================================================================
⚠️  IMPORTANT: Data Migration
================================================================================

If your existing invoices/clients/jobs have data but NO org_id values:

You'll need to UPDATE those rows with org_id values manually.

Example:
  UPDATE invoices SET org_id = 'YOUR_ORG_ID' WHERE org_id IS NULL;

Get YOUR_ORG_ID from:
  SELECT id FROM organizations LIMIT 1;

Or set it when creating your first organization during app signup.

================================================================================
📝 FILES:
================================================================================

Current approach:
  1. SCHEMA_REPAIR_MIGRATION.sql ← USE THIS (fixes existing schema)
  2. COMPLETE_DATABASE_SCHEMA_WITH_RLS.sql (if you want to recreate from scratch)

Recommended: Use SCHEMA_REPAIR_MIGRATION.sql (preserves existing data)

================================================================================
