-- Test Script: Owner Feature Control & Audit Logging
-- Run this to verify the migration was applied correctly

-- 1. Check organizations table has new columns
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns 
  WHERE table_name='organizations' AND column_name='feature_lock_enabled'
) as has_feature_lock_enabled;

-- 2. Check feature_personalization table has new columns
SELECT EXISTS (
  SELECT 1 FROM information_schema.columns 
  WHERE table_name='feature_personalization' AND column_name='is_owner_enforced'
) as has_owner_enforced;

-- 3. Check feature_audit_log table exists
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_name='feature_audit_log'
) as feature_audit_log_exists;

-- 4. Check RLS is enabled on feature_audit_log
SELECT relrowsecurity FROM pg_class 
WHERE relname='feature_audit_log';

-- 5. Check indexes exist
SELECT COUNT(*) as audit_log_indexes FROM pg_indexes 
WHERE tablename='feature_audit_log';

-- 6. Check triggers exist
SELECT COUNT(*) as triggers_count FROM information_schema.triggers 
WHERE trigger_name='feature_personalization_audit_trigger';

-- 7. Test RLS policy creation
SELECT COUNT(*) as policies_count FROM pg_policies 
WHERE tablename='feature_audit_log';

-- 8. Display all new columns in organizations table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name='organizations' AND column_name IN (
  'feature_lock_enabled', 'locked_features', 'feature_lock_reason', 
  'feature_lock_by', 'feature_lock_at', 'feature_unlock_at'
)
ORDER BY ordinal_position DESC;

-- 9. Display all new columns in feature_personalization table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name='feature_personalization' AND column_name IN (
  'is_owner_enforced', 'enforced_by', 'enforced_at', 'disabled_features',
  'disabled_by_owner', 'disabled_by', 'disabled_at'
)
ORDER BY ordinal_position DESC;

-- 10. Test: Create a mock audit log entry
-- (This will fail if RLS isn't working correctly)
-- INSERT INTO feature_audit_log (
--   org_id,
--   action,
--   performed_by,
--   details
-- ) VALUES (
--   '00000000-0000-0000-0000-000000000000'::uuid,
--   'test_action',
--   '00000000-0000-0000-0000-000000000000'::uuid,
--   'Test entry for validation'
-- );

ECHO '✅ Schema validation complete';
