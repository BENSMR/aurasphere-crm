-- ============================================================================
-- EXECUTION PLAN: Complete RLS Setup for Organization A
-- ============================================================================
-- Organization: d55b394d-7db2-4977-b92b-a97512d7a968
-- Status: Ready to Execute
-- Timeline: ~10 minutes
-- ============================================================================

-- ============================================================================
-- STEP 1: BACKFILL org_id FOR ALL NULL VALUES
-- ============================================================================
-- Copy this entire section and paste into Supabase SQL Editor
-- Timeline: 1 minute
-- Safety: Only updates rows where org_id IS NULL
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
-- STEP 2: CREATE AUTO-ASSIGN ORG_ID TRIGGERS
-- ============================================================================
-- Copy this entire section and paste into Supabase SQL Editor
-- Timeline: 1 minute
-- Benefit: Prevents NULL org_id on future INSERTs
-- ============================================================================

-- Create the trigger function
CREATE OR REPLACE FUNCTION public.set_org_id_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.org_id IS NULL THEN
    NEW.org_id := (
      SELECT org_id 
      FROM public.user_profiles 
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing triggers if they exist (safe to re-run)
DROP TRIGGER IF EXISTS trigger_invoices_set_org_id ON public.invoices CASCADE;
DROP TRIGGER IF EXISTS trigger_clients_set_org_id ON public.clients CASCADE;
DROP TRIGGER IF EXISTS trigger_jobs_set_org_id ON public.jobs CASCADE;
DROP TRIGGER IF EXISTS trigger_expenses_set_org_id ON public.expenses CASCADE;
DROP TRIGGER IF EXISTS trigger_inventory_set_org_id ON public.inventory CASCADE;
DROP TRIGGER IF EXISTS trigger_devices_set_org_id ON public.devices CASCADE;
DROP TRIGGER IF EXISTS trigger_whatsapp_set_org_id ON public.whatsapp_numbers CASCADE;
DROP TRIGGER IF EXISTS trigger_integrations_set_org_id ON public.integrations CASCADE;
DROP TRIGGER IF EXISTS trigger_digital_certs_set_org_id ON public.digital_certificates CASCADE;
DROP TRIGGER IF EXISTS trigger_invoice_sigs_set_org_id ON public.invoice_signatures CASCADE;

-- Create triggers on all tenant-scoped tables
CREATE TRIGGER trigger_invoices_set_org_id 
  BEFORE INSERT ON public.invoices
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_clients_set_org_id 
  BEFORE INSERT ON public.clients
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_jobs_set_org_id 
  BEFORE INSERT ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_expenses_set_org_id 
  BEFORE INSERT ON public.expenses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_inventory_set_org_id 
  BEFORE INSERT ON public.inventory
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_devices_set_org_id 
  BEFORE INSERT ON public.devices
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_whatsapp_set_org_id 
  BEFORE INSERT ON public.whatsapp_numbers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_integrations_set_org_id 
  BEFORE INSERT ON public.integrations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_digital_certs_set_org_id 
  BEFORE INSERT ON public.digital_certificates
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

CREATE TRIGGER trigger_invoice_sigs_set_org_id 
  BEFORE INSERT ON public.invoice_signatures
  FOR EACH ROW
  EXECUTE FUNCTION public.set_org_id_on_insert();

-- ============================================================================
-- STEP 3: RUN FULL HARDENING SCRIPT
-- ============================================================================
-- Copy entire content of: FINAL_SCHEMA_MIGRATION.sql
-- Timeline: 2 minutes
-- File Location: c:\Users\PC\AuraSphere\crm\aura_crm\FINAL_SCHEMA_MIGRATION.sql
-- ============================================================================
-- Instructions:
-- 1. Open: https://app.supabase.com/project/fppmuibvpxrkwmymszhd/sql/new
-- 2. Open: FINAL_SCHEMA_MIGRATION.sql in your editor
-- 3. SELECT ALL (Ctrl+A) and COPY
-- 4. Paste into Supabase SQL Editor
-- 5. Click "Run"
-- 6. Wait for success message

-- ============================================================================
-- STEP 4: VERIFICATION QUERIES
-- ============================================================================
-- Copy this entire section and paste into Supabase SQL Editor
-- Timeline: 2 minutes
-- Purpose: Confirm all changes applied successfully
-- ============================================================================

-- Query 1: Verify no NULL org_ids remain
SELECT 
  'invoices' as table_name, 
  COUNT(*) as total_rows,
  SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) as null_org_ids,
  SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 as is_clean
FROM public.invoices
UNION ALL
SELECT 'clients', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.clients
UNION ALL
SELECT 'jobs', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.jobs
UNION ALL
SELECT 'expenses', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.expenses
UNION ALL
SELECT 'inventory', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.inventory
UNION ALL
SELECT 'devices', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.devices
UNION ALL
SELECT 'whatsapp_numbers', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.whatsapp_numbers
UNION ALL
SELECT 'integrations', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.integrations
UNION ALL
SELECT 'digital_certificates', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.digital_certificates
UNION ALL
SELECT 'invoice_signatures', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) = 0 FROM public.invoice_signatures;

-- Expected: All is_clean should be TRUE (all null_org_ids = 0)

-- ============================================================================

-- Query 2: Verify RLS is enabled on all tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname='public'
ORDER BY tablename;

-- Expected: All public tables should show rowsecurity=true

-- ============================================================================

-- Query 3: Verify get_user_org_id() function exists
SELECT proname, prokind
FROM pg_proc
WHERE proname='get_user_org_id' AND prokind='f';

-- Expected: 1 row (function exists and is callable)

-- ============================================================================

-- Query 4: Verify triggers exist
SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema='public'
ORDER BY event_object_table, trigger_name;

-- Expected: 10 triggers total (one BEFORE INSERT on each tenant table)
-- Triggers:
-- - trigger_invoices_set_org_id
-- - trigger_clients_set_org_id
-- - trigger_jobs_set_org_id
-- - trigger_expenses_set_org_id
-- - trigger_inventory_set_org_id
-- - trigger_devices_set_org_id
-- - trigger_whatsapp_set_org_id
-- - trigger_integrations_set_org_id
-- - trigger_digital_certs_set_org_id
-- - trigger_invoice_sigs_set_org_id

-- ============================================================================

-- Query 5: Check how many policies are created
SELECT schemaname, tablename, policyname, permissive
FROM pg_policies
WHERE schemaname='public'
ORDER BY tablename, policyname;

-- Expected: 30+ RLS policies across 14 tables
-- Sample policies:
-- - org_owner_access (organizations)
-- - org_members_view_own_team (org_members)
-- - invoices_select, invoices_insert, invoices_update, invoices_delete
-- - clients_select, clients_insert, clients_update, clients_delete
-- - jobs_select, jobs_insert, jobs_update, jobs_delete
-- - expenses_select, expenses_insert, expenses_update
-- - inventory_select, inventory_insert, inventory_update
-- - whatsapp_select, whatsapp_insert, whatsapp_update
-- - integrations_select, integrations_insert, integrations_update
-- - devices_select, devices_insert
-- - feature_personalization_select, feature_personalization_update
-- - digital_certs_select, digital_certs_insert
-- - invoice_sigs_select

-- ============================================================================
-- SUCCESS INDICATORS
-- ============================================================================
-- ✅ All NULL org_ids are backfilled (is_clean = TRUE for all tables)
-- ✅ RLS is enabled (rowsecurity=true for all public tables)
-- ✅ get_user_org_id() function exists
-- ✅ 10 auto-assign triggers created
-- ✅ 30+ RLS policies created
-- ✅ All indexes created
--
-- When you see all these, your database is:
-- ✅ SECURE: Multi-tenant isolation enforced at DB level
-- ✅ COMPLIANT: RLS prevents unauthorized data access
-- ✅ PRODUCTION-READY: Safe to deploy to staging/production
-- ============================================================================
