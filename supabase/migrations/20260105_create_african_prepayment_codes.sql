-- African Prepayment Codes Table
-- Stores offline activation codes for 54 African countries

CREATE TABLE african_prepayment_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(255) UNIQUE NOT NULL,
  region VARCHAR(2) NOT NULL, -- ISO country code
  country_name VARCHAR(255) NOT NULL,
  plan_id VARCHAR(50) NOT NULL, -- solo_trades, small_team, workshop
  duration VARCHAR(10) NOT NULL, -- 1M, 3M, 6M, 1Y
  duration_days INT NOT NULL, -- Converted duration in days
  generated_by UUID NOT NULL REFERENCES auth.users(id),
  status VARCHAR(50) DEFAULT 'active', -- active, redeemed, expired
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL, -- 12x duration from creation
  redeemed_by UUID REFERENCES auth.users(id),
  redeemed_at TIMESTAMP,
  description TEXT,
  metadata JSONB DEFAULT '{}', -- Custom metadata for codes
  
  -- Indexes for fast lookups
  CONSTRAINT valid_region CHECK (region IN (
    'EG', 'MA', 'DZ', 'TN', 'LY', 'SD', 'MR', -- North Africa
    'NG', 'GH', 'CI', 'SN', 'ML', 'BF', 'BJ', 'TG', 'NE', 'GN', 'GW', 'LR', 'SL', 'CV', -- West
    'CM', 'GA', 'CG', 'CD', 'TD', 'CF', 'ST', 'GQ', 'AO', -- Central
    'ET', 'KE', 'UG', 'TZ', 'RW', 'BI', 'SO', 'DJ', 'ER', 'SC', 'KM', -- East
    'ZA', 'ZM', 'ZW', 'MW', 'MZ', 'NA', 'BW', 'LS', 'SZ', 'MU', 'MG', 'RE', 'YT' -- Southern
  )),
  CONSTRAINT valid_duration CHECK (duration IN ('1M', '3M', '6M', '1Y')),
  CONSTRAINT valid_status CHECK (status IN ('active', 'redeemed', 'expired'))
);

-- Indexes
CREATE INDEX idx_african_codes_code ON african_prepayment_codes(code);
CREATE INDEX idx_african_codes_status ON african_prepayment_codes(status);
CREATE INDEX idx_african_codes_region ON african_prepayment_codes(region);
CREATE INDEX idx_african_codes_plan ON african_prepayment_codes(plan_id);
CREATE INDEX idx_african_codes_redeemed_by ON african_prepayment_codes(redeemed_by);
CREATE INDEX idx_african_codes_created_at ON african_prepayment_codes(created_at DESC);
CREATE INDEX idx_african_codes_expires_at ON african_prepayment_codes(expires_at);

-- Audit table for code redemptions
CREATE TABLE african_code_redemption_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES african_prepayment_codes(id) ON DELETE CASCADE,
  code VARCHAR(255) NOT NULL,
  redeemed_by UUID NOT NULL REFERENCES auth.users(id),
  org_id UUID NOT NULL REFERENCES organizations(id),
  region VARCHAR(2) NOT NULL,
  plan_id VARCHAR(50) NOT NULL,
  duration VARCHAR(10) NOT NULL,
  subscription_start TIMESTAMP NOT NULL,
  subscription_end TIMESTAMP NOT NULL,
  ip_address INET,
  user_agent TEXT,
  status VARCHAR(50) DEFAULT 'success', -- success, failed, cancelled
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('success', 'failed', 'cancelled'))
);

-- Indexes for audit
CREATE INDEX idx_audit_code_id ON african_code_redemption_audit(code_id);
CREATE INDEX idx_audit_redeemed_by ON african_code_redemption_audit(redeemed_by);
CREATE INDEX idx_audit_org_id ON african_code_redemption_audit(org_id);
CREATE INDEX idx_audit_region ON african_code_redemption_audit(region);
CREATE INDEX idx_audit_created_at ON african_code_redemption_audit(created_at DESC);

-- Table for code distribution tracking
CREATE TABLE african_code_distribution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id VARCHAR(255) NOT NULL UNIQUE,
  generated_by UUID NOT NULL REFERENCES auth.users(id),
  plan_id VARCHAR(50) NOT NULL,
  regions TEXT[] NOT NULL, -- Array of region codes
  duration VARCHAR(10) NOT NULL,
  quantity INT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  description TEXT,
  distribution_method VARCHAR(50), -- email, download, manual, api
  distributed_at TIMESTAMP,
  distributed_by UUID REFERENCES auth.users(id),
  
  CONSTRAINT valid_distribution_method CHECK (distribution_method IN ('email', 'download', 'manual', 'api', NULL))
);

-- Index for batch tracking
CREATE INDEX idx_distribution_batch_id ON african_code_distribution(batch_id);
CREATE INDEX idx_distribution_generated_by ON african_code_distribution(generated_by);
CREATE INDEX idx_distribution_created_at ON african_code_distribution(created_at DESC);

-- RLS Policies

-- Allow anyone to verify code status (read-only for public verification)
CREATE POLICY "anyone_can_verify_code_status"
  ON african_prepayment_codes
  FOR SELECT
  USING (true); -- Public verification - only shows basic info via API

-- Admins can manage codes
CREATE POLICY "admins_can_manage_codes"
  ON african_prepayment_codes
  FOR ALL
  USING (
    (SELECT role FROM org_members 
     WHERE user_id = auth.uid() 
     AND org_members.org_id = (
       SELECT org_id FROM organizations WHERE id = auth.uid()
     )) = 'admin'
    OR
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'service_role'
  );

-- Users can view their own redemptions
CREATE POLICY "users_can_view_their_redemptions"
  ON african_prepayment_codes
  FOR SELECT
  USING (redeemed_by = auth.uid());

-- Admins can view audit logs
CREATE POLICY "admins_can_view_audit"
  ON african_code_redemption_audit
  FOR SELECT
  USING (
    (SELECT role FROM org_members 
     WHERE user_id = auth.uid() 
     AND org_members.org_id = org_id) = 'admin'
  );

-- Tables to be enabled for RLS
ALTER TABLE african_prepayment_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE african_code_redemption_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE african_code_distribution ENABLE ROW LEVEL SECURITY;
