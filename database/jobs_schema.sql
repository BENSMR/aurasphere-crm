-- AuraSphere CRM Database Schema Extensions
-- For contractors, tradespeople, and service businesses

-- ============================================
-- JOBS TABLE (Chantiers / Worksites)
-- ============================================
-- Tracks job sites, projects, and work orders
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  title TEXT NOT NULL, -- "Bathroom renovation - Ahmed"
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  address TEXT, -- Job site address (different from client address)
  notes TEXT,
  scheduled_date TIMESTAMPTZ,
  completion_date TIMESTAMPTZ,
  estimated_hours NUMERIC(10,2),
  actual_hours NUMERIC(10,2),
  estimated_cost NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_jobs_org_id ON jobs(org_id);
CREATE INDEX idx_jobs_client_id ON jobs(client_id);
CREATE INDEX idx_jobs_status ON jobs(status);

-- Enable Row Level Security
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view jobs in their organization"
  ON jobs FOR SELECT
  USING (
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
      UNION
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert jobs in their organization"
  ON jobs FOR INSERT
  WITH CHECK (
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
      UNION
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update jobs in their organization"
  ON jobs FOR UPDATE
  USING (
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
      UNION
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete jobs in their organization"
  ON jobs FOR DELETE
  USING (
    org_id IN (
      SELECT id FROM organizations WHERE owner_id = auth.uid()
      UNION
      SELECT org_id FROM org_members WHERE user_id = auth.uid()
    )
  );

-- ============================================
-- JOB ITEMS / LINE ITEMS (Materials & Labor)
-- ============================================
-- Track materials used and labor hours per job
CREATE TABLE IF NOT EXISTS job_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('material', 'labor')),
  description TEXT NOT NULL,
  quantity NUMERIC(10,2) DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  total NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_job_items_job_id ON job_items(job_id);

-- Enable RLS
ALTER TABLE job_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage job items through jobs"
  ON job_items FOR ALL
  USING (
    job_id IN (
      SELECT id FROM jobs WHERE org_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
        UNION
        SELECT org_id FROM org_members WHERE user_id = auth.uid()
      )
    )
  );

-- ============================================
-- JOB PHOTOS (Before/After, Progress)
-- ============================================
-- Track photos for documentation and customer proof
CREATE TABLE IF NOT EXISTS job_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL, -- Supabase Storage path
  caption TEXT,
  photo_type TEXT CHECK (photo_type IN ('before', 'progress', 'after', 'issue')),
  taken_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_job_photos_job_id ON job_photos(job_id);

-- Enable RLS
ALTER TABLE job_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage job photos through jobs"
  ON job_photos FOR ALL
  USING (
    job_id IN (
      SELECT id FROM jobs WHERE org_id IN (
        SELECT id FROM organizations WHERE owner_id = auth.uid()
        UNION
        SELECT org_id FROM org_members WHERE user_id = auth.uid()
      )
    )
  );

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update jobs.updated_at
CREATE TRIGGER update_jobs_updated_at
  BEFORE UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- Job Summary View
CREATE OR REPLACE VIEW job_summary AS
SELECT 
  j.id,
  j.title,
  j.status,
  j.address,
  c.name AS client_name,
  c.email AS client_email,
  j.scheduled_date,
  j.completion_date,
  j.estimated_cost,
  COALESCE(SUM(ji.total), 0) AS actual_cost,
  j.estimated_hours,
  j.actual_hours,
  COUNT(DISTINCT jp.id) AS photo_count,
  j.created_at,
  j.updated_at
FROM jobs j
LEFT JOIN clients c ON j.client_id = c.id
LEFT JOIN job_items ji ON j.id = ji.job_id
LEFT JOIN job_photos jp ON j.id = jp.job_id
GROUP BY j.id, c.name, c.email;

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================
-- Uncomment to insert test data
/*
INSERT INTO jobs (org_id, client_id, title, status, address, notes, scheduled_date, estimated_cost, estimated_hours)
VALUES 
  ((SELECT id FROM organizations LIMIT 1), (SELECT id FROM clients LIMIT 1), 'Kitchen Plumbing Repair', 'in_progress', '123 Main St, Apt 4', 'Replace leaking pipes under sink', NOW() + INTERVAL '2 days', 350.00, 4.0),
  ((SELECT id FROM organizations LIMIT 1), (SELECT id FROM clients LIMIT 1), 'Electrical Panel Upgrade', 'pending', '456 Oak Ave', 'Upgrade to 200A service', NOW() + INTERVAL '5 days', 2500.00, 12.0);
*/

-- ============================================
-- NOTES
-- ============================================
-- After running this schema:
-- 1. Create Supabase Storage bucket: 'job-photos'
-- 2. Set RLS policies on storage bucket
-- 3. Update Flutter app to use jobs table
-- 4. Add jobs page to bottom navigation
-- 5. Integrate with invoicing (link jobs to invoices)
