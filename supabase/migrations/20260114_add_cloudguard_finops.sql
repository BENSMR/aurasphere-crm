-- FinOps CloudGuard Feature Schema
-- Tables for cloud expense tracking, waste detection, and partner enablement
-- Date: January 14, 2026

-- =====================================================
-- 1. CLOUD PROVIDER CONNECTIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS cloud_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('aws', 'azure', 'gcp')), -- AWS, Azure, GCP
  account_name TEXT NOT NULL,
  account_id TEXT NOT NULL,
  api_key_encrypted TEXT NOT NULL, -- Encrypted via Supabase Secrets
  api_secret_encrypted TEXT NOT NULL, -- Encrypted
  is_active BOOLEAN DEFAULT true,
  last_sync_at TIMESTAMP,
  sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'syncing', 'success', 'failed')),
  sync_error TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(org_id, provider, account_id)
);

CREATE INDEX idx_cloud_connections_org ON cloud_connections(org_id);
CREATE INDEX idx_cloud_connections_status ON cloud_connections(is_active, sync_status);

-- =====================================================
-- 2. CLOUD EXPENSES (Monthly Bills)
-- =====================================================
CREATE TABLE IF NOT EXISTS cloud_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  connection_id UUID NOT NULL REFERENCES cloud_connections(id) ON DELETE CASCADE,
  provider TEXT NOT NULL, -- 'aws' | 'azure' | 'gcp'
  month DATE NOT NULL, -- First day of month (e.g., '2024-01-01')
  total_cost DECIMAL(12,2) NOT NULL,
  estimated_waste_cost DECIMAL(12,2) DEFAULT 0, -- Calculated by waste detection
  waste_percentage DECIMAL(5,2) DEFAULT 0, -- e.g., 28.5
  service_breakdown JSONB DEFAULT '{}', -- { "compute": 500, "storage": 300, ... }
  raw_bill_data JSONB, -- Full AWS/Azure/GCP bill (encrypted)
  last_analyzed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(org_id, connection_id, month)
);

CREATE INDEX idx_cloud_expenses_org_month ON cloud_expenses(org_id, month DESC);
CREATE INDEX idx_cloud_expenses_provider ON cloud_expenses(provider, month DESC);

-- =====================================================
-- 3. WASTE DETECTION FINDINGS
-- =====================================================
CREATE TABLE IF NOT EXISTS waste_findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  expense_id UUID NOT NULL REFERENCES cloud_expenses(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  waste_category TEXT NOT NULL CHECK (waste_category IN (
    'idle_resource',      -- <5% CPU for 7+ days
    'over_provisioned',   -- Instance type too large
    'unused_service',     -- CDN, unused backups
    'unattached_storage', -- EBS volumes, managed disks
    'data_transfer',      -- Expensive egress
    'old_snapshot',       -- Outdated backups
    'orphaned_ips',       -- Unattached IPs
    'reserved_unused'     -- Unused reserved instances
  )),
  
  -- Resource details
  resource_type TEXT, -- e.g., 'ec2_instance', 'rds_database'
  resource_id TEXT,
  resource_name TEXT,
  resource_region TEXT,
  
  -- Cost impact
  current_monthly_cost DECIMAL(10,2),
  potential_monthly_savings DECIMAL(10,2),
  potential_annual_savings DECIMAL(10,2),
  
  -- Analysis details
  severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  description TEXT,
  recommendation TEXT,
  
  -- Status
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'fixed', 'dismissed')),
  fixed_at TIMESTAMP,
  dismissed_at TIMESTAMP,
  dismissal_reason TEXT,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_waste_findings_org ON waste_findings(org_id, status);
CREATE INDEX idx_waste_findings_severity ON waste_findings(severity, status);
CREATE INDEX idx_waste_findings_savings ON waste_findings(potential_annual_savings DESC);

-- =====================================================
-- 4. PARTNER ENABLEMENT
-- =====================================================
CREATE TABLE IF NOT EXISTS partner_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  partner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_company_name TEXT NOT NULL,
  partner_email TEXT NOT NULL,
  partner_phone TEXT,
  
  -- Certification level
  certification_level TEXT DEFAULT 'base' CHECK (certification_level IN ('base', 'certified', 'elite')),
  certification_started_at TIMESTAMP,
  certification_renewed_at TIMESTAMP,
  
  -- Commission tracking (20% recurring)
  commission_rate DECIMAL(4,2) DEFAULT 20.00, -- 20%
  total_commissions_earned DECIMAL(12,2) DEFAULT 0,
  current_month_commissions DECIMAL(10,2) DEFAULT 0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected', 'suspended')),
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(org_id, partner_user_id)
);

CREATE INDEX idx_partners_org ON partner_accounts(org_id, is_active);
CREATE INDEX idx_partners_certification ON partner_accounts(certification_level);

-- =====================================================
-- 5. PARTNER DEMOS & SALES COLLATERAL
-- =====================================================
CREATE TABLE IF NOT EXISTS partner_demos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  partner_id UUID NOT NULL REFERENCES partner_accounts(id) ON DELETE CASCADE,
  prospect_client_id UUID REFERENCES clients(id) ON DELETE SET NULL, -- Prospect being demoed to
  
  -- Demo data (snapshot)
  demo_title TEXT NOT NULL,
  prospect_name TEXT NOT NULL,
  prospect_email TEXT,
  prospect_current_cloud_spend DECIMAL(10,2),
  prospect_detected_waste DECIMAL(10,2),
  prospect_potential_savings DECIMAL(10,2),
  
  -- Demo materials
  demo_video_url TEXT,
  roi_calculator_data JSONB,
  pitch_deck_url TEXT,
  
  -- Engagement tracking
  created_at TIMESTAMP DEFAULT NOW(),
  sent_at TIMESTAMP,
  opened_at TIMESTAMP,
  clicked_at TIMESTAMP,
  converted_at TIMESTAMP,
  
  -- Outcome
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'opened', 'clicked', 'converted', 'lost')),
  deal_value DECIMAL(12,2), -- If converted
  
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_partner_demos_partner ON partner_demos(partner_id, created_at DESC);
CREATE INDEX idx_partner_demos_status ON partner_demos(status);

-- =====================================================
-- 6. PARTNER RESOURCES & CERTIFICATION
-- =====================================================
CREATE TABLE IF NOT EXISTS partner_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  resource_type TEXT NOT NULL CHECK (resource_type IN (
    'video',          -- Training videos
    'calculator',     -- ROI calculator
    'pitch_deck',     -- Sales presentation
    'case_study',     -- Success story
    'whitepaper',     -- Technical document
    'webinar'         -- Live training
  )),
  
  title TEXT NOT NULL,
  description TEXT,
  content_url TEXT NOT NULL, -- YouTube, S3, etc.
  thumbnail_url TEXT,
  
  certification_required TEXT DEFAULT 'base' CHECK (certification_required IN ('base', 'certified', 'elite')),
  access_level TEXT DEFAULT 'all' CHECK (access_level IN ('all', 'certified', 'elite', 'custom')),
  
  views INT DEFAULT 0,
  downloads INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_partner_resources_type ON partner_resources(resource_type);
CREATE INDEX idx_partner_resources_cert ON partner_resources(certification_required);

-- =====================================================
-- 7. PARTNER COMMISSION TRACKING
-- =====================================================
CREATE TABLE IF NOT EXISTS partner_commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  partner_id UUID NOT NULL REFERENCES partner_accounts(id) ON DELETE CASCADE,
  
  -- What triggered the commission
  commission_type TEXT NOT NULL CHECK (commission_type IN (
    'cloudguard_addon',     -- Partner sold CloudGuard add-on
    'demo_conversion',      -- Demo led to customer
    'referral',             -- Referred new customer
    'resource_engagement'   -- Customer used partner resources
  )),
  
  source_deal_id UUID REFERENCES invoices(id), -- If from invoice/subscription
  
  -- Commission details
  base_amount DECIMAL(10,2), -- 20% of whatever
  commission_rate DECIMAL(4,2), -- 20%
  commission_amount DECIMAL(10,2),
  
  commission_period DATE, -- Month of commission
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'processed', 'paid', 'failed')),
  paid_at TIMESTAMP,
  
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_commissions_partner ON partner_commissions(partner_id, commission_period DESC);
CREATE INDEX idx_commissions_status ON partner_commissions(payment_status);

-- =====================================================
-- 8. RLS POLICIES
-- =====================================================

-- Cloud Connections RLS
ALTER TABLE cloud_connections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their org's cloud connections"
  ON cloud_connections FOR SELECT
  USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()));

CREATE POLICY "Only org owners can create cloud connections"
  ON cloud_connections FOR INSERT
  WITH CHECK (org_id IN (SELECT id FROM organizations WHERE owner_id = auth.uid()));

-- Cloud Expenses RLS
ALTER TABLE cloud_expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their org's cloud expenses"
  ON cloud_expenses FOR SELECT
  USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()));

-- Waste Findings RLS
ALTER TABLE waste_findings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their org's waste findings"
  ON waste_findings FOR SELECT
  USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()));

-- Partner Accounts RLS
ALTER TABLE partner_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view partners in their org"
  ON partner_accounts FOR SELECT
  USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()));

CREATE POLICY "Partners can view their own account"
  ON partner_accounts FOR SELECT
  USING (partner_user_id = auth.uid());

-- Partner Demos RLS
ALTER TABLE partner_demos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view demos in their org"
  ON partner_demos FOR SELECT
  USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()));

CREATE POLICY "Partners can view their own demos"
  ON partner_demos FOR SELECT
  USING (partner_id IN (SELECT id FROM partner_accounts WHERE partner_user_id = auth.uid()));

-- Partner Resources RLS
ALTER TABLE partner_resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view resources in their org"
  ON partner_resources FOR SELECT
  USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()));

-- Partner Commissions RLS
ALTER TABLE partner_commissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view commissions in their org"
  ON partner_commissions FOR SELECT
  USING (org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()));

CREATE POLICY "Partners can view their own commissions"
  ON partner_commissions FOR SELECT
  USING (partner_id IN (SELECT id FROM partner_accounts WHERE partner_user_id = auth.uid()));

-- =====================================================
-- 9. GRANTS
-- =====================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
