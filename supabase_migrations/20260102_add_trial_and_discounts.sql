-- AuraSphere CRM - Trial & Discount Management
-- Adds 3-day free trial and 50% discount for first 2 months

-- ============================================
-- SUBSCRIPTION TRACKING TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL UNIQUE REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL, -- 'solo_trades', 'small_team', 'workshop', 'enterprise'
  status TEXT DEFAULT 'trial' CHECK (status IN ('trial', 'active', 'suspended', 'cancelled')),
  
  -- Trial tracking
  trial_started_at TIMESTAMPTZ DEFAULT NOW(),
  trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '3 days'),
  trial_used BOOLEAN DEFAULT FALSE,
  
  -- Subscription dates
  subscription_started_at TIMESTAMPTZ DEFAULT NOW(),
  subscription_ends_at TIMESTAMPTZ,
  next_billing_date TIMESTAMPTZ,
  
  -- Discount tracking
  discount_percentage NUMERIC(5,2) DEFAULT 50.00, -- First 2 months: 50% off
  discount_months_remaining NUMERIC(3,0) DEFAULT 2,
  discount_applied_at TIMESTAMPTZ DEFAULT NOW(),
  discount_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '2 months'),
  
  -- Stripe integration
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  stripe_product_id TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_trial_period CHECK (trial_ends_at > trial_started_at),
  CONSTRAINT valid_discount_period CHECK (discount_ends_at > discount_applied_at)
);

-- Indexes for faster lookups
CREATE INDEX idx_subscriptions_org_id ON subscriptions(org_id);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_trial_ends ON subscriptions(trial_ends_at);
CREATE INDEX idx_subscriptions_discount_ends ON subscriptions(discount_ends_at);

-- Enable Row Level Security
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own subscription"
  ON subscriptions FOR SELECT
  USING (
    user_id = auth.uid() OR
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
      UNION
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own subscription"
  ON subscriptions FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Service role can manage subscriptions"
  ON subscriptions FOR ALL
  USING (auth.jwt()->>'role' = 'service_role')
  WITH CHECK (auth.jwt()->>'role' = 'service_role');

-- ============================================
-- UPDATE ORGANIZATIONS TABLE
-- ============================================
-- Add trial and discount fields to organizations
ALTER TABLE organizations 
  ADD COLUMN IF NOT EXISTS is_trial_active BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '3 days'),
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5,2) DEFAULT 50.00,
  ADD COLUMN IF NOT EXISTS discount_ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '2 months');

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_organizations_trial_ends ON organizations(trial_ends_at);
CREATE INDEX IF NOT EXISTS idx_organizations_stripe_customer ON organizations(stripe_customer_id);

-- ============================================
-- TRIAL USAGE TRACKING TABLE
-- ============================================
-- Track when trial features are first used
CREATE TABLE IF NOT EXISTS trial_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_accessed TEXT NOT NULL, -- 'dashboard', 'jobs', 'invoices', etc.
  accessed_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT unique_feature_per_org_user UNIQUE(org_id, user_id, feature_accessed)
);

CREATE INDEX idx_trial_usage_org_id ON trial_usage(org_id);
CREATE INDEX idx_trial_usage_accessed_at ON trial_usage(accessed_at);

ALTER TABLE trial_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their trial usage"
  ON trial_usage FOR SELECT
  USING (
    user_id = auth.uid() OR
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
      UNION
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

-- ============================================
-- PRICING PLANS TABLE (Reference)
-- ============================================
CREATE TABLE IF NOT EXISTS pricing_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  monthly_price NUMERIC(10,2) NOT NULL,
  max_users INT NOT NULL,
  max_jobs INT NOT NULL,
  features TEXT[] NOT NULL, -- Array of feature names
  stripe_product_id TEXT,
  stripe_price_id TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default plans
INSERT INTO pricing_plans (plan_id, name, monthly_price, max_users, max_jobs, features, is_active)
VALUES
  ('solo_trades', 'Solo', 9.99, 1, 30, ARRAY['jobs', 'invoices', 'clients', 'ai_assistant'], TRUE),
  ('small_team', 'Team', 20.00, 3, 120, ARRAY['jobs', 'invoices', 'clients', 'team', 'dispatch', 'ai_assistant'], TRUE),
  ('workshop', 'Workshop', 49.00, 7, 999999, ARRAY['jobs', 'invoices', 'clients', 'team', 'dispatch', 'analytics', 'ai_assistant', 'dedicated_support'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- TRIAL REMINDER TABLE
-- ============================================
-- Track trial end reminders sent to users
CREATE TABLE IF NOT EXISTS trial_reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('1_day_left', '6_hours_left', 'trial_ended')),
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT unique_reminder_per_org UNIQUE(org_id, user_id, reminder_type)
);

CREATE INDEX idx_trial_reminders_org_id ON trial_reminders(org_id);

ALTER TABLE trial_reminders ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to check if organization is in trial period
CREATE OR REPLACE FUNCTION is_organization_in_trial(org_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM organizations
    WHERE id = org_id_param
    AND is_trial_active = TRUE
    AND trial_ends_at > NOW()
  );
END;
$$ LANGUAGE plpgsql;

-- Function to calculate discounted price
CREATE OR REPLACE FUNCTION calculate_discounted_price(
  base_price NUMERIC,
  org_id_param UUID
)
RETURNS NUMERIC AS $$
DECLARE
  discount_percent NUMERIC;
BEGIN
  SELECT discount_percentage INTO discount_percent
  FROM organizations
  WHERE id = org_id_param
  AND discount_ends_at > NOW();
  
  IF discount_percent IS NULL THEN
    RETURN base_price;
  END IF;
  
  RETURN base_price * (1 - discount_percent / 100.0);
END;
$$ LANGUAGE plpgsql;

-- Function to create trial subscription
CREATE OR REPLACE FUNCTION create_trial_subscription(
  p_org_id UUID,
  p_user_id UUID,
  p_plan TEXT
)
RETURNS UUID AS $$
DECLARE
  v_subscription_id UUID;
BEGIN
  INSERT INTO subscriptions (
    org_id,
    user_id,
    plan,
    status,
    trial_started_at,
    trial_ends_at,
    subscription_started_at,
    discount_percentage,
    discount_months_remaining,
    discount_applied_at,
    discount_ends_at
  ) VALUES (
    p_org_id,
    p_user_id,
    p_plan,
    'trial',
    NOW(),
    NOW() + INTERVAL '3 days',
    NOW(),
    50.00,
    2,
    NOW(),
    NOW() + INTERVAL '2 months'
  )
  RETURNING id INTO v_subscription_id;
  
  -- Update organization
  UPDATE organizations
  SET 
    is_trial_active = TRUE,
    trial_ends_at = NOW() + INTERVAL '3 days',
    discount_percentage = 50.00,
    discount_ends_at = NOW() + INTERVAL '2 months'
  WHERE id = p_org_id;
  
  RETURN v_subscription_id;
END;
$$ LANGUAGE plpgsql;

-- Function to end trial and activate paid plan
CREATE OR REPLACE FUNCTION activate_paid_subscription(
  p_org_id UUID,
  p_stripe_customer_id TEXT,
  p_stripe_subscription_id TEXT
)
RETURNS VOID AS $$
BEGIN
  UPDATE subscriptions
  SET 
    status = 'active',
    trial_used = TRUE,
    stripe_customer_id = p_stripe_customer_id,
    stripe_subscription_id = p_stripe_subscription_id,
    subscription_started_at = NOW(),
    next_billing_date = NOW() + INTERVAL '1 month'
  WHERE org_id = p_org_id
  AND status = 'trial';
  
  UPDATE organizations
  SET 
    is_trial_active = FALSE,
    stripe_customer_id = p_stripe_customer_id,
    stripe_subscription_id = p_stripe_subscription_id
  WHERE id = p_org_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger to auto-update trial status when it expires
CREATE OR REPLACE FUNCTION check_trial_expiry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_trial_active = TRUE AND NEW.trial_ends_at <= NOW() THEN
    NEW.is_trial_active = FALSE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_trial_expiry
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION check_trial_expiry();

-- Trigger to update subscriptions when org is updated
CREATE OR REPLACE FUNCTION sync_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE subscriptions
  SET updated_at = NOW()
  WHERE org_id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_subscription_status
  AFTER UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION sync_subscription_status();

COMMIT;
