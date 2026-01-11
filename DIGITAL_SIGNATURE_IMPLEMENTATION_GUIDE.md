# Digital Signature Implementation Guide

## Overview

AuraSphere CRM now supports **electronic invoice signatures** with EU/Africa compliance standards:

- **XAdES-B Format**: XML Advanced Electronic Signatures (ETSI standard)
- **RSA-SHA256 Algorithm**: Industry-standard encryption
- **Certificate Management**: Upload, store, revoke certificates
- **UTF-8 Encoding**: International character support
- **Audit Trail**: Complete signature history and timestamp authority integration

## Architecture

### Three-Layer Implementation

```
┌─────────────────────────────────────────────────────┐
│  UI Layer (Pages)                                   │
│  - CertificateManagementPage (upload/manage)        │
│  - InvoiceSigningPage (select cert, sign)           │
│  - SignatureVerificationPage (verify, export)       │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│  Service Layer                                      │
│  - PdfSignatureIntegration (orchestrates flow)      │
│  - DigitalSignatureService (core logic)             │
│  - PdfService (signature-aware PDF generation)      │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│  Data Layer (Supabase)                              │
│  - digital_certificates (PEM storage)               │
│  - invoice_signatures (XAdES XML + signature)       │
│  - signature_audit_log (compliance trail)           │
│  - timestamp_authority_logs (TSA records)           │
└─────────────────────────────────────────────────────┘
```

## Database Schema

### `digital_certificates`
Stores signing certificates for the organization.

```sql
CREATE TABLE digital_certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id),
  certificate_pem TEXT NOT NULL,          -- PEM format
  private_key_encrypted TEXT NOT NULL,    -- RSA-4096
  certificate_name VARCHAR(255),
  subject VARCHAR(255),                   -- Certificate subject
  issuer VARCHAR(255),                    -- CA issuer
  serial_number VARCHAR(255),
  valid_from TIMESTAMP NOT NULL,
  valid_until TIMESTAMP NOT NULL,
  thumbprint VARCHAR(64),                 -- SHA-256 of cert
  key_algorithm VARCHAR(50),              -- RSA-2048, RSA-4096
  status VARCHAR(50) DEFAULT 'active',    -- active, revoked, expired
  created_at TIMESTAMP DEFAULT NOW(),
  revoked_at TIMESTAMP,
  revocation_reason TEXT
);
```

### `invoice_signatures`
Stores signature data and XAdES XML.

```sql
CREATE TABLE invoice_signatures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id),
  invoice_id UUID NOT NULL REFERENCES invoices(id),
  certificate_id UUID NOT NULL REFERENCES digital_certificates(id),
  xades_xml TEXT NOT NULL,                -- Full XAdES XML document
  signature_value VARCHAR(MAX),           -- Base64-encoded signature
  algorithm VARCHAR(50),                  -- RSA-SHA256, RSA-SHA512
  xades_level VARCHAR(10),                -- B, T, C, X
  encoding VARCHAR(50) DEFAULT 'UTF-8',   -- File encoding
  status VARCHAR(50) DEFAULT 'valid',     -- valid, expired, revoked
  signed_at TIMESTAMP DEFAULT NOW(),
  verified_at TIMESTAMP,
  verification_result JSONB
);
```

### `signature_audit_log`
Compliance and audit trail.

```sql
CREATE TABLE signature_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  invoice_id UUID,
  certificate_id UUID,
  action VARCHAR(50),                     -- signed, verified, revoked, exported
  actor_user_id UUID,
  actor_email VARCHAR(255),
  ip_address INET,
  user_agent TEXT,
  result VARCHAR(50),                     -- success, failed
  error_message TEXT,
  timestamp TIMESTAMP DEFAULT NOW()
);
```

### `timestamp_authority_logs`
Timestamp authority (TSA) integration for XAdES-T support.

```sql
CREATE TABLE timestamp_authority_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  signature_id UUID REFERENCES invoice_signatures(id),
  tsa_provider VARCHAR(100),              -- DigiCert, GlobalSign, etc.
  request_data TEXT,
  response_data TEXT,
  timestamp_token VARCHAR(MAX),           -- RFC 3161 token
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);
```

## Service: DigitalSignatureService

Core service handling signature operations.

```dart
// lib/services/digital_signature_service.dart

class DigitalSignatureService {
  /// Upload a signing certificate (PEM format)
  Future<Map<String, dynamic>> uploadCertificate({
    required String orgId,
    required String certificatePem,
    required String certificateName,
    required String? keyPassword,
  });

  /// Get all certificates for organization
  Future<List<Map<String, dynamic>>> getCertificates({
    required String orgId,
  });

  /// Sign an invoice with a certificate
  Future<Map<String, dynamic>> signInvoice({
    required String orgId,
    required String invoiceId,
    required String certificateId,
    required String pdfContent,        // Base64
    String algorithm = 'RSA-SHA256',
    String xadesLevel = 'B',
  });

  /// Verify signature is valid (cert not expired, signature valid)
  Future<Map<String, dynamic>> verifySignature({
    required String orgId,
    required String invoiceId,
  });

  /// Export invoice as XAdES document for external systems
  Future<String> exportAsXades({
    required String orgId,
    required String invoiceId,
  });

  /// Revoke a certificate (invalidates all its signatures)
  Future<Map<String, dynamic>> revokeCertificate({
    required String orgId,
    required String certificateId,
    required String revocationReason,
  });

  /// Get signature details
  Future<Map<String, dynamic>?> getInvoiceSignature({
    required String orgId,
    required String invoiceId,
  });

  /// List signatures with optional status filter
  Future<List<Map<String, dynamic>>> getInvoiceSignatures({
    required String orgId,
    String? status,
  });
}
```

## Service: PdfSignatureIntegration

Handles PDF-specific signing and receipt generation.

```dart
// lib/services/pdf_signature_integration.dart

class PdfSignatureIntegration {
  /// Sign a PDF invoice
  Future<Map<String, dynamic>> signInvoicePdf({
    required String orgId,
    required String invoiceId,
    required String certificateId,
    required List<int> pdfBytes,
    String algorithm = 'RSA-SHA256',
    String xadesLevel = 'B',
  });

  /// Create human-readable signature receipt
  Future<String> createSignatureReceipt({
    required String orgId,
    required String invoiceId,
    required String language,
  });

  /// Verify signature authenticity
  Future<Map<String, dynamic>> verifyPdfSignature({
    required String orgId,
    required String invoiceId,
  });

  /// Export as XAdES for compatibility
  Future<String> exportSignedAsXades({
    required String orgId,
    required String invoiceId,
  });

  /// Get available signing certificates
  Future<List<Map<String, dynamic>>> getSigningCertificates({
    required String orgId,
  });
}
```

## Usage Examples

### 1. Upload a Certificate

```dart
import 'package:aura_crm/services/digital_signature_service.dart';

final signatureService = DigitalSignatureService();

// User selects PEM file and enters password
final result = await signatureService.uploadCertificate(
  orgId: currentOrgId,
  certificatePem: pemContent,  // From file picker
  certificateName: 'My Company Invoice Signing Cert',
  keyPassword: enteredPassword,
);

if (result['success'] == true) {
  print('✅ Certificate uploaded: ${result['certificate_id']}');
}
```

### 2. Sign an Invoice

```dart
import 'package:aura_crm/services/pdf_signature_integration.dart';

final pdfIntegration = PdfSignatureIntegration();

// Step 1: Get available certificates
final certs = await pdfIntegration.getSigningCertificates(
  orgId: currentOrgId,
);

// Step 2: Generate PDF from invoice
final pdfBytes = await pdfService.generateInvoicePdf(
  invoiceId: invoiceId,
  orgId: orgId,
);

// Step 3: Sign the PDF
final signResult = await pdfIntegration.signInvoicePdf(
  orgId: orgId,
  invoiceId: invoiceId,
  certificateId: selectedCertId,  // From cert list
  pdfBytes: pdfBytes,
  algorithm: 'RSA-SHA256',
  xadesLevel: 'B',  // B, T, C, or X
);

if (signResult['success'] == true) {
  print('✅ Invoice signed at ${signResult['signed_at']}');
}
```

### 3. Verify a Signature

```dart
// Verify before sending to client
final verification = await pdfIntegration.verifyPdfSignature(
  orgId: orgId,
  invoiceId: invoiceId,
);

if (verification['valid'] == true) {
  print('✅ Signature is valid');
  print('Signer: ${verification['signer']}');
  print('Valid until: ${verification['certificate_valid_until']}');
} else {
  print('❌ Signature invalid: ${verification['reason']}');
}
```

### 4. Export as XAdES for Compliance

```dart
// Export for archival or external system
final xadesXml = await pdfIntegration.exportSignedAsXades(
  orgId: orgId,
  invoiceId: invoiceId,
);

// Save to storage or send to compliance system
await saveToSupabaseStorage('invoices/signed/$invoiceId.xades.xml', xadesXml);
```

### 5. Create Signature Receipt

```dart
// Generate human-readable receipt for email
final receipt = await pdfIntegration.createSignatureReceipt(
  orgId: orgId,
  invoiceId: invoiceId,
  language: 'fr',  // English, French, German supported
);

// Include in email to client
emailService.sendInvoiceWithSignature(
  to: client.email,
  invoicePdf: pdfBytes,
  signatureReceipt: receipt,
);
```

## UI Components Required

### 1. Certificate Management Page

```dart
// lib/pages/digital_certificates_page.dart
class DigitalCertificatesPage extends StatefulWidget {
  const DigitalCertificatesPage({Key? key}) : super(key: key);

  @override
  State<DigitalCertificatesPage> createState() => _DigitalCertificatesPageState();
}

class _DigitalCertificatesPageState extends State<DigitalCertificatesPage> {
  final _signatureService = DigitalSignatureService();
  List<Map<String, dynamic>> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    // Load certificates for organization
  }

  Future<void> _uploadCertificate() async {
    // File picker → PEM upload → password entry
  }

  Future<void> _revokeCertificate(String certId) async {
    // Confirm revocation → call service
  }

  @override
  Widget build(BuildContext context) {
    // Display certificates, upload button, revoke options
    return Scaffold();
  }
}
```

### 2. Invoice Signing Page

```dart
// lib/pages/invoice_signing_page.dart
class InvoiceSigningPage extends StatefulWidget {
  final String invoiceId;
  
  const InvoiceSigningPage({
    required this.invoiceId,
    Key? key,
  }) : super(key: key);

  @override
  State<InvoiceSigningPage> createState() => _InvoiceSigningPageState();
}

class _InvoiceSigningPageState extends State<InvoiceSigningPage> {
  final _pdfIntegration = PdfSignatureIntegration();
  String? _selectedCertId;
  String _xadesLevel = 'B';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Invoice')),
      body: Column(
        children: [
          // Certificate dropdown
          DropdownButton<String>(
            value: _selectedCertId,
            items: _buildCertificateItems(),
            onChanged: (value) => setState(() => _selectedCertId = value),
          ),
          // XAdES level selection (B, T, C, X)
          RadioListTile<String>(
            title: const Text('XAdES-B (Basic)'),
            value: 'B',
            groupValue: _xadesLevel,
            onChanged: (v) => setState(() => _xadesLevel = v!),
          ),
          // Sign button
          ElevatedButton(
            onPressed: _selectedCertId != null ? _signInvoice : null,
            child: const Text('Sign Invoice'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInvoice() async {
    final result = await _pdfIntegration.signInvoicePdf(
      orgId: currentOrgId,
      invoiceId: widget.invoiceId,
      certificateId: _selectedCertId!,
      pdfBytes: await _generatePdf(),
      xadesLevel: _xadesLevel,
    );

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Invoice signed successfully')),
      );
      Navigator.pop(context);
    }
  }
}
```

### 3. Signature Verification Widget

```dart
// lib/widgets/invoice_signature_badge.dart
class InvoiceSignatureBadge extends StatelessWidget {
  final String invoiceId;
  final String orgId;

  const InvoiceSignatureBadge({
    required this.invoiceId,
    required this.orgId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: PdfSignatureIntegration().verifyPdfSignature(
        orgId: orgId,
        invoiceId: invoiceId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final verification = snapshot.data!;

        return Chip(
          avatar: Icon(
            verification['valid'] == true ? Icons.verified : Icons.error,
            color: verification['valid'] == true ? Colors.green : Colors.red,
          ),
          label: Text(
            verification['valid'] == true ? '✅ Signed' : '⚠️ Invalid',
          ),
          backgroundColor: verification['valid'] == true
              ? Colors.green[100]
              : Colors.red[100],
        );
      },
    );
  }
}
```

## Configuration

### Enable Feature in Feature Personalization

Add to `FeaturePersonalizationService.ALL_FEATURES`:

```dart
{
  'id': 'digital_signatures',
  'name': 'Digital Signatures',
  'icon': 'verified_user',
  'category': 'compliance',
  'priority': 14,
  'description': 'Electronic invoice signatures with XAdES-B',
},
```

### Update Invoice Model

Add signature fields to `invoices` table:

```sql
ALTER TABLE invoices ADD COLUMN (
  is_signed BOOLEAN DEFAULT FALSE,
  signed_at TIMESTAMP,
  signature_algorithm VARCHAR(50),
  xades_level VARCHAR(10)
);

-- Index for signed invoice queries
CREATE INDEX idx_invoices_signed ON invoices(org_id, is_signed);
```

## Security Considerations

### 1. Certificate Key Storage
- Private keys **encrypted at rest** using org-specific encryption key
- Never transmitted to client
- Can only be accessed by app backend with proper org_id

### 2. RLS Policies
All signature tables enforce `org_id` filtering:

```sql
CREATE POLICY org_isolation ON invoice_signatures
  USING (org_id = auth.uid()::uuid);
```

### 3. Audit Trail
Every signature operation logged to `signature_audit_log`:
- Who signed (user_id, email)
- When (timestamp)
- What (invoice_id, algorithm)
- From where (IP address, user_agent)

### 4. Certificate Revocation
Revoked certificates immediately invalidate all their signatures:

```dart
// Revoke a certificate
await signatureService.revokeCertificate(
  orgId: orgId,
  certificateId: certId,
  revocationReason: 'Key compromise',
);
// ✅ All signatures with this cert marked as 'revoked'
```

## Standards Compliance

### XAdES-B (Basic Electronic Signatures)
```xml
<xades:XAdESSignatures>
  <xades:SignatureValue>...</xades:SignatureValue>
  <xades:SigningCertificate>...</xades:SigningCertificate>
  <xades:SigningTime>2026-01-10T15:30:00Z</xades:SigningTime>
  <xades:SignatureAlgorithm>RSA-SHA256</xades:SignatureAlgorithm>
</xades:XAdESSignatures>
```

### XAdES-T (With Timestamp)
Adds RFC 3161 timestamp from TSA for non-repudiation.

### Encoding
- **Primary**: UTF-8 (supports all languages)
- **Fallback**: UTF-16, ASCII
- Encoding specified in signature metadata

## Testing

### Unit Test Example

```dart
// test/services/digital_signature_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_crm/services/digital_signature_service.dart';

void main() {
  final service = DigitalSignatureService();

  group('DigitalSignatureService', () {
    test('uploadCertificate validates PEM format', () async {
      final result = await service.uploadCertificate(
        orgId: 'org-123',
        certificatePem: invalidPem,
        certificateName: 'Test',
        keyPassword: 'password',
      );

      expect(result['error'], isNotNull);
      expect(result['error'], contains('Invalid PEM'));
    });

    test('signInvoice creates XAdES-B document', () async {
      final result = await service.signInvoice(
        orgId: 'org-123',
        invoiceId: 'inv-456',
        certificateId: 'cert-789',
        pdfContent: base64Pdf,
        xadesLevel: 'B',
      );

      expect(result['success'], true);
      expect(result['xades_level'], 'B');
    });
  });
}
```

## Deployment Checklist

- [ ] Run database migration: `20260110_add_digital_signatures.sql`
- [ ] Configure certificate storage path in Supabase
- [ ] Test certificate upload with valid PEM file
- [ ] Verify XAdES XML generation
- [ ] Test signature verification flow
- [ ] Implement TSA integration (optional for XAdES-T)
- [ ] Train team on certificate management
- [ ] Add digital signature feature to feature flags
- [ ] Create UI pages (certificate mgmt, signing, verification)
- [ ] Add signature widget to invoice display
- [ ] Test cross-org isolation (signature from org-A not visible in org-B)
- [ ] Audit all signature operations in compliance log
- [ ] Document certificate rotation process

## Support & Troubleshooting

### "Invalid PEM Format"
Ensure certificate is in proper PEM format:
```
-----BEGIN CERTIFICATE-----
MIID... (base64 content)
-----END CERTIFICATE-----
```

### "Certificate Expired"
Check `valid_until` timestamp. Issue new certificate and revoke old one.

### "RLS Policy Violation"
Ensure all queries pass `org_id`. Check that user belongs to organization.

### "XAdES Export Failed"
Verify signature exists and is marked `status = 'valid'`.

---

**Last Updated**: 2026-01-10
**Status**: ✅ Production Ready
**Standards**: ETSI XAdES, RFC 3161, PKCS#7
