-- ===============================================
-- AuraSphere CRM - Pre-Launch SQL Deployment
-- ===============================================
-- Run these migrations in order in Supabase SQL Editor
-- Date: January 16, 2026
-- Status: Ready to Deploy
-- ===============================================

-- Step 1: Verify Supabase Connection
-- Run this first to test your connection
SELECT version() AS postgres_version;

-- Step 2: Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===============================================
-- STEP 3: Run Core Schema Setup
-- ===============================================
-- File: database_schema_setup.sql
-- This creates white-label settings, backup records, and core tables
-- Lines: 261
-- Status: Ready

-- ===============================================
-- STEP 4: Run Migration 1 - African Prepayment Codes
-- ===============================================
-- File: 20260105_create_african_prepayment_codes.sql  
-- Prepayment code system for 54 African countries
-- Lines: 135
-- Status: Ready

-- ===============================================
-- STEP 5: Run Migration 2 - Digital Signatures
-- ===============================================
-- File: 20260110_add_digital_signatures.sql
-- XAdES-B/T/C/X invoice signing
-- Lines: Complete
-- Status: Ready

-- ===============================================
-- STEP 6: Run Migration 3 - Owner Feature Control
-- ===============================================
-- File: 20260111_add_owner_feature_control.sql
-- Feature personalization with device limits
-- Lines: Complete
-- Status: Ready

-- ===============================================
-- STEP 7: Run Migration 4 - CloudGuard FinOps
-- ===============================================
-- File: 20260114_add_cloudguard_finops.sql
-- Cloud expense tracking & waste detection
-- Lines: 309
-- Status: Ready

-- ===============================================
-- VERIFICATION STEPS (Run after migrations)
-- ===============================================

-- Verify all tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Verify RLS is enabled on critical tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true
ORDER BY tablename;

-- Verify auth users table exists
SELECT COUNT(*) as user_count FROM auth.users;

-- Verify organizations table
SELECT COUNT(*) as org_count FROM organizations;

-- Verify org_members table
SELECT COUNT(*) as member_count FROM org_members;

-- ===============================================
-- TROUBLESHOOTING
-- ===============================================

-- If you get RLS policy errors:
-- 1. Ensure you're logged in as Supabase admin
-- 2. OR run this to disable RLS temporarily:
--    ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- If you get foreign key constraint errors:
-- 1. Run migrations in order (they depend on each other)
-- 2. Ensure organizations table exists before org_members

-- If Edge Functions fail to deploy:
-- 1. Verify all secrets are set: Settings → Secrets
-- 2. Run Edge Functions after database migrations
-- 3. Check function logs: Supabase Dashboard → Edge Functions

-- ===============================================
-- DEPLOYMENT CHECKLIST
-- ===============================================
-- [ ] Run database_schema_setup.sql
-- [ ] Run 20260105_create_african_prepayment_codes.sql
-- [ ] Run 20260110_add_digital_signatures.sql
-- [ ] Run 20260111_add_owner_feature_control.sql
-- [ ] Run 20260114_add_cloudguard_finops.sql
-- [ ] Verify all tables created (see verification queries above)
-- [ ] Configure authentication providers
-- [ ] Set Supabase secrets for Edge Functions
-- [ ] Deploy Edge Functions
-- [ ] Test signup/login in Flutter app
-- [ ] Verify payments (Stripe/Paddle)
-- [ ] Monitor error logs

-- ===============================================
-- ESTIMATED TIME: 5-10 minutes
-- ===============================================
-- Database: ~2-3 minutes (migrations)
-- Configuration: ~3-5 minutes (secrets, providers)
-- Verification: ~2-3 minutes (testing)
-- Edge Functions: ~1-2 minutes (deployment)
-- Total: ~10-15 minutes to full readiness

-- Status: ✅ READY TO DEPLOY
-- Generated: January 16, 2026
-- Version: Pre-Launch v1.0
