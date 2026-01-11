-- ============================================================
-- BUSINESS IDENTITY PROVISIONING SCHEMA
-- Automatically provisions domain, email, and website on subscription
-- ============================================================

-- 1. EXTEND user_profiles table with business identity fields
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS (
    -- Business information (collected during trial signup)
    business_name VARCHAR(100),
    business_address VARCHAR(255),
    whatsapp_number VARCHAR(20),
    
    -- Auto-provisioned business identity
    business_domain VARCHAR(100) UNIQUE,  -- e.g., premium-plumbing-dubai.online
    business_email VARCHAR(100),          -- e.g., contact@premium-plumbing-dubai.online
    website_url VARCHAR(255),             -- e.g., https://premium-plumbing-dubai.online
    website_status VARCHAR(50),           -- 'pending', 'active', 'failed'
    
    -- Domain information
    domain_tld VARCHAR(10),               -- 'online', 'shop', 'pro'
    domain_registrar VARCHAR(50),         -- 'porkbun'
    domain_cost_cents INTEGER,            -- Cost in cents (e.g., 299 = $2.99)
    domain_expiry_date TIMESTAMP,
    
    -- Email service information
    email_provider VARCHAR(50),           -- 'zoho' 
    email_status VARCHAR(50),             -- 'pending', 'active', 'failed'
    
    -- Timestamps
    identity_provisioned_at TIMESTAMP,
    identity_error_message TEXT
);

-- 2. CREATE subscription_plans table (maps Paddle product IDs to plans)
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    plan_name VARCHAR(50) NOT NULL,       -- 'solo', 'team', 'workshop'
    paddle_product_id VARCHAR(100) UNIQUE,
    monthly_price_cents INTEGER NOT NULL,
    domain_tld VARCHAR(10) NOT NULL,      -- '.online', '.shop', '.pro'
    email_limit INTEGER NOT NULL,         -- 3, 3, 5
    whatsapp_limit INTEGER NOT NULL,      -- 1, 3, 7
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. CREATE subscriptions table (tracks active subscriptions)
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES public.subscription_plans(id),
    paddle_subscription_id VARCHAR(100) UNIQUE,
    status VARCHAR(50) NOT NULL,          -- 'active', 'paused', 'cancelled'
    trial_ends_at TIMESTAMP,
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    next_billing_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. CREATE business_emails table (tracks email accounts per plan)
CREATE TABLE IF NOT EXISTS public.business_emails (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email_address VARCHAR(100) NOT NULL UNIQUE,  -- e.g., contact@mybusiness.online
    email_type VARCHAR(50) NOT NULL,             -- 'contact', 'jobs', 'invoices', 'support', 'billing'
    zoho_account_id VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending',        -- 'pending', 'active', 'failed'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. CREATE provisioning_logs table (audit trail for business identity provisioning)
CREATE TABLE IF NOT EXISTS public.provisioning_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    step VARCHAR(100) NOT NULL,                  -- 'domain_reserved', 'domain_purchased', 'emails_created', 'website_deployed'
    status VARCHAR(50) NOT NULL,                 -- 'pending', 'completed', 'failed'
    external_id VARCHAR(100),                    -- Porkbun domain ID, Zoho account ID, etc.
    error_message TEXT,
    metadata JSONB,                              -- Extra data per step
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_paddle_id ON public.subscriptions(paddle_subscription_id);
CREATE INDEX IF NOT EXISTS idx_business_emails_user_id ON public.business_emails(user_id);
CREATE INDEX IF NOT EXISTS idx_provisioning_logs_user_id ON public.provisioning_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_business_domain ON public.user_profiles(business_domain);

-- ============================================================
-- SAMPLE DATA: Insert subscription plans
-- ============================================================
INSERT INTO public.subscription_plans 
(plan_name, paddle_product_id, monthly_price_cents, domain_tld, email_limit, whatsapp_limit)
VALUES
('Solo', 'prod_solo_paddle_id', 999, 'online', 3, 1),
('Team', 'prod_team_paddle_id', 1500, 'shop', 3, 3),
('Workshop', 'prod_workshop_paddle_id', 2900, 'pro', 5, 7)
ON CONFLICT DO NOTHING;

-- ============================================================
-- RLS POLICIES (Row Level Security)
-- ============================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provisioning_logs ENABLE ROW LEVEL SECURITY;

-- User can only view/edit their own profile
CREATE POLICY user_profile_access ON public.user_profiles
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- User can only view/edit their own subscriptions
CREATE POLICY subscription_access ON public.subscriptions
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- User can only view/edit their own business emails
CREATE POLICY business_email_access ON public.business_emails
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- User can only view their own provisioning logs
CREATE POLICY provisioning_logs_access ON public.provisioning_logs
    FOR SELECT USING (auth.uid() = user_id);
