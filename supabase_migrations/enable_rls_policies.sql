-- AuraSphere CRM - Row Level Security (RLS) Policies
-- 
-- CRITICAL: Run this SQL in Supabase Dashboard to enable RLS on all tables
-- This prevents users from accessing other organizations' data
-- 
-- Steps to enable RLS:
-- 1. Go to Supabase Dashboard → Database → Tables
-- 2. For EACH table below, click "Row Level Security" toggle to ENABLE
-- 3. Copy and run this entire SQL file in the SQL Editor
-- 4. Test RLS by running queries in different user contexts

-- ============================================================================
-- 1. ORGANIZATIONS - Users can only access their own organization
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view only their own organization
CREATE POLICY "Users can view own organization"
  ON organizations
  FOR SELECT
  USING (owner_id = auth.uid());

-- Policy: Owners can update their organization
CREATE POLICY "Owners can update their organization"
  ON organizations
  FOR UPDATE
  USING (owner_id = auth.uid());

-- Policy: Owners can delete their organization
CREATE POLICY "Owners can delete their organization"
  ON organizations
  FOR DELETE
  USING (owner_id = auth.uid());

-- ============================================================================
-- 2. USERS (Team Members) - Users can view team members in their org only
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own team members
CREATE POLICY "Users can view own team members"
  ON users
  FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
  );

-- Policy: Only owner can add/remove team members
CREATE POLICY "Owners can manage team members"
  ON users
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
  );

-- ============================================================================
-- 3. CLIENTS - Access only clients of their organization
-- ============================================================================

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view clients in their organization
CREATE POLICY "Users can view org clients"
  ON clients
  FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can create clients in their organization
CREATE POLICY "Users can create org clients"
  ON clients
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can update clients in their organization
CREATE POLICY "Users can update org clients"
  ON clients
  FOR UPDATE
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- ============================================================================
-- 4. INVOICES - Access only invoices of their organization
-- ============================================================================

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view invoices in their organization
CREATE POLICY "Users can view org invoices"
  ON invoices
  FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can create invoices in their organization
CREATE POLICY "Users can create org invoices"
  ON invoices
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can update invoices in their organization
CREATE POLICY "Users can update org invoices"
  ON invoices
  FOR UPDATE
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- ============================================================================
-- 5. JOBS - Access only jobs of their organization
-- ============================================================================

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view jobs in their organization
CREATE POLICY "Users can view org jobs"
  ON jobs
  FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can create jobs in their organization
CREATE POLICY "Users can create org jobs"
  ON jobs
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can update jobs in their organization
CREATE POLICY "Users can update org jobs"
  ON jobs
  FOR UPDATE
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- ============================================================================
-- 6. INVENTORY - Access only inventory of their organization
-- ============================================================================

ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view inventory in their organization
CREATE POLICY "Users can view org inventory"
  ON inventory
  FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can manage inventory in their organization
CREATE POLICY "Users can manage org inventory"
  ON inventory
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- ============================================================================
-- 7. EXPENSES - Access only expenses of their organization
-- ============================================================================

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view expenses in their organization
CREATE POLICY "Users can view org expenses"
  ON expenses
  FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- Policy: Users can create expenses in their organization
CREATE POLICY "Users can create org expenses"
  ON expenses
  FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- ============================================================================
-- 8. USER PREFERENCES - Users can only access their own preferences
-- ============================================================================

ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view only their own preferences
CREATE POLICY "Users can view own preferences"
  ON user_preferences
  FOR SELECT
  USING (user_id = auth.uid());

-- Policy: Users can update only their own preferences
CREATE POLICY "Users can update own preferences"
  ON user_preferences
  FOR UPDATE
  USING (user_id = auth.uid());

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- 
-- After running this SQL, verify RLS is working:
-- 
-- 1. As user 1, should see their org only:
--    SELECT * FROM organizations;
-- 
-- 2. As user 2, should see different org:
--    SELECT * FROM organizations;
-- 
-- 3. As user 1, trying to see user 2's org data should return empty:
--    SELECT * FROM invoices WHERE org_id = 'user2_org_id';
-- 
-- 4. Check RLS status in Dashboard:
--    Go to Database → Tables → Each table should show "RLS enabled" badge
-- 
-- ============================================================================
