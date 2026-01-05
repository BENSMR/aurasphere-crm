-- supabase_migrations/ai_automation_and_cost_control.sql
-- Automation Settings, Usage Tracking, and Cost Control

-- ==================== AI AUTOMATION SETTINGS ====================
-- Stores automation configuration per organization
CREATE TABLE IF NOT EXISTS ai_automation_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  automation_enabled BOOLEAN DEFAULT TRUE,
  proactivity_level TEXT CHECK (proactivity_level IN ('conservative', 'balanced', 'aggressive')) DEFAULT 'balanced',
  
  -- Agent configuration (JSONB)
  agents JSONB DEFAULT '{
    "cfo": {"enabled": true, "proactive": true, "api_calls_limit": 100},
    "ceo": {"enabled": true, "proactive": true, "api_calls_limit": 80},
    "marketing": {"enabled": true, "proactive": false, "api_calls_limit": 60},
    "sales": {"enabled": true, "proactive": false, "api_calls_limit": 70},
    "admin": {"enabled": false, "proactive": false, "api_calls_limit": 40}
  }',
  
  -- Cost limits
  monthly_api_limit INTEGER DEFAULT 2000,
  monthly_cost_limit DECIMAL(10, 2) DEFAULT 100.00,
  cost_alert_threshold DECIMAL(3, 2) DEFAULT 0.80,  -- Alert at 80%
  auto_pause_on_limit BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(org_id)
);

CREATE INDEX IF NOT EXISTS idx_ai_automation_settings_org_id ON ai_automation_settings(org_id);

-- ==================== AI USAGE LOG ====================
-- Tracks every API call for cost calculation and analytics
CREATE TABLE IF NOT EXISTS ai_usage_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  agent_name TEXT NOT NULL,  -- 'cfo', 'ceo', 'marketing', etc.
  action TEXT NOT NULL,       -- 'parse_command', 'analyze', 'create_invoice', etc.
  
  -- Token usage
  tokens_used INTEGER DEFAULT 0,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  
  -- Cost tracking (Groq pricing)
  estimated_cost DECIMAL(10, 4) DEFAULT 0.0000,
  
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_log_org_id ON ai_usage_log(org_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_log_user_id ON ai_usage_log(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_log_agent_name ON ai_usage_log(agent_name);
CREATE INDEX IF NOT EXISTS idx_ai_usage_log_timestamp ON ai_usage_log(timestamp);

-- Monthly view for easy aggregation
CREATE VIEW IF NOT EXISTS ai_usage_monthly AS
SELECT
  org_id,
  DATE_TRUNC('month', timestamp)::DATE as month,
  COUNT(*) as api_calls,
  SUM(tokens_used) as total_tokens,
  SUM(estimated_cost)::DECIMAL(10, 2) as total_cost,
  COUNT(DISTINCT agent_name) as agents_used
FROM ai_usage_log
GROUP BY org_id, DATE_TRUNC('month', timestamp);

-- Agent breakdown view
CREATE VIEW IF NOT EXISTS ai_usage_by_agent AS
SELECT
  org_id,
  agent_name,
  COUNT(*) as call_count,
  SUM(tokens_used) as total_tokens,
  SUM(estimated_cost)::DECIMAL(10, 2) as total_cost,
  AVG(estimated_cost)::DECIMAL(10, 4) as avg_cost,
  DATE_TRUNC('month', timestamp)::DATE as month
FROM ai_usage_log
GROUP BY org_id, agent_name, DATE_TRUNC('month', timestamp);

-- ==================== RLS POLICIES ====================

-- Enable RLS
ALTER TABLE ai_automation_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage_log ENABLE ROW LEVEL SECURITY;

-- RLS: Automation settings (org members only)
CREATE POLICY "org_members_can_view_automation_settings"
  ON ai_automation_settings FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM users WHERE users.id = auth.uid()
    )
  );

CREATE POLICY "org_owners_can_update_automation_settings"
  ON ai_automation_settings FOR UPDATE
  USING (
    org_id IN (
      SELECT org_id FROM organizations 
      WHERE owner_id = auth.uid()
    )
  );

-- RLS: Usage logs (org members view, owner analytics)
CREATE POLICY "org_members_can_view_own_usage"
  ON ai_usage_log FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM users WHERE users.id = auth.uid()
    )
  );

CREATE POLICY "system_can_insert_usage_logs"
  ON ai_usage_log FOR INSERT
  WITH CHECK (TRUE);

-- ==================== HELPER FUNCTIONS ====================

-- Function to get current month's usage for an org
CREATE OR REPLACE FUNCTION get_current_month_usage(p_org_id UUID)
RETURNS TABLE (
  total_tokens BIGINT,
  total_cost DECIMAL(10, 2),
  api_calls BIGINT,
  agents_used INT
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(dul.tokens_used), 0)::BIGINT,
    COALESCE(SUM(dul.estimated_cost), 0)::DECIMAL(10, 2),
    COUNT(*)::BIGINT,
    COUNT(DISTINCT dul.agent_name)::INT
  FROM ai_usage_log dul
  WHERE dul.org_id = p_org_id
    AND DATE_TRUNC('month', dul.timestamp) = DATE_TRUNC('month', NOW());
END;
$$;

-- Function to check if org is over cost limit
CREATE OR REPLACE FUNCTION is_org_over_cost_limit(p_org_id UUID)
RETURNS TABLE (
  over_limit BOOLEAN,
  current_cost DECIMAL(10, 2),
  limit_amount DECIMAL(10, 2)
) LANGUAGE plpgsql AS $$
DECLARE
  v_current_cost DECIMAL(10, 2);
  v_limit DECIMAL(10, 2);
BEGIN
  SELECT COALESCE(SUM(dul.estimated_cost), 0)
  INTO v_current_cost
  FROM ai_usage_log dul
  WHERE dul.org_id = p_org_id
    AND DATE_TRUNC('month', dul.timestamp) = DATE_TRUNC('month', NOW());
  
  SELECT aas.monthly_cost_limit INTO v_limit
  FROM ai_automation_settings aas
  WHERE aas.org_id = p_org_id;
  
  RETURN QUERY SELECT
    (v_current_cost >= COALESCE(v_limit, 100)),
    v_current_cost,
    COALESCE(v_limit, 100);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_current_month_usage(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_org_over_cost_limit(UUID) TO authenticated;
