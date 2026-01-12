-- Migration: Add Owner Feature Control & Audit Logging
-- Purpose: Enable organization owners to control team member features org-wide
-- Date: January 11, 2026

-- 1. Add owner control columns to organizations table
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS feature_lock_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS locked_features JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS feature_lock_reason VARCHAR(500) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS feature_lock_by UUID DEFAULT NULL,
ADD COLUMN IF NOT EXISTS feature_lock_at TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS feature_unlock_at TIMESTAMPTZ DEFAULT NULL;

-- 2. Add owner enforcement columns to feature_personalization table
ALTER TABLE feature_personalization
ADD COLUMN IF NOT EXISTS is_owner_enforced BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS enforced_by UUID DEFAULT NULL,
ADD COLUMN IF NOT EXISTS enforced_at TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS disabled_features JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS disabled_by_owner BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS disabled_by UUID DEFAULT NULL,
ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMPTZ DEFAULT NULL;

-- 3. Create feature_audit_log table for complete audit trail
CREATE TABLE IF NOT EXISTS feature_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  action VARCHAR(100) NOT NULL,
  performed_by UUID NOT NULL,
  target_user_id UUID,
  target_device_id UUID,
  details TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT fk_audit_org FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE,
  CONSTRAINT fk_audit_performer FOREIGN KEY (performed_by) REFERENCES auth.users(id) ON DELETE SET NULL,
  CONSTRAINT fk_audit_target FOREIGN KEY (target_user_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 4. Create indexes for faster audit log queries
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_org_id ON feature_audit_log(org_id);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_created_at ON feature_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_action ON feature_audit_log(action);
CREATE INDEX IF NOT EXISTS idx_feature_audit_log_performer ON feature_audit_log(performed_by);

-- 5. Enable RLS on feature_audit_log (org-wide read for owner, write by system only)
ALTER TABLE feature_audit_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policy: Owners can view their org's audit logs
CREATE POLICY audit_log_owner_view ON feature_audit_log
  FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
    )
  );

-- Create RLS policy: System/Service can insert audit logs
CREATE POLICY audit_log_service_insert ON feature_audit_log
  FOR INSERT
  WITH CHECK (true);

-- 6. Create audit trigger to log direct feature_personalization changes
CREATE OR REPLACE FUNCTION log_feature_personalization_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Log when owner enforcement is set
  IF NEW.is_owner_enforced != OLD.is_owner_enforced THEN
    INSERT INTO feature_audit_log (
      org_id,
      action,
      performed_by,
      target_user_id,
      details
    )
    SELECT
      o.id,
      CASE WHEN NEW.is_owner_enforced THEN 'feature_enforcement_enabled' ELSE 'feature_enforcement_disabled' END,
      NEW.enforced_by,
      NEW.user_id,
      'Features automatically logged by trigger'
    FROM organizations o
    WHERE o.id = (SELECT org_id FROM devices WHERE id = (SELECT device_id FROM feature_personalization fp WHERE fp.id = NEW.id LIMIT 1) LIMIT 1);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF NOT EXISTS feature_personalization_audit_trigger ON feature_personalization;
CREATE TRIGGER feature_personalization_audit_trigger
AFTER UPDATE ON feature_personalization
FOR EACH ROW
EXECUTE FUNCTION log_feature_personalization_change();

-- 7. Add comment documenting owner control features
COMMENT ON TABLE feature_audit_log IS 'Audit trail for all feature changes made by organization owners for compliance and security';
COMMENT ON COLUMN feature_audit_log.action IS 'Type of action: force_enable_all_features, disable_features, lock_features_org_wide, reset_all_team_features, etc';
COMMENT ON COLUMN feature_audit_log.performed_by IS 'Organization owner who performed the action';
COMMENT ON COLUMN feature_audit_log.target_user_id IS 'Team member affected by the action (NULL if org-wide)';

-- 8. Grant permissions
GRANT SELECT ON feature_audit_log TO authenticated;
GRANT INSERT ON feature_audit_log TO service_role;
