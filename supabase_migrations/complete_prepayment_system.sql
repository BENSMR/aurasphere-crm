-- ============================================================================
-- AURASPHERE CRM - PREPAYMENT CODE SYSTEM
-- Complete Database Migration for 54 African Countries
-- ============================================================================
-- This migration adds complete prepayment code management for offline payment
-- support in 54 African countries where Stripe/Paddle are unavailable
-- ============================================================================

-- ============================================================================
-- 1. CREATE PREPAYMENT CODES TABLE (Main system)
-- ============================================================================
CREATE TABLE IF NOT EXISTS prepayment_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  plan_id VARCHAR(20) NOT NULL, -- solo, team, workshop
  region VARCHAR(5) NOT NULL, -- ISO 3166-1 alpha-2 code
  subscription_duration INTEGER NOT NULL DEFAULT 1, -- months (1, 3, 6, 12)
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, redeemed, expired
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
  
  -- Redemption tracking (single-use enforcement via UNIQUE constraint)
  redeemed_by UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
  redeemed_at TIMESTAMP WITH TIME ZONE,
  subscription_active_until TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  CONSTRAINT valid_plan CHECK (plan_id IN ('solo', 'team', 'workshop')),
  CONSTRAINT valid_region CHECK (region IN (
    -- NORTH AFRICA (7 countries)
    'TN', 'EG', 'MA', 'DZ', 'LY', 'SD', 'MR',
    -- WEST AFRICA (14 countries)
    'ML', 'BF', 'SN', 'CI', 'BJ', 'TG', 'NE', 'GH', 'LR', 'SL', 'GW', 'GM', 'CV', 'MU',
    -- CENTRAL AFRICA (9 countries)
    'CM', 'GA', 'CG', 'CD', 'TD', 'CF', 'ST', 'GQ', 'AO',
    -- EAST AFRICA (11 countries)
    'ET', 'KE', 'UG', 'TZ', 'RW', 'BI', 'SO', 'DJ', 'ER', 'SC', 'KM',
    -- SOUTHERN AFRICA (8 countries)
    'ZM', 'ZW', 'MW', 'MZ', 'NA', 'BW', 'LS', 'SZ', 'ZA'
  )),
  CONSTRAINT valid_duration CHECK (subscription_duration IN (1, 3, 6, 12)),
  CONSTRAINT valid_status CHECK (status IN ('active', 'redeemed', 'expired')),
  CONSTRAINT redeemed_constraints CHECK (
    (status = 'redeemed' AND redeemed_by IS NOT NULL AND redeemed_at IS NOT NULL AND subscription_active_until IS NOT NULL) OR
    (status != 'redeemed' AND redeemed_by IS NULL AND redeemed_at IS NULL AND subscription_active_until IS NULL)
  )
);

-- ============================================================================
-- 2. CREATE INDEXES for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_code ON prepayment_codes(code);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_status ON prepayment_codes(status);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_region ON prepayment_codes(region);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_redeemed_by ON prepayment_codes(redeemed_by);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_valid_until ON prepayment_codes(valid_until);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_subscription_duration ON prepayment_codes(subscription_duration);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_created_by ON prepayment_codes(created_by);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_created_at ON prepayment_codes(created_at);

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================
ALTER TABLE prepayment_codes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. RLS POLICIES - Prepayment Codes
-- ============================================================================

-- Policy 1: Admins can view all codes
CREATE POLICY IF NOT EXISTS "admins_view_all_codes" ON prepayment_codes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy 2: Admins can generate codes
CREATE POLICY IF NOT EXISTS "admins_insert_codes" ON prepayment_codes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy 3: Admins can update codes (mark as expired, manage status)
CREATE POLICY IF NOT EXISTS "admins_update_codes" ON prepayment_codes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy 4: Users can see/redeem codes only for their own redeemed codes
CREATE POLICY IF NOT EXISTS "users_view_own_redeemed" ON prepayment_codes
  FOR SELECT
  USING (
    redeemed_by = auth.uid()
  );

-- Policy 5: Users can redeem active codes
CREATE POLICY IF NOT EXISTS "users_redeem_codes" ON prepayment_codes
  FOR UPDATE
  USING (
    status = 'active'
  )
  WITH CHECK (
    redeemed_by = auth.uid()
    AND status = 'redeemed'
  );

-- ============================================================================
-- 5. UPDATE USERS TABLE with prepayment tracking
-- ============================================================================
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS prepayment_code_id UUID REFERENCES prepayment_codes(id) ON DELETE SET NULL;
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS activation_method VARCHAR(20) DEFAULT 'stripe'; -- stripe, paddle, prepayment_code
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR(20); -- solo, team, workshop
ALTER TABLE IF EXISTS users ADD COLUMN IF NOT EXISTS subscription_active_until TIMESTAMP WITH TIME ZONE;

-- ============================================================================
-- 6. CREATE AUDIT LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS prepayment_code_audit (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code_id UUID NOT NULL REFERENCES prepayment_codes(id) ON DELETE CASCADE,
  action VARCHAR(50) NOT NULL, -- generated, validated, redeemed, expired
  performed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT,
  details JSONB DEFAULT '{}',
  CONSTRAINT valid_action CHECK (action IN ('generated', 'validated', 'redeemed', 'expired'))
);

-- ============================================================================
-- 7. CREATE INDEXES for audit table
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_audit_code_id ON prepayment_code_audit(code_id);
CREATE INDEX IF NOT EXISTS idx_audit_performed_by ON prepayment_code_audit(performed_by);
CREATE INDEX IF NOT EXISTS idx_audit_action ON prepayment_code_audit(action);
CREATE INDEX IF NOT EXISTS idx_audit_performed_at ON prepayment_code_audit(performed_at);

-- ============================================================================
-- 8. ENABLE RLS on AUDIT TABLE
-- ============================================================================
ALTER TABLE prepayment_code_audit ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can view all audit logs
CREATE POLICY IF NOT EXISTS "admins_view_audit" ON prepayment_code_audit
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy: Admins can insert audit logs
CREATE POLICY IF NOT EXISTS "admins_insert_audit" ON prepayment_code_audit
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- ============================================================================
-- 9. TRIGGER FUNCTIONS
-- ============================================================================

-- Function: Log code generation
CREATE OR REPLACE FUNCTION log_code_generation()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO prepayment_code_audit (code_id, action, performed_by, details)
  VALUES (NEW.id, 'generated', NEW.created_by, jsonb_build_object(
    'plan_id', NEW.plan_id,
    'region', NEW.region,
    'subscription_duration', NEW.subscription_duration,
    'valid_until', NEW.valid_until
  ));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: On INSERT, log code generation
CREATE TRIGGER IF NOT EXISTS trigger_log_code_generation
AFTER INSERT ON prepayment_codes
FOR EACH ROW
EXECUTE FUNCTION log_code_generation();

-- Function: Log code redemption
CREATE OR REPLACE FUNCTION log_code_redemption()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status = 'active' AND NEW.status = 'redeemed' THEN
    INSERT INTO prepayment_code_audit (code_id, action, performed_by, details)
    VALUES (NEW.id, 'redeemed', NEW.redeemed_by, jsonb_build_object(
      'plan_id', NEW.plan_id,
      'region', NEW.region,
      'subscription_duration', NEW.subscription_duration,
      'subscription_active_until', NEW.subscription_active_until
    ));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: On UPDATE, log code redemption
CREATE TRIGGER IF NOT EXISTS trigger_log_code_redemption
AFTER UPDATE ON prepayment_codes
FOR EACH ROW
EXECUTE FUNCTION log_code_redemption();

-- ============================================================================
-- 10. COMPLETION MESSAGE
-- ============================================================================
-- Migration complete. Run this to verify:
-- SELECT * FROM prepayment_codes LIMIT 1;
-- SELECT * FROM prepayment_code_audit LIMIT 1;
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users' AND column_name IN ('prepayment_code_id', 'activation_method', 'subscription_plan', 'subscription_active_until');
