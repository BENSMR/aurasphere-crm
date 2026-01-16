-- ============================================================================
-- AURASPHERE CRM - COMPLETE MISSING TABLES SCHEMA
-- ============================================================================
-- This migration adds ALL missing tables referenced in the 41 services
-- Run this AFTER FINAL_SCHEMA_MIGRATION.sql
-- ============================================================================

-- ============================================================================
-- MISSING CORE BUSINESS TABLES
-- ============================================================================

-- USER_PREFERENCES (critical - referenced by many services)
CREATE TABLE IF NOT EXISTS user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  features jsonb DEFAULT '{}',
  business_type text,
  language text DEFAULT 'en',
  theme text DEFAULT 'light',
  quickbooks_access_token text,
  quickbooks_refresh_token text,
  quickbooks_realm_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- PREPAYMENT_CODES (for prepaid/gift cards)
CREATE TABLE IF NOT EXISTS prepayment_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  code text UNIQUE NOT NULL,
  amount decimal(10, 2) NOT NULL,
  currency text DEFAULT 'USD',
  status text DEFAULT 'active', -- active, redeemed, expired
  redemption_date timestamptz,
  redeemed_by uuid REFERENCES auth.users(id),
  expires_at timestamptz,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- PREPAYMENT_CODE_AUDIT (audit trail)
CREATE TABLE IF NOT EXISTS prepayment_code_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  code_id uuid REFERENCES prepayment_codes(id) ON DELETE CASCADE,
  action text,
  amount decimal(10, 2),
  user_id uuid REFERENCES auth.users(id),
  timestamp timestamptz DEFAULT now()
);

-- RECURRING_INVOICES (for subscription billing)
CREATE TABLE IF NOT EXISTS recurring_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id uuid REFERENCES clients(id) ON DELETE SET NULL,
  amount decimal(10, 2) NOT NULL,
  currency text DEFAULT 'USD',
  frequency text NOT NULL, -- weekly, monthly, quarterly, yearly
  status text DEFAULT 'active', -- active, paused, cancelled, completed
  next_run_date date,
  last_run_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- SUBSCRIPTIONS (for trial/paid plans)
CREATE TABLE IF NOT EXISTS subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  plan text NOT NULL, -- solo, team, workshop, enterprise
  status text DEFAULT 'active', -- active, cancelled, expired, pending
  stripe_subscription_id text,
  paddle_subscription_id text,
  amount decimal(10, 2),
  billing_cycle text, -- monthly, yearly
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- TRIAL_USAGE (track trial feature usage)
CREATE TABLE IF NOT EXISTS trial_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  feature_name text,
  usage_count int DEFAULT 0,
  last_used_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(org_id, feature_name)
);

-- TRIAL_REMINDERS (send reminders before trial expires)
CREATE TABLE IF NOT EXISTS trial_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  reminder_type text, -- 7days, 3days, 1day, expired
  sent_at timestamptz DEFAULT now(),
  UNIQUE(org_id, reminder_type)
);

-- ============================================================================
-- AI & AUTOMATION TABLES
-- ============================================================================

-- AI_AUTOMATION_SETTINGS (control AI features per org)
CREATE TABLE IF NOT EXISTS ai_automation_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  automation_enabled boolean DEFAULT true,
  proactivity_level text DEFAULT 'medium', -- low, medium, high
  agents jsonb DEFAULT '[]'::jsonb, -- list of enabled agents
  monthly_api_limit int DEFAULT 10000,
  monthly_cost_limit decimal(10, 2) DEFAULT 100,
  auto_pause_on_limit boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(org_id)
);

-- AI_USAGE_LOG (track token usage and costs)
CREATE TABLE IF NOT EXISTS ai_usage_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  agent_name text,
  tokens_used int,
  estimated_cost decimal(10, 2),
  timestamp timestamptz DEFAULT now()
);

-- AUTONOMOUS_AI_AGENTS (track agent execution)
CREATE TABLE IF NOT EXISTS autonomous_ai_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  agent_type text, -- ceo, coo, cfo
  status text DEFAULT 'running', -- running, paused, error
  last_execution timestamptz,
  next_execution timestamptz,
  error_message text,
  created_at timestamptz DEFAULT now()
);

-- WASTE_FINDINGS (AI waste/cost detection)
CREATE TABLE IF NOT EXISTS waste_findings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  category text, -- inventory, labor, materials, software
  description text,
  estimated_savings decimal(10, 2),
  severity text DEFAULT 'medium', -- low, medium, high
  status text DEFAULT 'open', -- open, acknowledged, resolved
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- COMMUNICATION & INTEGRATION TABLES
-- ============================================================================

-- WHATSAPP_DELIVERY_LOGS (message tracking)
CREATE TABLE IF NOT EXISTS whatsapp_delivery_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  phone_number text,
  message_sid text UNIQUE,
  message_body text,
  delivery_status text DEFAULT 'sent', -- sent, delivered, failed, read
  delivered_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- COMMUNICATION_LOGS (unified communication tracking)
CREATE TABLE IF NOT EXISTS communication_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  communication_type text, -- email, whatsapp, sms, call
  recipient text,
  subject text,
  body text,
  status text DEFAULT 'sent',
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- MARKETING_FLOWS (email/SMS campaign automation)
CREATE TABLE IF NOT EXISTS marketing_flows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  flow_name text NOT NULL,
  flow_type text, -- email_sequence, sms_campaign, welcome_series
  status text DEFAULT 'draft', -- draft, active, paused, completed
  trigger_event text,
  recipient_count int DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- EMAIL_ENGAGEMENT (track opens, clicks)
CREATE TABLE IF NOT EXISTS email_engagement (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email_id text,
  recipient_email text,
  event_type text, -- sent, opened, clicked, bounced
  event_timestamp timestamptz,
  created_at timestamptz DEFAULT now()
);

-- SMS_CAMPAIGNS (SMS campaign tracking)
CREATE TABLE IF NOT EXISTS sms_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  campaign_name text,
  message_body text,
  recipients_count int,
  sent_count int DEFAULT 0,
  delivery_rate decimal(3, 2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ORGANIZATION_INTEGRATIONS (third-party integration credentials)
CREATE TABLE IF NOT EXISTS organization_integrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  integration_name text NOT NULL, -- stripe, hubspot, quickbooks, slack, etc
  is_active boolean DEFAULT true,
  credentials jsonb, -- encrypted API keys
  activated_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(org_id, integration_name)
);

-- ============================================================================
-- SUPPLY CHAIN & INVENTORY TABLES
-- ============================================================================

-- SUPPLIERS (vendor management)
CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  supplier_name text NOT NULL,
  contact_email text,
  contact_phone text,
  payment_terms text,
  rating decimal(2, 1),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- SUPPLIER_PRODUCT_PRICING (product prices by supplier)
CREATE TABLE IF NOT EXISTS supplier_product_pricing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  supplier_id uuid REFERENCES suppliers(id) ON DELETE CASCADE,
  product_id text,
  product_name text,
  unit_price decimal(10, 2),
  quantity_available int,
  lead_time_days int,
  last_updated timestamptz,
  created_at timestamptz DEFAULT now()
);

-- PURCHASE_ORDERS (PO tracking)
CREATE TABLE IF NOT EXISTS purchase_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
  po_number text UNIQUE,
  total_amount decimal(10, 2),
  status text DEFAULT 'draft', -- draft, sent, confirmed, received, cancelled
  expected_delivery_date date,
  actual_delivery_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- STOCK_MOVEMENTS (inventory movement tracking)
CREATE TABLE IF NOT EXISTS stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  inventory_id uuid REFERENCES inventory(id) ON DELETE CASCADE,
  movement_type text, -- in, out, adjustment, loss
  quantity int NOT NULL,
  reason text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- CLOUD_CONNECTIONS (cloud service accounts)
CREATE TABLE IF NOT EXISTS cloud_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  provider text NOT NULL, -- AWS, Azure, GCP
  account_name text,
  api_key text,
  sync_status text DEFAULT 'not_synced', -- not_synced, syncing, synced, error
  last_sync_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CLOUD_EXPENSES (cloud service expense tracking)
CREATE TABLE IF NOT EXISTS cloud_expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  connection_id uuid REFERENCES cloud_connections(id) ON DELETE CASCADE,
  service_name text,
  monthly_cost decimal(10, 2),
  currency text DEFAULT 'USD',
  billing_date date,
  service_breakdown jsonb, -- breakdown by service category
  trend text DEFAULT 'stable', -- trending_up, trending_down, stable
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- TEAM & DEVICE MANAGEMENT TABLES
-- ============================================================================

-- DEVICE_MANAGEMENT (device registration and approval)
CREATE TABLE IF NOT EXISTS device_management (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_type text NOT NULL, -- mobile, tablet, desktop
  device_name text,
  device_os text, -- iOS, Android, Windows, macOS
  device_id text UNIQUE,
  reference_code text UNIQUE,
  approval_status text DEFAULT 'pending', -- pending, approved, rejected, revoked
  is_active boolean DEFAULT true,
  approved_by uuid REFERENCES auth.users(id),
  approved_at timestamptz,
  last_access_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- DEVICE_ACCESS_LOGS (audit trail for device access)
CREATE TABLE IF NOT EXISTS device_access_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  device_id uuid REFERENCES device_management(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id),
  action text, -- login, logout, access_granted, access_denied
  ip_address text,
  timestamp timestamptz DEFAULT now()
);

-- MEMBER_ACTIVITY_LOGS (track team member actions)
CREATE TABLE IF NOT EXISTS member_activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  member_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type text, -- invoice_created, job_completed, client_added, etc
  activity_details jsonb,
  timestamp timestamptz DEFAULT now()
);

-- LEADS (CRM lead tracking)
CREATE TABLE IF NOT EXISTS leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  lead_name text NOT NULL,
  email text,
  phone text,
  company text,
  status text DEFAULT 'new', -- new, qualified, contacted, cold
  lead_score int DEFAULT 0,
  lead_status text DEFAULT 'hot', -- hot, warm, cold
  source text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- LEAD_ACTIVITIES (track lead interactions)
CREATE TABLE IF NOT EXISTS lead_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  lead_id uuid REFERENCES leads(id) ON DELETE CASCADE,
  activity_type text, -- email, call, meeting, note
  activity_notes text,
  next_followup_date date,
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- BACKUP & AUDIT TABLES
-- ============================================================================

-- ORGANIZATION_BACKUP_SETTINGS (backup configuration)
CREATE TABLE IF NOT EXISTS organization_backup_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  backup_enabled boolean DEFAULT true,
  backup_frequency text DEFAULT 'daily', -- daily, weekly, monthly
  retention_days int DEFAULT 30,
  max_backups int DEFAULT 10,
  last_backup_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(org_id)
);

-- BACKUP_RECORDS (backup history)
CREATE TABLE IF NOT EXISTS backup_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  backup_name text,
  backup_size_mb int,
  status text DEFAULT 'completed', -- pending, in_progress, completed, failed
  backup_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- RESTORE_LOGS (restore operation audit trail)
CREATE TABLE IF NOT EXISTS restore_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  backup_id uuid REFERENCES backup_records(id) ON DELETE SET NULL,
  restored_by uuid REFERENCES auth.users(id),
  restore_status text,
  restored_at timestamptz DEFAULT now()
);

-- RATE_LIMIT_LOG (API rate limiting)
CREATE TABLE IF NOT EXISTS rate_limit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  endpoint text,
  request_count int,
  window_start timestamptz,
  window_end timestamptz,
  created_at timestamptz DEFAULT now()
);

-- FEATURE_AUDIT_LOG (track feature changes for compliance)
CREATE TABLE IF NOT EXISTS feature_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  action text,
  performed_by uuid REFERENCES auth.users(id),
  target_user_id uuid REFERENCES auth.users(id),
  target_device_id uuid,
  details text,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- WHITE LABEL & CUSTOMIZATION TABLES
-- ============================================================================

-- WHITE_LABEL_SETTINGS (white-label branding)
CREATE TABLE IF NOT EXISTS white_label_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_name text,
  brand_color text,
  logo_url text,
  custom_domain text,
  terms_url text,
  privacy_url text,
  support_email text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(org_id)
);

-- COMPANY_PROFILES (company branding/info)
CREATE TABLE IF NOT EXISTS company_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  company_name text NOT NULL,
  company_type text,
  registration_number text,
  tax_id text,
  address text,
  city text,
  country text,
  postal_code text,
  phone text,
  email text,
  website text,
  logo_url text,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(org_id)
);

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- User preferences
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);

-- Prepayment codes
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_org_id ON prepayment_codes(org_id);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_status ON prepayment_codes(status);
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_code ON prepayment_codes(code);

-- Recurring invoices
CREATE INDEX IF NOT EXISTS idx_recurring_invoices_org_id ON recurring_invoices(org_id);
CREATE INDEX IF NOT EXISTS idx_recurring_invoices_status ON recurring_invoices(status);
CREATE INDEX IF NOT EXISTS idx_recurring_invoices_next_run ON recurring_invoices(next_run_date);

-- Subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_org_id ON subscriptions(org_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- AI tables
CREATE INDEX IF NOT EXISTS idx_ai_automation_settings_org_id ON ai_automation_settings(org_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_log_org_id ON ai_usage_log(org_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_log_timestamp ON ai_usage_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_waste_findings_org_id ON waste_findings(org_id);
CREATE INDEX IF NOT EXISTS idx_waste_findings_status ON waste_findings(status);

-- Communication
CREATE INDEX IF NOT EXISTS idx_whatsapp_delivery_logs_org_id ON whatsapp_delivery_logs(org_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_delivery_logs_status ON whatsapp_delivery_logs(delivery_status);
CREATE INDEX IF NOT EXISTS idx_communication_logs_org_id ON communication_logs(org_id);
CREATE INDEX IF NOT EXISTS idx_marketing_flows_org_id ON marketing_flows(org_id);
CREATE INDEX IF NOT EXISTS idx_marketing_flows_status ON marketing_flows(status);
CREATE INDEX IF NOT EXISTS idx_email_engagement_org_id ON email_engagement(org_id);

-- Supply chain
CREATE INDEX IF NOT EXISTS idx_suppliers_org_id ON suppliers(org_id);
CREATE INDEX IF NOT EXISTS idx_supplier_product_pricing_org_id ON supplier_product_pricing(org_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_org_id ON purchase_orders(org_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_stock_movements_org_id ON stock_movements(org_id);
CREATE INDEX IF NOT EXISTS idx_cloud_connections_org_id ON cloud_connections(org_id);
CREATE INDEX IF NOT EXISTS idx_cloud_expenses_org_id ON cloud_expenses(org_id);

-- Team & device
CREATE INDEX IF NOT EXISTS idx_device_management_org_id ON device_management(org_id);
CREATE INDEX IF NOT EXISTS idx_device_management_user_id ON device_management(user_id);
CREATE INDEX IF NOT EXISTS idx_device_access_logs_device_id ON device_access_logs(device_id);
CREATE INDEX IF NOT EXISTS idx_member_activity_logs_org_id ON member_activity_logs(org_id);
CREATE INDEX IF NOT EXISTS idx_leads_org_id ON leads(org_id);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_lead_activities_lead_id ON lead_activities(lead_id);

-- Backup & audit
CREATE INDEX IF NOT EXISTS idx_organization_backup_settings_org_id ON organization_backup_settings(org_id);
CREATE INDEX IF NOT EXISTS idx_backup_records_org_id ON backup_records(org_id);
CREATE INDEX IF NOT EXISTS idx_restore_logs_org_id ON restore_logs(org_id);
CREATE INDEX IF NOT EXISTS idx_rate_limit_log_user_id ON rate_limit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_org_id ON feature_audit_log(org_id);

-- White label
CREATE INDEX IF NOT EXISTS idx_white_label_settings_org_id ON white_label_settings(org_id);
CREATE INDEX IF NOT EXISTS idx_company_profiles_org_id ON company_profiles(org_id);

-- ============================================================================
-- ENABLE RLS ON ALL NEW TABLES
-- ============================================================================

ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE prepayment_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE prepayment_code_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trial_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE trial_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_automation_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE autonomous_ai_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_engagement ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplier_product_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE cloud_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_management ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_backup_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE backup_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE restore_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_limit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE white_label_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES FOR NEW TABLES
-- ============================================================================

-- USER_PREFERENCES (user can see own preferences)
CREATE POLICY "user_preferences_self" ON user_preferences 
  FOR ALL TO authenticated 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ORG-SCOPED TABLES (filtered by org_id using get_user_org_id function)
CREATE POLICY "prepayment_codes_select" ON prepayment_codes 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "prepayment_codes_insert" ON prepayment_codes 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "prepayment_codes_update" ON prepayment_codes 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "recurring_invoices_select" ON recurring_invoices 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "recurring_invoices_insert" ON recurring_invoices 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "recurring_invoices_update" ON recurring_invoices 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "subscriptions_select" ON subscriptions 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "subscriptions_insert" ON subscriptions 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "subscriptions_update" ON subscriptions 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "trial_usage_select" ON trial_usage 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "trial_usage_upsert" ON trial_usage 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "trial_reminders_select" ON trial_reminders 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "trial_reminders_upsert" ON trial_reminders 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "ai_automation_settings_select" ON ai_automation_settings 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "ai_automation_settings_insert" ON ai_automation_settings 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "ai_automation_settings_update" ON ai_automation_settings 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "ai_usage_log_select" ON ai_usage_log 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "ai_usage_log_insert" ON ai_usage_log 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "waste_findings_select" ON waste_findings 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "waste_findings_insert" ON waste_findings 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "waste_findings_update" ON waste_findings 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "whatsapp_delivery_logs_select" ON whatsapp_delivery_logs 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "whatsapp_delivery_logs_insert" ON whatsapp_delivery_logs 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "communication_logs_select" ON communication_logs 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "communication_logs_insert" ON communication_logs 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "marketing_flows_select" ON marketing_flows 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "marketing_flows_insert" ON marketing_flows 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "marketing_flows_update" ON marketing_flows 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "email_engagement_select" ON email_engagement 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "email_engagement_insert" ON email_engagement 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "sms_campaigns_select" ON sms_campaigns 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "sms_campaigns_insert" ON sms_campaigns 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "sms_campaigns_update" ON sms_campaigns 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "organization_integrations_select" ON organization_integrations 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "organization_integrations_insert" ON organization_integrations 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "organization_integrations_update" ON organization_integrations 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "suppliers_select" ON suppliers 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "suppliers_insert" ON suppliers 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "suppliers_update" ON suppliers 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "supplier_product_pricing_select" ON supplier_product_pricing 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "supplier_product_pricing_insert" ON supplier_product_pricing 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "purchase_orders_select" ON purchase_orders 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "purchase_orders_insert" ON purchase_orders 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "purchase_orders_update" ON purchase_orders 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "stock_movements_select" ON stock_movements 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "stock_movements_insert" ON stock_movements 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "cloud_connections_select" ON cloud_connections 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "cloud_connections_insert" ON cloud_connections 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "cloud_connections_update" ON cloud_connections 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "cloud_expenses_select" ON cloud_expenses 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "cloud_expenses_insert" ON cloud_expenses 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "device_management_select" ON device_management 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "device_management_insert" ON device_management 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "device_management_update" ON device_management 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "device_access_logs_select" ON device_access_logs 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "device_access_logs_insert" ON device_access_logs 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "member_activity_logs_select" ON member_activity_logs 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "member_activity_logs_insert" ON member_activity_logs 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "leads_select" ON leads 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "leads_insert" ON leads 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "leads_update" ON leads 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "lead_activities_select" ON lead_activities 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "lead_activities_insert" ON lead_activities 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "organization_backup_settings_select" ON organization_backup_settings 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "organization_backup_settings_insert" ON organization_backup_settings 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "organization_backup_settings_update" ON organization_backup_settings 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "backup_records_select" ON backup_records 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "backup_records_insert" ON backup_records 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "restore_logs_select" ON restore_logs 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "restore_logs_insert" ON restore_logs 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "rate_limit_log_select" ON rate_limit_log 
  FOR SELECT TO authenticated 
  USING (user_id = auth.uid());

CREATE POLICY "rate_limit_log_insert" ON rate_limit_log 
  FOR INSERT TO authenticated 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "feature_audit_log_select" ON feature_audit_log 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "feature_audit_log_insert" ON feature_audit_log 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "white_label_settings_select" ON white_label_settings 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "white_label_settings_insert" ON white_label_settings 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "white_label_settings_update" ON white_label_settings 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "company_profiles_select" ON company_profiles 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "company_profiles_insert" ON company_profiles 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "company_profiles_update" ON company_profiles 
  FOR UPDATE TO authenticated 
  USING (org_id = get_user_org_id())
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "prepayment_code_audit_select" ON prepayment_code_audit 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "prepayment_code_audit_insert" ON prepayment_code_audit 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

CREATE POLICY "autonomous_ai_agents_select" ON autonomous_ai_agents 
  FOR SELECT TO authenticated 
  USING (org_id = get_user_org_id());

CREATE POLICY "autonomous_ai_agents_insert" ON autonomous_ai_agents 
  FOR INSERT TO authenticated 
  WITH CHECK (org_id = get_user_org_id());

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- All 35+ missing tables have been created with:
-- ✅ Complete column definitions
-- ✅ Foreign key relationships
-- ✅ Unique constraints
-- ✅ Indexes for performance
-- ✅ RLS enabled on all tables
-- ✅ RLS policies for multi-tenant isolation
-- 
-- Next steps:
-- 1. Run this migration in Supabase SQL Editor
-- 2. Verify tables with: SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;
-- 3. Verify RLS: SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname='public';
-- 4. Test multi-tenant isolation
-- ============================================================================
