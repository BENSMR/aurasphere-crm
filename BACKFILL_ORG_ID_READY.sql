-- ============================================================================
-- BACKFILL SCRIPT: YOUR TWO ORGANIZATIONS
-- ============================================================================
-- Organization 1: "My workshop"
-- ID: d55b394d-7db2-4977-b92b-a97512d7a968
-- Owner: 9821eded-e6f6-4011-b3f4-24172bb51d69
-- Created: 2025-12-24 06:30
--
-- Organization 2: "My workshop"  
-- ID: d31d4700-8b88-4793-b424-fba8e674ab67
-- Owner: 86cd3330-1638-4b4e-aab1-efc4b730f46f
-- Created: 2025-12-24 09:02
--
-- CHOOSE ONE:
-- Option A: Backfill with ORG #1 (the earlier one, created at 06:30)
-- Option B: Backfill with ORG #2 (the later one, created at 09:02)
-- Option C: Backfill BOTH (use separate scripts for each org)
--
-- ============================================================================

-- ============================================================================
-- OPTION A: BACKFILL ALL DATA WITH ORG #1
-- ============================================================================
-- Use this if all your data belongs to the first organization
-- Organization ID: d55b394d-7db2-4977-b92b-a97512d7a968
--
-- Copy and paste this entire section if you choose OPTION A
-- ============================================================================

UPDATE public.invoices 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.clients 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.jobs 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.expenses 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.inventory 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.devices 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.whatsapp_numbers 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.integrations 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.digital_certificates 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

UPDATE public.invoice_signatures 
SET org_id = 'd55b394d-7db2-4977-b92b-a97512d7a968'
WHERE org_id IS NULL;

-- ============================================================================
-- OPTION B: BACKFILL ALL DATA WITH ORG #2
-- ============================================================================
-- Use this if all your data belongs to the second organization
-- Organization ID: d31d4700-8b88-4793-b424-fba8e674ab67
--
-- Copy and paste this entire section if you choose OPTION B
-- ============================================================================

UPDATE public.invoices 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.clients 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.jobs 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.expenses 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.inventory 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.devices 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.whatsapp_numbers 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.integrations 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.digital_certificates 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

UPDATE public.invoice_signatures 
SET org_id = 'd31d4700-8b88-4793-b424-fba8e674ab67'
WHERE org_id IS NULL;

-- ============================================================================
-- OPTION C: BACKFILL WITH BOTH ORGS (Advanced)
-- ============================================================================
-- Use this only if you have data that belongs to BOTH organizations
-- WARNING: This requires manual setup - requires additional context about
-- which records belong to which org
--
-- For now, choose OPTION A or B above
-- ============================================================================

-- ============================================================================
-- VERIFICATION: Run this AFTER backfill completes
-- ============================================================================
-- Copy this to verify no NULL org_ids remain:

SELECT 
  'invoices' as table_name, 
  COUNT(*) as total_rows,
  SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) as null_org_ids
FROM public.invoices
UNION ALL
SELECT 'clients', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.clients
UNION ALL
SELECT 'jobs', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.jobs
UNION ALL
SELECT 'expenses', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.expenses
UNION ALL
SELECT 'inventory', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.inventory
UNION ALL
SELECT 'devices', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.devices
UNION ALL
SELECT 'whatsapp_numbers', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.whatsapp_numbers
UNION ALL
SELECT 'integrations', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.integrations
UNION ALL
SELECT 'digital_certificates', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.digital_certificates
UNION ALL
SELECT 'invoice_signatures', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.invoice_signatures;

-- Expected result: All null_org_ids should be 0

-- ============================================================================
