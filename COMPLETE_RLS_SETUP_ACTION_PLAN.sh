#!/bin/bash
# ============================================================================
# COMPLETE RLS SETUP & DATA BACKFILL SCRIPT
# ============================================================================
# Purpose: Apply all RLS hardening + backfill org_id + create auto-assign triggers
# Status: TEMPLATE - waiting for your organization UUID
# ============================================================================

# STEP 1: IDENTIFY YOUR ORGANIZATION UUID
# ============================================================================
# Run this query in Supabase SQL Editor to get your org_id:
#
# SELECT id, name, owner_id 
# FROM public.organizations 
# ORDER BY created_at DESC 
# LIMIT 1;
#
# Replace YOUR_ORG_UUID in all queries below with the actual UUID
#
# Example: a1b2c3d4-e5f6-7890-abcd-ef1234567890
#

YOUR_ORG_UUID="YOUR_ORG_UUID_HERE"

# ============================================================================
# STEP 2: VERIFY NO EXISTING DATA (Optional)
# ============================================================================
# Run this to see current state:
#
# SELECT 
#   'invoices' as table_name, 
#   COUNT(*) as total_rows,
#   SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) as null_org_ids
# FROM public.invoices
# UNION ALL
# SELECT 'clients', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.clients
# UNION ALL
# SELECT 'jobs', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.jobs
# UNION ALL
# SELECT 'expenses', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.expenses
# UNION ALL
# SELECT 'inventory', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.inventory
# UNION ALL
# SELECT 'devices', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.devices
# UNION ALL
# SELECT 'whatsapp_numbers', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.whatsapp_numbers
# UNION ALL
# SELECT 'integrations', COUNT(*), SUM(CASE WHEN org_id IS NULL THEN 1 ELSE 0 END) FROM public.integrations;

# ============================================================================
# STEP 3: BACKFILL org_id (Run if you have data with NULL org_ids)
# ============================================================================
# This safely updates only rows where org_id IS NULL
# It's safe to run multiple times (idempotent)
#

# BACKFILL SCRIPT:
# ============================================================================
-- Update invoices
UPDATE public.invoices 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update clients
UPDATE public.clients 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update jobs
UPDATE public.jobs 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update expenses
UPDATE public.expenses 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update inventory
UPDATE public.inventory 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update devices
UPDATE public.devices 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update whatsapp_numbers
UPDATE public.whatsapp_numbers 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update integrations
UPDATE public.integrations 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update digital_certificates
UPDATE public.digital_certificates 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;

-- Update invoice_signatures
UPDATE public.invoice_signatures 
SET org_id = 'YOUR_ORG_UUID_HERE' 
WHERE org_id IS NULL;
# ============================================================================

# ============================================================================
# STEP 4: CREATE AUTO-ASSIGN TRIGGERS (Recommended)
# ============================================================================
# These triggers automatically assign org_id on INSERT
# Prevents NULL org_id going forward
#

-- STEP 4a: Create the trigger function
CREATE OR REPLACE FUNCTION public.set_org_id_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Only set org_id if it's NULL or not provided
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

-- STEP 4b: Create triggers on all tenant-scoped tables
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

# ============================================================================

# ============================================================================
# STEP 5: RUN FULL HARDENING SCRIPT
# ============================================================================
# After backfill and triggers are complete, run FINAL_SCHEMA_FIX_COMPLETE.sql
# This applies all remaining RLS policies and composite indexes
#

# Command:
# 1. Open: https://app.supabase.com/project/fppmuibvpxrkwmymszhd/sql/new
# 2. Copy entire content of: FINAL_SCHEMA_FIX_COMPLETE.sql
# 3. Paste and click "Run"
# 4. Watch for success message

# ============================================================================

# ============================================================================
# STEP 6: VERIFICATION QUERIES
# ============================================================================
# Run these AFTER all updates to confirm success:
#

-- Verify no NULL org_ids remain
SELECT 
  'invoices' as table_name, 
  COUNT(*) as null_org_ids
FROM public.invoices
WHERE org_id IS NULL
UNION ALL
SELECT 'clients', COUNT(*) FROM public.clients WHERE org_id IS NULL
UNION ALL
SELECT 'jobs', COUNT(*) FROM public.jobs WHERE org_id IS NULL
UNION ALL
SELECT 'expenses', COUNT(*) FROM public.expenses WHERE org_id IS NULL
UNION ALL
SELECT 'inventory', COUNT(*) FROM public.inventory WHERE org_id IS NULL
UNION ALL
SELECT 'devices', COUNT(*) FROM public.devices WHERE org_id IS NULL
UNION ALL
SELECT 'whatsapp_numbers', COUNT(*) FROM public.whatsapp_numbers WHERE org_id IS NULL
UNION ALL
SELECT 'integrations', COUNT(*) FROM public.integrations WHERE org_id IS NULL;
-- Expected result: All rows show 0

-- Verify RLS is enabled on all tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname='public'
ORDER BY tablename;
-- Expected: All tables should show rowsecurity=true

-- Verify triggers exist
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema='public'
ORDER BY event_object_table;
-- Expected: 10 triggers (one per tenant table)

# ============================================================================

# ============================================================================
# TIMELINE
# ============================================================================
# Step 1: Get org_id from database        → 2 minutes
# Step 2: Verify current state (optional) → 2 minutes
# Step 3: Backfill org_id                 → 1 minute
# Step 4: Create triggers                 → 1 minute
# Step 5: Run hardening script            → 2 minutes
# Step 6: Verify success                  → 2 minutes
# TOTAL:                                   → ~10 minutes
# ============================================================================

# ============================================================================
# EMERGENCY ROLLBACK (if something goes wrong)
# ============================================================================
# These queries let you undo changes safely:
#

-- Drop triggers if needed
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

-- Drop function if needed
DROP FUNCTION IF EXISTS public.set_org_id_on_insert() CASCADE;

-- Revert backfill (set org_id back to NULL) - only if absolutely needed
-- WARNING: Only run if you made a mistake above
-- UPDATE public.invoices SET org_id = NULL WHERE org_id = 'WRONG_ORG_UUID';

# ============================================================================

