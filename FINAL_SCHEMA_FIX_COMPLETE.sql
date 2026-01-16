-- ============================================================================
-- COMPLETE FIX: Handle BOTH missing org_id columns AND missing tables
-- ============================================================================
-- This script fixes the "column org_id does not exist" error by:
-- 1. Adding org_id to existing tables that lack it
-- 2. Creating new tables that don't exist
-- 3. Creating RLS function and policies
-- ============================================================================

-- ============================================================================
-- PHASE 1: ADD org_id COLUMN TO EXISTING TABLES (idempotent)
-- ============================================================================

ALTER TABLE IF EXISTS invoices ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS clients ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS jobs ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS expenses ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS inventory ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS whatsapp_numbers ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS integrations ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS devices ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS digital_certificates ADD COLUMN IF NOT EXISTS org_id uuid;
ALTER TABLE IF EXISTS invoice_signatures ADD COLUMN IF NOT EXISTS org_id uuid;

-- ============================================================================
-- PHASE 2: CREATE REQUIRED BASE TABLES (if they don't exist)
-- ============================================================================

CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan text DEFAULT 'solo',
  name text NOT NULL,
  stripe_status text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  full_name text,
  avatar_url text,
  language text DEFAULT 'en',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS org_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text DEFAULT 'member',
  email text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(org_id, user_id)
);

-- ============================================================================
-- PHASE 3: ADD FOREIGN KEY CONSTRAINTS TO org_id IN EXISTING TABLES
-- ============================================================================

ALTER TABLE IF EXISTS invoices 
ADD CONSTRAINT fk_invoices_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS clients 
ADD CONSTRAINT fk_clients_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS jobs 
ADD CONSTRAINT fk_jobs_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS expenses 
ADD CONSTRAINT fk_expenses_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS inventory 
ADD CONSTRAINT fk_inventory_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS whatsapp_numbers 
ADD CONSTRAINT fk_whatsapp_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS integrations 
ADD CONSTRAINT fk_integrations_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS devices 
ADD CONSTRAINT fk_devices_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS digital_certificates 
ADD CONSTRAINT fk_digital_certs_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS invoice_signatures 
ADD CONSTRAINT fk_invoice_sigs_org_id FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

-- ============================================================================
-- PHASE 4: CREATE REMAINING TABLES (if they don't exist)
-- ============================================================================

CREATE TABLE IF NOT EXISTS feature_personalization (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_type text NOT NULL,
  selected_features jsonb DEFAULT '[]'::jsonb,
  is_owner_enforced boolean DEFAULT false,
  enforced_by uuid,
  enforced_at timestamptz,
  disabled_by_owner boolean DEFAULT false,
  disabled_features jsonb,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, device_type)
);

-- ============================================================================
-- PHASE 5: CREATE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_invoices_org_id ON invoices(org_id);
CREATE INDEX IF NOT EXISTS idx_clients_org_id ON clients(org_id);
CREATE INDEX IF NOT EXISTS idx_jobs_org_id ON jobs(org_id);
CREATE INDEX IF NOT EXISTS idx_expenses_org_id ON expenses(org_id);
CREATE INDEX IF NOT EXISTS idx_inventory_org_id ON inventory(org_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON org_members(org_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_org_id ON user_profiles(org_id);
CREATE INDEX IF NOT EXISTS idx_devices_org_id ON devices(org_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_org_id ON whatsapp_numbers(org_id);
CREATE INDEX IF NOT EXISTS idx_integrations_org_id ON integrations(org_id);
CREATE INDEX IF NOT EXISTS idx_digital_certs_org_id ON digital_certificates(org_id);
CREATE INDEX IF NOT EXISTS idx_invoice_sigs_org_id ON invoice_signatures(org_id);

CREATE INDEX IF NOT EXISTS idx_invoices_org_status ON invoices(org_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_org_status ON jobs(org_id, status);
CREATE INDEX IF NOT EXISTS idx_expenses_org_date ON expenses(org_id, created_at DESC);

-- ============================================================================
-- PHASE 6: CREATE RLS FUNCTION (now user_profiles definitely exists)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_org_id() 
RETURNS uuid 
LANGUAGE sql 
SECURITY DEFINER 
STABLE 
AS $$
  SELECT org_id 
  FROM user_profiles 
  WHERE auth_user_id = auth.uid()
  LIMIT 1;
$$;

REVOKE EXECUTE ON FUNCTION get_user_org_id() FROM anon;
GRANT EXECUTE ON FUNCTION get_user_org_id() TO authenticated;

-- ============================================================================
-- PHASE 7: ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_personalization ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_signatures ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PHASE 8: DROP OLD POLICIES AND CREATE NEW ONES
-- ============================================================================

DROP POLICY IF EXISTS "org_owner_access" ON organizations;
DROP POLICY IF EXISTS "org_members_view_own_team" ON org_members;
DROP POLICY IF EXISTS "org_members_manage" ON org_members;
DROP POLICY IF EXISTS "user_profiles_self_view" ON user_profiles;
DROP POLICY IF EXISTS "user_profiles_self_update" ON user_profiles;
DROP POLICY IF EXISTS "invoices_select" ON invoices;
DROP POLICY IF EXISTS "invoices_insert" ON invoices;
DROP POLICY IF EXISTS "invoices_update" ON invoices;
DROP POLICY IF EXISTS "invoices_delete" ON invoices;
DROP POLICY IF EXISTS "clients_select" ON clients;
DROP POLICY IF EXISTS "clients_insert" ON clients;
DROP POLICY IF EXISTS "clients_update" ON clients;
DROP POLICY IF EXISTS "clients_delete" ON clients;
DROP POLICY IF EXISTS "jobs_select" ON jobs;
DROP POLICY IF EXISTS "jobs_insert" ON jobs;
DROP POLICY IF EXISTS "jobs_update" ON jobs;
DROP POLICY IF EXISTS "jobs_delete" ON jobs;
DROP POLICY IF EXISTS "expenses_select" ON expenses;
DROP POLICY IF EXISTS "expenses_insert" ON expenses;
DROP POLICY IF EXISTS "expenses_update" ON expenses;
DROP POLICY IF EXISTS "inventory_select" ON inventory;
DROP POLICY IF EXISTS "inventory_insert" ON inventory;
DROP POLICY IF EXISTS "inventory_update" ON inventory;
DROP POLICY IF EXISTS "whatsapp_select" ON whatsapp_numbers;
DROP POLICY IF EXISTS "whatsapp_insert" ON whatsapp_numbers;
DROP POLICY IF EXISTS "whatsapp_update" ON whatsapp_numbers;
DROP POLICY IF EXISTS "integrations_select" ON integrations;
DROP POLICY IF EXISTS "integrations_insert" ON integrations;
DROP POLICY IF EXISTS "integrations_update" ON integrations;
DROP POLICY IF EXISTS "devices_select" ON devices;
DROP POLICY IF EXISTS "devices_insert" ON devices;
DROP POLICY IF EXISTS "feature_personalization_select" ON feature_personalization;
DROP POLICY IF EXISTS "feature_personalization_update" ON feature_personalization;
DROP POLICY IF EXISTS "digital_certs_select" ON digital_certificates;
DROP POLICY IF EXISTS "digital_certs_insert" ON digital_certificates;
DROP POLICY IF EXISTS "invoice_sigs_select" ON invoice_signatures;

-- ORGANIZATIONS POLICIES
CREATE POLICY "org_owner_access"
  ON organizations FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ORG_MEMBERS POLICIES
CREATE POLICY "org_members_view_own_team"
  ON org_members FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "org_members_manage"
  ON org_members FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- USER_PROFILES POLICIES
CREATE POLICY "user_profiles_self_view"
  ON user_profiles FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid());

CREATE POLICY "user_profiles_self_update"
  ON user_profiles FOR UPDATE TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

-- INVOICES POLICIES
CREATE POLICY "invoices_select"
  ON invoices FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "invoices_insert"
  ON invoices FOR INSERT TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "invoices_update"
  ON invoices FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "invoices_delete"
  ON invoices FOR DELETE TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- CLIENTS POLICIES
CREATE POLICY "clients_select"
  ON clients FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "clients_insert"
  ON clients FOR INSERT TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "clients_update"
  ON clients FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "clients_delete"
  ON clients FOR DELETE TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- JOBS POLICIES
CREATE POLICY "jobs_select"
  ON jobs FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "jobs_insert"
  ON jobs FOR INSERT TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "jobs_update"
  ON jobs FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "jobs_delete"
  ON jobs FOR DELETE TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- EXPENSES POLICIES
CREATE POLICY "expenses_select"
  ON expenses FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "expenses_insert"
  ON expenses FOR INSERT TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "expenses_update"
  ON expenses FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- INVENTORY POLICIES
CREATE POLICY "inventory_select"
  ON inventory FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "inventory_insert"
  ON inventory FOR INSERT TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "inventory_update"
  ON inventory FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- WHATSAPP_NUMBERS POLICIES
CREATE POLICY "whatsapp_select"
  ON whatsapp_numbers FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "whatsapp_insert"
  ON whatsapp_numbers FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

CREATE POLICY "whatsapp_update"
  ON whatsapp_numbers FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- INTEGRATIONS POLICIES
CREATE POLICY "integrations_select"
  ON integrations FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "integrations_insert"
  ON integrations FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

CREATE POLICY "integrations_update"
  ON integrations FOR UPDATE TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- DEVICES POLICIES
CREATE POLICY "devices_select"
  ON devices FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "devices_insert"
  ON devices FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- FEATURE_PERSONALIZATION POLICIES
CREATE POLICY "feature_personalization_select"
  ON feature_personalization FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "feature_personalization_update"
  ON feature_personalization FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DIGITAL_CERTIFICATES POLICIES
CREATE POLICY "digital_certs_select"
  ON digital_certificates FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "digital_certs_insert"
  ON digital_certificates FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- INVOICE_SIGNATURES POLICIES
CREATE POLICY "invoice_sigs_select"
  ON invoice_signatures FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

-- ============================================================================
-- SUCCESS: All 14 tables now have org_id with RLS enabled
-- ============================================================================
