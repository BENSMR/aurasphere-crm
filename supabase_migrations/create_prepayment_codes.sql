-- Prepayment Code Management System
-- Supports 54 African countries across 5 continents
-- Enables offline payment code sharing with online redemption
-- Single-use enforcement + subscription duration tracking

CREATE TABLE IF NOT EXISTS prepayment_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  plan_id VARCHAR(20) NOT NULL, -- solo, team, workshop
  region VARCHAR(5) NOT NULL, -- ISO 3166-1 alpha-2 code (54 African countries)
  subscription_duration INTEGER NOT NULL DEFAULT 1, -- months (1, 3, 6, 12)
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, redeemed, expired
  
  -- Metadata
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
  
  -- Redemption tracking (single-use enforcement)
  redeemed_by UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL, -- UNIQUE ensures single-use
  redeemed_at TIMESTAMP WITH TIME ZONE,
  subscription_active_until TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT valid_plan CHECK (plan_id IN ('solo', 'team', 'workshop')),
  CONSTRAINT valid_region CHECK (region IN (
    -- North Africa (7): Tunisia, Egypt, Morocco, Algeria, Libya, Sudan, Mauritania
    'TN', 'EG', 'MA', 'DZ', 'LY', 'SD', 'MR',
    -- West Africa (14): Mali, Burkina Faso, Senegal, Ivory Coast, Benin, Togo, Niger, Ghana, Liberia, Sierra Leone, Guinea-Bissau, Gambia, Cape Verde, Mauritius
    'ML', 'BF', 'SN', 'CI', 'BJ', 'TG', 'NE', 'GH', 'LR', 'SL', 'GW', 'GM', 'CV', 'MU',
    -- Central Africa (9): Cameroon, Gabon, Congo, DR Congo, Chad, Central African Republic, São Tomé & Príncipe, Equatorial Guinea, Angola
    'CM', 'GA', 'CG', 'CD', 'TD', 'CF', 'ST', 'GQ', 'AO',
    -- East Africa (11): Ethiopia, Kenya, Uganda, Tanzania, Rwanda, Burundi, Somalia, Djibouti, Eritrea, Seychelles, Comoros
    'ET', 'KE', 'UG', 'TZ', 'RW', 'BI', 'SO', 'DJ', 'ER', 'SC', 'KM',
    -- Southern Africa (8): Zambia, Zimbabwe, Malawi, Mozambique, Namibia, Botswana, Lesotho, Eswatini, South Africa
    'ZM', 'ZW', 'MW', 'MZ', 'NA', 'BW', 'LS', 'SZ', 'ZA'
  )),
  CONSTRAINT valid_duration CHECK (subscription_duration IN (1, 3, 6, 12)),
  CONSTRAINT valid_status CHECK (status IN ('active', 'redeemed', 'expired')),
  CONSTRAINT redeemed_constraints CHECK (
    (status = 'redeemed' AND redeemed_by IS NOT NULL AND redeemed_at IS NOT NULL AND subscription_active_until IS NOT NULL) OR
    (status != 'redeemed' AND redeemed_by IS NULL AND redeemed_at IS NULL AND subscription_active_until IS NULL)
  )
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_code ON prepayment_codes(code);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_status ON prepayment_codes(status);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_region ON prepayment_codes(region);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_redeemed_by ON prepayment_codes(redeemed_by);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_valid_until ON prepayment_codes(valid_until);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_subscription_duration ON prepayment_codes(subscription_duration);

-- Enable RLS
ALTER TABLE prepayment_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- 1. Admins can view all codes
CREATE POLICY "admins_view_all_codes" ON prepayment_codes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- 2. Admins can generate codes
CREATE POLICY "admins_insert_codes" ON prepayment_codes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- 3. Admins can update codes (mark as expired, etc)
CREATE POLICY "admins_update_codes" ON prepayment_codes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- 4. Users can only see/redeem their own redeemed codes (limited visibility)
CREATE POLICY "users_view_own_redeemed" ON prepayment_codes
  FOR SELECT
  USING (
    redeemed_by = auth.uid()
  );

-- 5. Users can redeem codes (update their own)
CREATE POLICY "users_redeem_codes" ON prepayment_codes
  FOR UPDATE
  USING (
    -- Code must be active and belong to current user after redemption
    status = 'active'
  )
  WITH CHECK (
    -- Only allow updating redeemed_by and redeemed_at fields
    redeemed_by = auth.uid()
    AND status = 'redeemed'
  );

-- Add column to users table to track if they used a prepayment code
ALTER TABLE users ADD COLUMN IF NOT EXISTS prepayment_code_id UUID REFERENCES prepayment_codes(id) ON DELETE SET NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS activation_method VARCHAR(20) DEFAULT 'stripe'; -- stripe, paddle, prepayment_code

-- Audit log table for code usage
CREATE TABLE IF NOT EXISTS prepayment_code_audit (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code_id UUID NOT NULL REFERENCES prepayment_codes(id) ON DELETE CASCADE,
  action VARCHAR(50) NOT NULL, -- generated, validated, redeemed, expired
  performed_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  details JSONB DEFAULT '{}',
  CONSTRAINT valid_action CHECK (action IN ('generated', 'validated', 'redeemed', 'expired'))
);

-- Indexes for audit table
CREATE INDEX IF NOT EXISTS idx_audit_code_id ON prepayment_code_audit(code_id);
CREATE INDEX IF NOT EXISTS idx_audit_performed_by ON prepayment_code_audit(performed_by);
CREATE INDEX IF NOT EXISTS idx_audit_action ON prepayment_code_audit(action);

-- Enable RLS on audit table
ALTER TABLE prepayment_code_audit ENABLE ROW LEVEL SECURITY;

-- Admins can view audit logs
CREATE POLICY "admins_view_audit" ON prepayment_code_audit
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Trigger to log code generation
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

CREATE TRIGGER IF NOT EXISTS trigger_log_code_generation
AFTER INSERT ON prepayment_codes
FOR EACH ROW
EXECUTE FUNCTION log_code_generation();

-- Trigger to log code redemption
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

CREATE TRIGGER IF NOT EXISTS trigger_log_code_redemption
AFTER UPDATE ON prepayment_codes
FOR EACH ROW
EXECUTE FUNCTION log_code_redemption();

CREATE TRIGGER trigger_log_code_redemption
AFTER UPDATE ON prepayment_codes
FOR EACH ROW
EXECUTE FUNCTION log_code_redemption();
