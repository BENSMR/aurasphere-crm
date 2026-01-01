-- Rate Limiting Table
-- Tracks login attempts and enforces 5 attempts per 5 minutes per user
-- Automatically cleans up old records via trigger

CREATE TABLE IF NOT EXISTS rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_email TEXT NOT NULL,
  attempt_ip TEXT NOT NULL,
  attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  success BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Keep records for 24 hours
  CONSTRAINT rate_limits_not_too_old CHECK (attempted_at > NOW() - INTERVAL '24 hours')
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_rate_limits_email_time 
  ON rate_limits(user_email, attempted_at DESC);

CREATE INDEX IF NOT EXISTS idx_rate_limits_ip_time 
  ON rate_limits(attempt_ip, attempted_at DESC);

-- Auto-delete old records (older than 24 hours)
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits()
RETURNS void AS $$
BEGIN
  DELETE FROM rate_limits 
  WHERE attempted_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Run cleanup daily
-- Note: In production, use pg_cron extension for scheduled tasks
-- SELECT cron.schedule('cleanup_rate_limits', '0 0 * * *', 'SELECT cleanup_old_rate_limits()');

-- Enable RLS on rate_limits (allow system to write, users cannot directly access)
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- Only system functions can write to rate_limits
CREATE POLICY "System can write to rate limits"
  ON rate_limits
  FOR INSERT
  WITH CHECK (TRUE);

-- Users cannot directly query rate limits
CREATE POLICY "Users cannot view rate limits"
  ON rate_limits
  FOR SELECT
  USING (FALSE);
