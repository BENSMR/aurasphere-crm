-- Add business_type column to user_preferences table
-- Run this in your Supabase SQL Editor

ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS business_type TEXT;

-- Optional: Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_preferences_business_type 
ON user_preferences(business_type);

-- Optional: Add comment
COMMENT ON COLUMN user_preferences.business_type IS 'User business type: freelancer or trades';
