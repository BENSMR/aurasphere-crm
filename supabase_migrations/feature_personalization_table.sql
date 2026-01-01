-- Create feature_personalization table
-- Stores user feature preferences for mobile and tablet devices
CREATE TABLE IF NOT EXISTS feature_personalization (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_type TEXT NOT NULL CHECK (device_type IN ('mobile', 'tablet')),
  selected_features TEXT[] NOT NULL DEFAULT '{}',
  feature_details JSONB,
  archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, device_type)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_feature_personalization_user_id 
  ON feature_personalization(user_id);

CREATE INDEX IF NOT EXISTS idx_feature_personalization_device_type 
  ON feature_personalization(device_type);

CREATE INDEX IF NOT EXISTS idx_feature_personalization_user_device 
  ON feature_personalization(user_id, device_type);

CREATE INDEX IF NOT EXISTS idx_feature_personalization_archived 
  ON feature_personalization(archived) 
  WHERE archived = FALSE;

-- Enable RLS
ALTER TABLE feature_personalization ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Allow users to view their own preferences
CREATE POLICY "Users can view their own feature preferences"
  ON feature_personalization
  FOR SELECT
  USING (auth.uid() = user_id);

-- Allow users to insert their own preferences
CREATE POLICY "Users can create their own feature preferences"
  ON feature_personalization
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own preferences
CREATE POLICY "Users can update their own feature preferences"
  ON feature_personalization
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own preferences
CREATE POLICY "Users can delete their own feature preferences"
  ON feature_personalization
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_feature_personalization_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_feature_personalization_updated_at ON feature_personalization;

CREATE TRIGGER update_feature_personalization_updated_at
BEFORE UPDATE ON feature_personalization
FOR EACH ROW
EXECUTE FUNCTION update_feature_personalization_timestamp();

-- Add comments
COMMENT ON TABLE feature_personalization IS 'Stores user feature preferences for mobile and tablet devices';
COMMENT ON COLUMN feature_personalization.device_type IS 'Device type: mobile or tablet';
COMMENT ON COLUMN feature_personalization.selected_features IS 'Array of selected feature IDs';
COMMENT ON COLUMN feature_personalization.feature_details IS 'JSONB with detailed feature metadata';
COMMENT ON COLUMN feature_personalization.archived IS 'Soft delete flag for account deactivation';
