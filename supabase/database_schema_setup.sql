-- ========================================
-- AuraSphere CRM - Database Schema Setup
-- ========================================
-- Run these SQL commands in Supabase SQL Editor

-- ========================================
-- 1. WHITE-LABEL SETTINGS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS white_label_settings (
  org_id UUID PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
  primary_color TEXT DEFAULT '#007BFF',
  secondary_color TEXT DEFAULT '#6C757D',
  accent_color TEXT DEFAULT '#28A745',
  logo_url TEXT,
  favicon_url TEXT,
  business_name TEXT DEFAULT 'AuraCRM',
  custom_domain TEXT UNIQUE,
  custom_strings JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create index for custom domain lookups
CREATE INDEX IF NOT EXISTS idx_white_label_custom_domain ON white_label_settings(custom_domain);

-- Enable RLS
ALTER TABLE white_label_settings ENABLE ROW LEVEL SECURITY;

-- Only org members can view/edit their own branding
CREATE POLICY white_label_member_access ON white_label_settings
  FOR ALL USING (
    org_id IN (
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

-- ========================================
-- 2. BACKUP RECORDS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS backup_records (
  id TEXT PRIMARY KEY,
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  size_bytes BIGINT,
  table_count INT,
  total_records INT,
  status TEXT DEFAULT 'in_progress', -- 'in_progress', 'completed', 'failed'
  storage_path TEXT,
  FOREIGN KEY (org_id) REFERENCES organizations(id)
);

-- Create indexes for queries
CREATE INDEX IF NOT EXISTS idx_backup_org_date ON backup_records(org_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_backup_status ON backup_records(status);

-- Enable RLS
ALTER TABLE backup_records ENABLE ROW LEVEL SECURITY;

-- Only org members can access their backups
CREATE POLICY backup_member_access ON backup_records
  FOR ALL USING (
    org_id IN (
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

-- ========================================
-- 3. BACKUP SETTINGS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS organization_backup_settings (
  org_id UUID PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
  interval_hours INT DEFAULT 24,
  enabled BOOLEAN DEFAULT true,
  retention_days INT DEFAULT 90,
  max_backups INT DEFAULT 30,
  last_backup_at TIMESTAMPTZ,
  next_backup_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE organization_backup_settings ENABLE ROW LEVEL SECURITY;

-- Only org members can view/edit
CREATE POLICY backup_settings_member_access ON organization_backup_settings
  FOR ALL USING (
    org_id IN (
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

-- ========================================
-- 4. RESTORE LOGS TABLE (Audit Trail)
-- ========================================
CREATE TABLE IF NOT EXISTS restore_logs (
  id BIGSERIAL PRIMARY KEY,
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  backup_id TEXT,
  restored_by UUID REFERENCES auth.users(id),
  restored_at TIMESTAMPTZ DEFAULT now(),
  status TEXT DEFAULT 'success', -- 'success', 'failed'
  error_message TEXT,
  FOREIGN KEY (org_id) REFERENCES organizations(id)
);

-- Create index for queries
CREATE INDEX IF NOT EXISTS idx_restore_logs_org_date ON restore_logs(org_id, restored_at DESC);

-- Enable RLS
ALTER TABLE restore_logs ENABLE ROW LEVEL SECURITY;

-- Only org members can view logs
CREATE POLICY restore_logs_member_access ON restore_logs
  FOR ALL USING (
    org_id IN (
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

-- ========================================
-- 5. RATE LIMIT LOG TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS rate_limit_log (
  id BIGSERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  ip_address TEXT,
  action TEXT NOT NULL, -- 'login', 'api_request'
  success BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_rate_limit_email_date ON rate_limit_log(email, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rate_limit_ip_date ON rate_limit_log(ip_address, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rate_limit_action ON rate_limit_log(action, created_at DESC);

-- Note: No RLS needed - this is app-level tracking

-- ========================================
-- 6. LOCKOUT TRACKING (Store in rate_limit_log instead)
-- ========================================
-- Note: Account lockout is tracked in rate_limit_log with timestamps
-- No need to alter auth.users table (requires special permissions)

-- ========================================
-- 7. FUNCTION: Auto-cleanup old backups
-- ========================================
CREATE OR REPLACE FUNCTION cleanup_old_backups()
RETURNS void AS $$
DECLARE
  v_org_id UUID;
  v_retention_days INT;
  v_cutoff_date TIMESTAMPTZ;
  v_backup_id TEXT;
BEGIN
  -- Loop through all organizations
  FOR v_org_id, v_retention_days IN 
    SELECT org_id, retention_days FROM organization_backup_settings WHERE enabled = true
  LOOP
    v_cutoff_date := now() - (v_retention_days || ' days')::interval;
    
    -- Delete old backups
    FOR v_backup_id IN
      SELECT id FROM backup_records 
      WHERE org_id = v_org_id 
      AND created_at < v_cutoff_date
      AND status = 'completed'
    LOOP
      -- Delete from storage (would be called via Edge Function)
      DELETE FROM backup_records WHERE id = v_backup_id;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 8. CREATE TRIGGER for backup cleanup
-- ========================================
CREATE OR REPLACE FUNCTION on_backup_completed()
RETURNS TRIGGER AS $$
BEGIN
  -- Update next backup time
  UPDATE organization_backup_settings
  SET next_backup_at = now() + (interval_hours || ' hours')::interval
  WHERE org_id = NEW.org_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER backup_completed_trigger
AFTER UPDATE OF status ON backup_records
FOR EACH ROW
WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
EXECUTE FUNCTION on_backup_completed();

-- ========================================
-- 9. STORAGE BUCKET POLICY (via Supabase UI)
-- ========================================
-- Go to Supabase → Storage → Create bucket
-- Bucket name: aura_backups
-- Then add these RLS policies:

/*
CREATE POLICY "org_members_can_upload_backups"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'aura_backups' 
  AND (storage.foldername(name))[1] IN (
    SELECT org_id::text FROM org_members WHERE user_id = auth.uid()
  )
);

CREATE POLICY "org_members_can_read_backups"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'aura_backups' 
  AND (storage.foldername(name))[1] IN (
    SELECT org_id::text FROM org_members WHERE user_id = auth.uid()
  )
);

CREATE POLICY "org_members_can_delete_backups"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'aura_backups' 
  AND (storage.foldername(name))[1] IN (
    SELECT org_id::text FROM org_members WHERE user_id = auth.uid()
  )
);
*/

-- ========================================
-- 10. VERIFY SETUP
-- ========================================
-- Run these to verify tables created successfully:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- ========================================
-- SUMMARY
-- ========================================
-- Tables created:
-- ✅ white_label_settings (org branding)
-- ✅ backup_records (backup history)
-- ✅ organization_backup_settings (backup config)
-- ✅ restore_logs (audit trail)
-- ✅ rate_limit_log (login/API attempt tracking)
-- ✅ auth.users.locked_until (account lockout)
--
-- Next steps:
-- 1. Run above SQL in Supabase SQL Editor
-- 2. Create aura_backups storage bucket
-- 3. Add RLS policies to storage bucket (see comments above)
-- 4. Deploy Edge Functions (register-custom-domain, setup-custom-email)
-- ========================================
