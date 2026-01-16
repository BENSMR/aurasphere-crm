-- ============================================================================
-- AURASPHERE CRM - COMPLETE DATABASE SCHEMA + RLS MIGRATION
-- ============================================================================
-- IMPORTANT: Run this COMPLETE script in order (don't skip parts)
-- This creates all tables THEN applies RLS policies
-- ============================================================================

-- ============================================================================
-- PHASE 1: CREATE BASE TABLES (Foundation)
-- ============================================================================

-- ORGANIZATIONS (Root tenant)
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan text DEFAULT 'solo', -- 'solo', 'team', 'workshop', 'enterprise'
  name text NOT NULL,
  stripe_status text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ORG_MEMBERS (Team)
CREATE TABLE IF NOT EXISTS org_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text DEFAULT 'member', -- 'owner', 'member', 'viewer'
  email text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(org_id, user_id)
);

-- USER_PROFILES (Critical for RLS - maps auth user to org)
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

-- ============================================================================
-- PHASE 2: CREATE TENANT-SCOPED TABLES (Multi-tenant data)
-- ============================================================================

-- CLIENTS
CREATE TABLE IF NOT EXISTS clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text,
  phone text,
  address text,
  invoice_count int DEFAULT 0,
  total_spent decimal(10, 2) DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- INVOICES
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id uuid REFERENCES clients(id) ON DELETE SET NULL,
  number text NOT NULL,
  amount decimal(10, 2),
  currency text DEFAULT 'USD',
  status text DEFAULT 'draft', -- 'draft', 'sent', 'paid', 'overdue'
  due_date date,
  payment_link text,
  reminder_sent_at timestamptz,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- JOBS
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id uuid REFERENCES clients(id) ON DELETE SET NULL,
  title text NOT NULL,
  status text DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'cancelled'
  assigned_to uuid REFERENCES auth.users(id),
  start_date date,
  end_date date,
  description text,
  materials_needed text,
  cost decimal(10, 2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- EXPENSES
CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  amount decimal(10, 2) NOT NULL,
  category text,
  description text,
  receipt_url text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- INVENTORY
CREATE TABLE IF NOT EXISTS inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  item_name text NOT NULL,
  quantity int DEFAULT 0,
  cost decimal(10, 2),
  low_stock_threshold int,
  last_restocked timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- WHATSAPP_NUMBERS (WhatsApp Business accounts)
CREATE TABLE IF NOT EXISTS whatsapp_numbers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  phone text NOT NULL UNIQUE,
  account_sid text,
  auth_token text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- INTEGRATIONS (Third-party connections)
CREATE TABLE IF NOT EXISTS integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  provider text NOT NULL, -- 'stripe', 'paddle', 'hubspot', 'quickbooks', etc.
  config jsonb, -- OAuth tokens, API keys, settings
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- DEVICES (Mobile device registration)
CREATE TABLE IF NOT EXISTS devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  device_type text NOT NULL, -- 'mobile', 'tablet'
  device_name text,
  reference_code text UNIQUE,
  registered_by uuid REFERENCES auth.users(id),
  registered_at timestamptz DEFAULT now()
);

-- FEATURE_PERSONALIZATION (User feature preferences per device)
CREATE TABLE IF NOT EXISTS feature_personalization (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_type text NOT NULL, -- 'mobile', 'tablet'
  selected_features jsonb DEFAULT '[]'::jsonb,
  is_owner_enforced boolean DEFAULT false,
  enforced_by uuid,
  enforced_at timestamptz,
  disabled_by_owner boolean DEFAULT false,
  disabled_features jsonb,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, device_type)
);

-- DIGITAL_CERTIFICATES (XAdES signing certificates)
CREATE TABLE IF NOT EXISTS digital_certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  certificate_name text NOT NULL,
  certificate_pem text NOT NULL,
  key_password text,
  is_active boolean DEFAULT true,
  valid_from timestamptz,
  valid_until timestamptz,
  created_at timestamptz DEFAULT now()
);

-- INVOICE_SIGNATURES (Signature audit trail)
CREATE TABLE IF NOT EXISTS invoice_signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  invoice_id uuid REFERENCES invoices(id) ON DELETE CASCADE,
  certificate_id uuid REFERENCES digital_certificates(id),
  signed_by uuid REFERENCES auth.users(id),
  xades_xml text,
  xades_level text, -- 'B', 'T', 'C', 'X'
  signed_at timestamptz DEFAULT now()
);

-- ============================================================================
-- PHASE 3: CREATE INDEXES (Performance)
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

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_invoices_org_status ON invoices(org_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_org_status ON jobs(org_id, status);
CREATE INDEX IF NOT EXISTS idx_expenses_org_date ON expenses(org_id, created_at DESC);

-- ============================================================================
-- PHASE 4: CREATE RLS FUNCTION (CRITICAL FOR MULTI-TENANT SECURITY)
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

-- Restrict to authenticated users only (anon cannot call)
REVOKE EXECUTE ON FUNCTION get_user_org_id() FROM anon;
GRANT EXECUTE ON FUNCTION get_user_org_id() TO authenticated;

-- ============================================================================
-- PHASE 5: ENABLE ROW LEVEL SECURITY & CREATE POLICIES
-- ============================================================================

-- ORGANIZATIONS TABLE
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_owner_access"
  ON organizations FOR ALL TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ORG_MEMBERS TABLE
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_members_view_own_team"
  ON org_members FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());
CREATE POLICY "org_members_manage"
  ON org_members FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- USER_PROFILES TABLE
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_profiles_self_view"
  ON user_profiles FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid());
CREATE POLICY "user_profiles_self_update"
  ON user_profiles FOR UPDATE TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

-- INVOICES TABLE
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
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

-- CLIENTS TABLE
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
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

-- JOBS TABLE
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
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

-- EXPENSES TABLE
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
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

-- INVENTORY TABLE
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
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

-- WHATSAPP_NUMBERS TABLE
ALTER TABLE whatsapp_numbers ENABLE ROW LEVEL SECURITY;
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

-- INTEGRATIONS TABLE
ALTER TABLE integrations ENABLE ROW LEVEL SECURITY;
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

-- DEVICES TABLE
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "devices_select"
  ON devices FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());
CREATE POLICY "devices_insert"
  ON devices FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- FEATURE_PERSONALIZATION TABLE
ALTER TABLE feature_personalization ENABLE ROW LEVEL SECURITY;
CREATE POLICY "feature_personalization_select"
  ON feature_personalization FOR SELECT TO authenticated
  USING (user_id = auth.uid());
CREATE POLICY "feature_personalization_update"
  ON feature_personalization FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DIGITAL_CERTIFICATES TABLE
ALTER TABLE digital_certificates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "digital_certs_select"
  ON digital_certificates FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());
CREATE POLICY "digital_certs_insert"
  ON digital_certificates FOR INSERT TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (SELECT 1 FROM organizations WHERE id = org_id AND owner_id = auth.uid())
  );

-- INVOICE_SIGNATURES TABLE
ALTER TABLE invoice_signatures ENABLE ROW LEVEL SECURITY;
CREATE POLICY "invoice_sigs_select"
  ON invoice_signatures FOR SELECT TO authenticated
  USING (org_id = get_user_org_id());

-- ============================================================================
-- PHASE 6: POST-MIGRATION SETUP
-- ============================================================================

-- Create test data structure (optional)
-- NOTE: Run these ONLY if you want to populate initial test data

-- If you need to create a test user:
-- 1. First create user via Supabase Auth dashboard (sign up)
-- 2. Then run this query to link them to an org:
--    INSERT INTO user_profiles (auth_user_id, org_id, full_name) 
--    VALUES ('USER_ID_FROM_AUTH', 'ORG_ID', 'Test User');

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- After migration succeeds, run these to verify:
-- 
-- 1. Check tables exist:
-- SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;
--
-- 2. Check RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables 
-- WHERE schemaname='public' AND rowsecurity=true ORDER BY tablename;
--
-- 3. Check function exists:
-- SELECT proname FROM pg_proc WHERE proname='get_user_org_id';
--
-- 4. Test RLS (as authenticated user):
-- SELECT get_user_org_id(); -- Should return your org_id
-- SELECT COUNT(*) FROM invoices; -- Should return 0 (no data yet)

-- ============================================================================
-- CRITICAL NOTES
-- ============================================================================
-- ✅ This script creates ALL required tables
-- ✅ This script enables RLS on all tables
-- ✅ This script creates the get_user_org_id() security function
-- ✅ All policies enforce org_id filtering (multi-tenant isolation)
-- ✅ Indexes optimize org_id filtering for performance
--
-- NEXT STEPS:
-- 1. Run this complete script in Supabase SQL editor
-- 2. Verify all tables and RLS are created
-- 3. Create test organization and user via app signup
-- 4. Test multi-tenant isolation
-- ============================================================================
