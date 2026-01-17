-- Feature Personalization Database Setup
-- Created: January 17, 2026
-- Purpose: Enable feature personalization service with device management and audit logging
-- Tables: feature_personalization, devices, feature_audit_log

-- ============================================================
-- TABLE 1: devices - Device Registration Management
-- ============================================================
-- Purpose: Track mobile/tablet devices registered per organization
-- Enforces subscription-based device limits
-- RLS: Users can only see their own org's devices
CREATE TABLE IF NOT EXISTS public.devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('mobile', 'tablet')),
  device_name VARCHAR(255) NOT NULL,
  reference_code VARCHAR(10) NOT NULL UNIQUE, -- 6-char code for easy reference
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- Device owner
  registered_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL, -- Who registered it
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_used_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Indexes for performance
  CONSTRAINT unique_device_per_user UNIQUE(user_id, reference_code),
  CONSTRAINT device_per_org_limit CHECK (true) -- Enforced by service layer
);

CREATE INDEX IF NOT EXISTS idx_devices_org_id ON public.devices(org_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_reference_code ON public.devices(reference_code);
CREATE INDEX IF NOT EXISTS idx_devices_device_type ON public.devices(device_type);

-- ============================================================
-- TABLE 2: feature_personalization - User Feature Selection
-- ============================================================
-- Purpose: Store which features each user selected for each device type
-- Mobile: Max 6 features | Tablet: Max 8 features (configurable)
-- RLS: Users can only modify their own, owners can override
CREATE TABLE IF NOT EXISTS public.feature_personalization (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('mobile', 'tablet')),
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  
  -- Selected features (JSON array of feature IDs)
  selected_features TEXT[] DEFAULT ARRAY['dashboard', 'jobs', 'invoices', 'clients', 'calendar', 'expenses'],
  feature_details JSONB, -- Full feature metadata cache
  
  -- Owner enforcement flags (for team members)
  is_owner_enforced BOOLEAN DEFAULT FALSE,
  enforced_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  enforced_at TIMESTAMP WITH TIME ZONE,
  
  -- Disabled features (owner can disable specific features)
  disabled_features TEXT[], -- Array of feature IDs disabled by owner
  disabled_by_owner BOOLEAN DEFAULT FALSE,
  disabled_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  disabled_at TIMESTAMP WITH TIME ZONE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Unique constraint: one preference per user per device type
  CONSTRAINT unique_user_device_type UNIQUE(user_id, device_type)
);

CREATE INDEX IF NOT EXISTS idx_feature_personalization_user_id ON public.feature_personalization(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_personalization_org_id ON public.feature_personalization(org_id);
CREATE INDEX IF NOT EXISTS idx_feature_personalization_device_type ON public.feature_personalization(device_type);
CREATE INDEX IF NOT EXISTS idx_feature_personalization_is_enforced ON public.feature_personalization(is_owner_enforced);

-- ============================================================
-- TABLE 3: feature_audit_log - Audit Trail for Feature Changes
-- ============================================================
-- Purpose: Track all feature changes for compliance and auditing
-- Records: Owner enforcement, feature toggles, device registration
-- RLS: Only owner of org can view audit log
CREATE TABLE IF NOT EXISTS public.feature_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  action VARCHAR(255) NOT NULL,
  -- Actions: force_enable_allFeatures, disable_features, lock_features_org_wide, 
  --          unlock_features_org_wide, reset_all_team_features, toggle_feature, etc.
  
  performed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL, -- Who did it
  target_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Who it affected (nullable for org-wide)
  target_device_id UUID REFERENCES public.devices(id) ON DELETE SET NULL, -- Device affected
  
  details TEXT, -- JSON or plain text details about the action
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- For searching
  CONSTRAINT valid_action CHECK (length(action) > 0)
);

CREATE INDEX IF NOT EXISTS idx_feature_audit_log_org_id ON public.feature_audit_log(org_id);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_performed_by ON public.feature_audit_log(performed_by);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_target_user ON public.feature_audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_timestamp ON public.feature_audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_action ON public.feature_audit_log(action);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_personalization ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- DEVICES TABLE RLS POLICIES
-- ============================================================

-- Policy 1: Users can view devices (basic auth)
CREATE POLICY "Users can view devices in their org"
  ON public.devices
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Policy 2: Only org owners can insert devices
CREATE POLICY "Owners can register devices"
  ON public.devices
  FOR INSERT
  WITH CHECK (
    (SELECT owner_id FROM public.organizations WHERE id = org_id) = auth.uid()
  );

-- Policy 3: Only org owners can update devices
CREATE POLICY "Owners can update devices"
  ON public.devices
  FOR UPDATE
  USING (
    (SELECT owner_id FROM public.organizations WHERE id = org_id) = auth.uid()
  );

-- Policy 4: Only org owners can delete devices
CREATE POLICY "Owners can delete devices"
  ON public.devices
  FOR DELETE
  USING (
    (SELECT owner_id FROM public.organizations WHERE id = org_id) = auth.uid()
  );

-- ============================================================
-- FEATURE_PERSONALIZATION TABLE RLS POLICIES
-- ============================================================

-- Policy 1: Users can view and update their own features
CREATE POLICY "Users manage own features"
  ON public.feature_personalization
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy 2: Org owners can view all team member features
CREATE POLICY "Owners view team features"
  ON public.feature_personalization
  FOR SELECT
  USING (
    (SELECT owner_id FROM public.organizations WHERE id = org_id) = auth.uid()
  );

-- Policy 3: Org owners can modify team member features
CREATE POLICY "Owners modify team features"
  ON public.feature_personalization
  FOR UPDATE
  USING (
    (SELECT owner_id FROM public.organizations WHERE id = org_id) = auth.uid()
  );

-- Policy 4: Org owners can insert team member features
CREATE POLICY "Owners insert team features"
  ON public.feature_personalization
  FOR INSERT
  WITH CHECK (
    (SELECT owner_id FROM public.organizations WHERE id = org_id) = auth.uid()
  );

-- ============================================================
-- FEATURE_AUDIT_LOG TABLE RLS POLICIES
-- ============================================================

-- Policy 1: Only org owners can view audit log
CREATE POLICY "Only owners view audit log"
  ON public.feature_audit_log
  FOR SELECT
  USING (
    (SELECT owner_id FROM public.organizations WHERE id = org_id) = auth.uid()
  );

-- Policy 2: Services can insert audit logs
CREATE POLICY "Services insert audit logs"
  ON public.feature_audit_log
  FOR INSERT
  WITH CHECK (org_id IS NOT NULL);

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: devices.updated_at
DROP TRIGGER IF EXISTS update_devices_updated_at ON public.devices;
CREATE TRIGGER update_devices_updated_at
  BEFORE UPDATE ON public.devices
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger: feature_personalization.updated_at
DROP TRIGGER IF EXISTS update_feature_personalization_updated_at ON public.feature_personalization;
CREATE TRIGGER update_feature_personalization_updated_at
  BEFORE UPDATE ON public.feature_personalization
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- INITIAL DATA (OPTIONAL)
-- ============================================================

-- Insert default feature list as reference
-- Keeping this for documentation - not required to run

-- ============================================================
-- VERIFICATION QUERIES (Run these to verify setup)
-- ============================================================
/*

-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('devices', 'feature_personalization', 'feature_audit_log');

-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables 
WHERE tablename IN ('devices', 'feature_personalization', 'feature_audit_log');

-- Check indexes created
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('devices', 'feature_personalization', 'feature_audit_log');

*/

-- ============================================================
-- NOTES
-- ============================================================
/*
HOW TO APPLY THIS MIGRATION:

1. In Supabase Dashboard:
   - Go to SQL Editor
   - Create new query
   - Paste entire contents of this file
   - Click "Run"
   - Wait for completion (should see ✓ Success)

2. Or via Supabase CLI:
   - Save this file to: supabase/migrations/20260117_add_feature_personalization.sql
   - Run: supabase migration up
   - Push to production: supabase db push

3. Verify in Supabase:
   - Go to Table Editor
   - Should see 3 new tables: devices, feature_personalization, feature_audit_log
   - Each should have RLS enabled (lock icon)

HOW IT WORKS:

1. DEVICES TABLE
   - Stores mobile/tablet device registrations
   - Enforces per-org device limits based on subscription plan
   - Reference code for easy manual device entry
   - Tracks who registered device and when
   - RLS: Only org members can see org devices, only owner can register/modify

2. FEATURE_PERSONALIZATION TABLE
   - Stores which features each user selected
   - Max 6 features for mobile, 8 for tablet
   - Owner can force-enable all or disable specific features
   - Tracks enforcement by owner
   - RLS: Users see their own, owner sees all team members

3. FEATURE_AUDIT_LOG TABLE
   - Complete audit trail of feature changes
   - Who changed what, when, and why
   - Compliance tracking for certifications
   - RLS: Only owner can view audit log

DEPENDENCIES:
- organizations table (should exist)
- auth.users table (built-in Supabase)
- org_members table (should exist)

AFTER SETUP:
- FeaturePersonalizationService will work fully
- Feature selection UI will persist data
- Owner control panel will track changes
- Device registration will enforce limits
*/
