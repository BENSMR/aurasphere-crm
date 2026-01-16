-- ============================================================================
-- FIX: 401 Invalid API Key - Verify Supabase Credentials
-- ============================================================================
-- Issue: 401 error when app tries to connect
-- Root Cause: Either wrong URL or wrong anon key
-- Solution: Verify and correct credentials in main.dart
-- ============================================================================

-- This script doesn't need to run in Supabase
-- Instead, follow the troubleshooting steps below

-- ============================================================================
-- TROUBLESHOOTING STEPS (Do these manually)
-- ============================================================================

-- Step 1: Verify Supabase URL and Key match Supabase Dashboard
-- Go to: https://app.supabase.com/project/fppmuibvpxrkwmymszhd/settings/api
-- Copy the EXACT values:

-- Your Project URL should be:
-- https://fppmuibvpxrkwmymszhd.supabase.co

-- Your anon (public) key should be:
-- eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA

-- Step 2: Update lib/main.dart with EXACT values
-- Lines 6-7 must match exactly

-- Step 3: If they don't match, your project might have been recreated
-- Check if fppmuibvpxrkwmymszhd is the CURRENT project ID

-- ============================================================================
-- ALTERNATIVE FIX: Check Supabase Project Health
-- ============================================================================
-- Run this query in Supabase SQL Editor to verify database is working:

SELECT 1 as "connection_test";
-- Expected: Returns 1 (database is working)

-- Verify you can access tables:
SELECT COUNT(*) as organizations_count FROM public.organizations;
-- Expected: Returns a number (not an error)

-- ============================================================================
-- MOST LIKELY ISSUE: Project Mismatch or Key Regeneration
-- ============================================================================

-- If the URL/key don't match the dashboard, the project may have been:
-- 1. Deleted and recreated (new project ID)
-- 2. Credentials were rotated (need new key)
-- 3. Wrong project name in code

-- ACTION: Go to Supabase Dashboard and verify:
-- - Project ID: fppmuibvpxrkwmymszhd (should match URL)
-- - Anon Key starts with: eyJhbGci...

-- If different, update main.dart with the CORRECT values from dashboard

-- ============================================================================
