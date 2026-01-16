-- ============================================================================
-- MULTI-TENANT RLS SETUP FOR AURASPHERE CRM
-- ============================================================================
-- COPY THIS ENTIRE SQL AND PASTE INTO SUPABASE SQL EDITOR
-- Project: https://app.supabase.com/project/fppmuibvpxrkwmymszhd/sql/new
-- ============================================================================

-- 1) Helper function: Get current user's organization
-- This is the KEY to all multi-tenant security
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

-- Restrict access to this function (don't let anon call it)
REVOKE EXECUTE ON FUNCTION get_user_org_id() FROM anon;
GRANT EXECUTE ON FUNCTION get_user_org_id() TO authenticated;

-- ============================================================================
-- ORGANIZATIONS TABLE (Owner-only access)
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Owner: Full access to their org
CREATE POLICY "org_owner_access"
  ON organizations
  FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ============================================================================
-- ORG_MEMBERS TABLE (Team access)
-- ============================================================================

ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

-- Members: Can see their team members
CREATE POLICY "org_members_view_own_team"
  ON org_members
  FOR SELECT
  TO authenticated
  USING (
    org_id = get_user_org_id()
  );

-- Members: Owner can manage team
CREATE POLICY "org_members_manage"
  ON org_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- USER_PROFILES TABLE (User context)
-- ============================================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Users: Can view their own profile
CREATE POLICY "user_profiles_self_view"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth_user_id = auth.uid());

-- Users: Can update their own profile
CREATE POLICY "user_profiles_self_update"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

-- ============================================================================
-- INVOICES TABLE (Example: Apply to ALL tenant-scoped tables)
-- ============================================================================

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- SELECT: Can view invoices in their org
CREATE POLICY "invoices_select"
  ON invoices
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

-- INSERT: Can create invoices in their org
CREATE POLICY "invoices_insert"
  ON invoices
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

-- UPDATE: Can update invoices in their org
CREATE POLICY "invoices_update"
  ON invoices
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- DELETE: Owner can delete invoices
CREATE POLICY "invoices_delete"
  ON invoices
  FOR DELETE
  TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- CLIENTS TABLE
-- ============================================================================

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clients_select"
  ON clients
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "clients_insert"
  ON clients
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "clients_update"
  ON clients
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "clients_delete"
  ON clients
  FOR DELETE
  TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- JOBS TABLE
-- ============================================================================

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "jobs_select"
  ON jobs
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "jobs_insert"
  ON jobs
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "jobs_update"
  ON jobs
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "jobs_delete"
  ON jobs
  FOR DELETE
  TO authenticated
  USING (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- EXPENSES TABLE
-- ============================================================================

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "expenses_select"
  ON expenses
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "expenses_insert"
  ON expenses
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "expenses_update"
  ON expenses
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- ============================================================================
-- INVENTORY TABLE
-- ============================================================================

ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "inventory_select"
  ON inventory
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "inventory_insert"
  ON inventory
  FOR INSERT
  TO authenticated
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "inventory_update"
  ON inventory
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- ============================================================================
-- WHATSAPP_NUMBERS TABLE (Org-specific phone accounts)
-- ============================================================================

ALTER TABLE whatsapp_numbers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "whatsapp_select"
  ON whatsapp_numbers
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "whatsapp_insert"
  ON whatsapp_numbers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "whatsapp_update"
  ON whatsapp_numbers
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- ============================================================================
-- INTEGRATIONS TABLE (OAuth tokens, webhook configs, etc.)
-- ============================================================================

ALTER TABLE integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "integrations_select"
  ON integrations
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "integrations_insert"
  ON integrations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "integrations_update"
  ON integrations
  FOR UPDATE
  TO authenticated
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

-- ============================================================================
-- DEVICES TABLE (Mobile device registration)
-- ============================================================================

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "devices_select"
  ON devices
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "devices_insert"
  ON devices
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- FEATURE_PERSONALIZATION TABLE (User feature preferences per device)
-- ============================================================================

ALTER TABLE feature_personalization ENABLE ROW LEVEL SECURITY;

-- Users can see their own feature preferences
CREATE POLICY "feature_personalization_select"
  ON feature_personalization
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can update their own feature preferences
CREATE POLICY "feature_personalization_update"
  ON feature_personalization
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- DIGITAL_CERTIFICATES TABLE (Signing certificates - org-scoped)
-- ============================================================================

ALTER TABLE digital_certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "digital_certs_select"
  ON digital_certificates
  FOR SELECT
  TO authenticated
  USING (org_id = get_user_org_id());

CREATE POLICY "digital_certs_insert"
  ON digital_certificates
  FOR INSERT
  TO authenticated
  WITH CHECK (
    org_id = get_user_org_id()
    AND EXISTS (
      SELECT 1 FROM organizations 
      WHERE id = org_id AND owner_id = auth.uid()
    )
  );

-- ============================================================================
-- INVOICE_SIGNATURES TABLE (Signature audit trail)
-- ============================================================================

ALTER TABLE invoice_signatures ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invoice_sigs_select"
  ON invoice_signatures
  FOR SELECT
  TO authenticated
  USING (
    org_id = get_user_org_id()
  );

-- ============================================================================
-- INDEXES (Performance tuning)
-- ============================================================================

-- All queries filter by org_id first - make sure this is indexed
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

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_invoices_org_status ON invoices(org_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_org_status ON jobs(org_id, status);
CREATE INDEX IF NOT EXISTS idx_expenses_org_date ON expenses(org_id, created_at DESC);

-- ============================================================================
-- VERIFICATION QUERIES (Run these to test RLS is working)
-- ============================================================================

-- Test 1: Can authenticated user in org_id ABC see invoices in that org?
-- SELECT * FROM invoices WHERE org_id = 'ABC'; 
-- Should return invoices if user is member of org ABC

-- Test 2: Can authenticated user see invoices from OTHER org (XYZ)?
-- SELECT * FROM invoices WHERE org_id = 'XYZ';
-- Should return 0 rows (RLS blocks it)

-- Test 3: Verify get_user_org_id() returns correct org
-- SELECT get_user_org_id();
-- Should return the org_id of current user

-- ============================================================================
-- DEPLOYMENT NOTES
-- ============================================================================
-- ✅ This SQL enables row-level security on all tenant-scoped tables
-- ✅ Every authenticated user can only access data from their organization
-- ✅ Owner-only operations (like delete) require ownership check
-- ✅ Anonymous users (anon key) cannot call get_user_org_id()
-- ✅ Indexes optimize org_id filtering for performance
--
-- CRITICAL: After applying this SQL:
-- 1. Test RLS with verification queries above
-- 2. Verify all Supabase queries in Dart include .eq('org_id', orgId)
-- 3. Run CODE_AUDIT_REPORT.md verification checks
-- 4. Test multi-tenant isolation (user A can't see user B's data)
-- ============================================================================
