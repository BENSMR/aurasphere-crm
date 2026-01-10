-- Migration: Add Digital Signature Support
-- File: supabase/migrations/20260110_add_digital_signatures.sql
-- Purpose: Enable invoice signing with XAdES-B, RSA-SHA256, UTF-8 encoding

-- Digital Certificates Table
CREATE TABLE IF NOT EXISTS digital_certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  -- Certificate metadata
  name TEXT NOT NULL,
  certificate_pem TEXT NOT NULL, -- PEM encoded certificate
  subject TEXT NOT NULL, -- CN=Company, O=Organization, C=Country
  issuer TEXT NOT NULL,
  serial_number TEXT NOT NULL,
  
  -- Validity dates
  valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
  valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
  
  -- Algorithm and status
  algorithm TEXT NOT NULL DEFAULT 'RSA-SHA256', -- RSA-SHA256, RSA-SHA512
  status TEXT NOT NULL DEFAULT 'active', -- active, revoked, expired
  
  -- Revocation
  revoked_at TIMESTAMP WITH TIME ZONE,
  revoked_reason TEXT,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by uuid REFERENCES auth.users(id),
  
  CONSTRAINT valid_algorithm CHECK (algorithm IN ('RSA-SHA256', 'RSA-SHA512')),
  CONSTRAINT valid_status CHECK (status IN ('active', 'revoked', 'expired'))
);

-- Invoice Signatures Table
CREATE TABLE IF NOT EXISTS invoice_signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  certificate_id uuid NOT NULL REFERENCES digital_certificates(id),
  
  -- Signature data
  signature_value TEXT NOT NULL, -- Base64 encoded signature
  xades_xml TEXT NOT NULL, -- Full XAdES XML structure
  
  -- Algorithm and standard
  algorithm TEXT NOT NULL DEFAULT 'RSA-SHA256',
  xades_level TEXT NOT NULL DEFAULT 'B', -- B, T, C, X
  
  -- Status
  status TEXT NOT NULL DEFAULT 'valid', -- valid, invalid, expired
  
  -- Timestamps
  signed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  verified_at TIMESTAMP WITH TIME ZONE,
  
  -- Encoding
  encoding TEXT DEFAULT 'UTF-8', -- UTF-8, UTF-16, ASCII
  
  -- Metadata
  ip_address INET,
  user_agent TEXT,
  signature_method TEXT DEFAULT 'PKCS#7', -- PKCS#7, CMS, XMLDSig
  
  CONSTRAINT valid_algorithm CHECK (algorithm IN ('RSA-SHA256', 'RSA-SHA512')),
  CONSTRAINT valid_xades_level CHECK (xades_level IN ('B', 'T', 'C', 'X')),
  CONSTRAINT valid_status CHECK (status IN ('valid', 'invalid', 'expired')),
  CONSTRAINT valid_encoding CHECK (encoding IN ('UTF-8', 'UTF-16', 'ASCII'))
);

-- Audit Trail for Signatures
CREATE TABLE IF NOT EXISTS signature_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  signature_id uuid NOT NULL REFERENCES invoice_signatures(id) ON DELETE CASCADE,
  
  action TEXT NOT NULL, -- created, verified, revoked, expired
  performed_by uuid REFERENCES auth.users(id),
  reason TEXT,
  
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT valid_action CHECK (action IN ('created', 'verified', 'revoked', 'expired'))
);

-- Timestamp Authority Logs (for XAdES-T support)
CREATE TABLE IF NOT EXISTS timestamp_authority_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  signature_id uuid NOT NULL REFERENCES invoice_signatures(id) ON DELETE CASCADE,
  
  tsa_url TEXT NOT NULL,
  request_id TEXT,
  timestamp_value TEXT NOT NULL, -- TSA timestamp
  
  status TEXT DEFAULT 'success', -- success, pending, failed
  error_message TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for Digital Certificates
ALTER TABLE digital_certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "organizations_own_certificates" ON digital_certificates
  FOR SELECT
  USING (org_id IN (
    SELECT id FROM organizations 
    WHERE owner_id = auth.uid() OR 
          id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ));

CREATE POLICY "organizations_insert_certificates" ON digital_certificates
  FOR INSERT
  WITH CHECK (org_id IN (
    SELECT id FROM organizations WHERE owner_id = auth.uid()
  ));

-- RLS Policies for Invoice Signatures
ALTER TABLE invoice_signatures ENABLE ROW LEVEL SECURITY;

CREATE POLICY "organizations_own_signatures" ON invoice_signatures
  FOR SELECT
  USING (org_id IN (
    SELECT id FROM organizations 
    WHERE owner_id = auth.uid() OR 
          id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ));

CREATE POLICY "organizations_create_signatures" ON invoice_signatures
  FOR INSERT
  WITH CHECK (org_id IN (
    SELECT id FROM organizations WHERE owner_id = auth.uid()
  ));

-- RLS Policies for Audit Log
ALTER TABLE signature_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "organizations_view_audit_log" ON signature_audit_log
  FOR SELECT
  USING (org_id IN (
    SELECT id FROM organizations WHERE owner_id = auth.uid()
  ));

-- Indexes for Performance
CREATE INDEX idx_digital_certificates_org_id ON digital_certificates(org_id);
CREATE INDEX idx_digital_certificates_status ON digital_certificates(status);
CREATE INDEX idx_invoice_signatures_org_id ON invoice_signatures(org_id);
CREATE INDEX idx_invoice_signatures_invoice_id ON invoice_signatures(invoice_id);
CREATE INDEX idx_invoice_signatures_status ON invoice_signatures(status);
CREATE INDEX idx_signature_audit_log_signature_id ON signature_audit_log(signature_id);

-- Comments for documentation
COMMENT ON TABLE digital_certificates IS 'Digital certificates for invoice signing (XAdES-B, RSA-SHA256)';
COMMENT ON TABLE invoice_signatures IS 'Signed invoices with XAdES XML structure and UTF-8 encoding';
COMMENT ON TABLE signature_audit_log IS 'Audit trail for all signature operations';
COMMENT ON TABLE timestamp_authority_logs IS 'Logs from trusted timestamp authority (TSA) for XAdES-T support';

COMMENT ON COLUMN digital_certificates.algorithm IS 'Signing algorithm: RSA-SHA256 or RSA-SHA512';
COMMENT ON COLUMN invoice_signatures.xades_level IS 'XAdES level: B=Basic, T=Timestamped, C=Complete, X=X-Long';
COMMENT ON COLUMN invoice_signatures.encoding IS 'File encoding: UTF-8 (recommended), UTF-16, ASCII';
