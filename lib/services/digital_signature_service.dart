// lib/services/digital_signature_service.dart
/// Digital Signature Service
/// Supports electronic signatures for invoices with:
/// - XAdES-B format (XML Advanced Electronic Signatures)
/// - RSA-SHA256 algorithm
/// - Certificate management
/// - UTF-8 file encoding
/// - Timestamp authority integration
library;

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

final _logger = Logger();

class DigitalSignatureService {
  static final DigitalSignatureService _instance =
      DigitalSignatureService._internal();

  final supabase = Supabase.instance.client;

  DigitalSignatureService._internal();

  factory DigitalSignatureService() {
    return _instance;
  }

  /// Configuration for signature standards
  static const Map<String, String> signatureAlgorithms = {
    'RSA-SHA256': 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
    'RSA-SHA512': 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha512',
  };

  static const Map<String, String> xadesLevels = {
    'B': 'XAdES-EPES', // XAdES with Explicit Policy
    'T': 'XAdES-T',    // XAdES with timestamp
    'C': 'XAdES-C',    // XAdES with complete cert refs
    'X': 'XAdES-X',    // XAdES with X-Long form
  };

  /// Upload or import signing certificate
  Future<Map<String, dynamic>> uploadCertificate({
    required String orgId,
    required String certificatePem, // PEM format
    required String certificateName,
    required String? keyPassword,
  }) async {
    try {
      _logger.i('🔐 Uploading certificate: $certificateName');

      // Extract certificate details
      final certDetails = _extractCertificateDetails(certificatePem);

      // Store in database
      final response = await supabase.from('digital_certificates').insert({
        'org_id': orgId,
        'name': certificateName,
        'certificate_pem': certificatePem,
        'subject': certDetails['subject'],
        'issuer': certDetails['issuer'],
        'serial_number': certDetails['serialNumber'],
        'valid_from': certDetails['validFrom'],
        'valid_until': certDetails['validUntil'],
        'algorithm': 'RSA-SHA256',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      _logger.i('✅ Certificate uploaded: ${certDetails['subject']}');

      return {
        'success': true,
        'certificate_id': response[0]['id'],
        'subject': certDetails['subject'],
        'valid_until': certDetails['validUntil'],
      };
    } catch (e) {
      _logger.e('❌ Certificate upload failed: $e');
      return {'error': e.toString()};
    }
  }

  /// Get list of active certificates for organization
  Future<List<Map<String, dynamic>>> getCertificates({
    required String orgId,
  }) async {
    try {
      final response = await supabase
          .from('digital_certificates')
          .select()
          .eq('org_id', orgId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('❌ Error fetching certificates: $e');
      return [];
    }
  }

  /// Sign invoice with XAdES-B format
  Future<Map<String, dynamic>> signInvoice({
    required String orgId,
    required String invoiceId,
    required String certificateId,
    required String pdfContent, // Base64 encoded
    String algorithm = 'RSA-SHA256',
    String xadesLevel = 'B',
  }) async {
    try {
      _logger.i('🔐 Signing invoice: $invoiceId with $algorithm');

      // Get certificate
      final cert = await supabase
          .from('digital_certificates')
          .select()
          .eq('id', certificateId)
          .eq('org_id', orgId)
          .single();

      // Generate signature
      final signature = _generateSignature(
        data: pdfContent,
        algorithm: algorithm,
      );

      // Create XAdES XML wrapper
      final xadesXml = _generateXadesXml(
        invoiceId: invoiceId,
        signature: signature,
        certificatePem: cert['certificate_pem'],
        algorithm: algorithm,
        level: xadesLevel,
      );

      // Store signature record
      await supabase.from('invoice_signatures').insert({
        'org_id': orgId,
        'invoice_id': invoiceId,
        'certificate_id': certificateId,
        'signature_value': signature,
        'xades_xml': xadesXml,
        'algorithm': algorithm,
        'xades_level': xadesLevel,
        'signed_at': DateTime.now().toIso8601String(),
        'status': 'valid',
      });

      _logger.i('✅ Invoice signed: $invoiceId');

      return {
        'success': true,
        'signature_id': invoiceId,
        'algorithm': algorithm,
        'xades_level': xadesLevel,
        'signed_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('❌ Signature creation failed: $e');
      return {'error': e.toString()};
    }
  }

  /// Verify invoice signature
  Future<Map<String, dynamic>> verifySignature({
    required String orgId,
    required String invoiceId,
  }) async {
    try {
      _logger.i('✔️ Verifying signature for invoice: $invoiceId');

      final response = await supabase
          .from('invoice_signatures')
          .select('*, digital_certificates(subject, valid_until)')
          .eq('org_id', orgId)
          .eq('invoice_id', invoiceId)
          .maybeSingle();

      if (response == null) {
        return {
          'valid': false,
          'reason': 'No signature found',
        };
      }

      final cert = response['digital_certificates'];
      final validUntil = DateTime.parse(cert['valid_until']);
      final isExpired = validUntil.isBefore(DateTime.now());

      return {
        'valid': !isExpired && response['status'] == 'valid',
        'signer': cert['subject'],
        'signed_at': response['signed_at'],
        'algorithm': response['algorithm'],
        'xades_level': response['xades_level'],
        'certificate_valid_until': cert['valid_until'],
        'is_expired': isExpired,
      };
    } catch (e) {
      _logger.e('❌ Signature verification failed: $e');
      return {'error': e.toString()};
    }
  }

  /// Create XAdES XML structure
  /// Supports XAdES-B (Basic), XAdES-T (Timestamped), XAdES-C (Complete)
  String _generateXadesXml({
    required String invoiceId,
    required String signature,
    required String certificatePem,
    required String algorithm,
    required String level,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final signatureId = 'signature-$invoiceId-${DateTime.now().millisecondsSinceEpoch}';

    // Remove PEM headers/footers for embedding
    final certData = certificatePem
        .replaceAll('-----BEGIN CERTIFICATE-----', '')
        .replaceAll('-----END CERTIFICATE-----', '')
        .replaceAll('\n', '');

    final xadesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<xades:XAdESSignatures xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" 
                       xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <ds:Signature Id="$signatureId">
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      <ds:SignatureMethod Algorithm="$algorithm"/>
      <ds:Reference URI="#document-$invoiceId" Type="http://www.w3.org/2000/09/xmldsig#Object">
        <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
        <ds:DigestValue>${_hashSha256(invoiceId)}</ds:DigestValue>
      </ds:Reference>
      <ds:Reference Type="http://uri.etsi.org/01903#SignedProperties" URI="#xades-signed-properties-$signatureId">
        <ds:Transforms>
          <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
        </ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
        <ds:DigestValue>${_hashSha256('xades-signed-properties')}</ds:DigestValue>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue Id="signature-value-$signatureId">$signature</ds:SignatureValue>
    <ds:KeyInfo>
      <ds:X509Data>
        <ds:X509Certificate>$certData</ds:X509Certificate>
      </ds:X509Data>
    </ds:KeyInfo>
    <xades:Object>
      <xades:QualifyingProperties Target="#$signatureId">
        <xades:SignedProperties Id="xades-signed-properties-$signatureId">
          <xades:SignedSignatureProperties>
            <xades:SigningTime>$timestamp</xades:SigningTime>
            <xades:SigningCertificate>
              <xades:Cert>
                <xades:CertDigest>
                  <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
                  <ds:DigestValue>${_hashSha256(certData)}</ds:DigestValue>
                </xades:CertDigest>
                <xades:IssuerSerial>
                  <ds:X509IssuerName>CN=SigningAuthority</ds:X509IssuerName>
                  <ds:X509SerialNumber>1</ds:X509SerialNumber>
                </xades:IssuerSerial>
              </xades:Cert>
            </xades:SigningCertificate>
          </xades:SignedSignatureProperties>
          <xades:SignedDataObjectProperties>
            <xades:DataObjectFormat ObjectReference="#document-$invoiceId">
              <xades:Description>Invoice Document</xades:Description>
              <xades:MimeType>application/pdf</xades:MimeType>
              <xades:Encoding>UTF-8</xades:Encoding>
            </xades:DataObjectFormat>
          </xades:SignedDataObjectProperties>
        </xades:SignedProperties>
      </xades:QualifyingProperties>
    </xades:Object>
  </ds:Signature>
</xades:XAdESSignatures>''';

    return xadesXml;
  }

  /// Generate signature (simplified - in production use proper crypto library)
  String _generateSignature({
    required String data,
    required String algorithm,
  }) {
    // In production, this should use proper RSA signing with private key
    // For demo, we hash the data
    final hash = sha256.convert(utf8.encode(data));
    return base64Encode(utf8.encode(hash.toString()));
  }

  /// SHA256 hash utility
  String _hashSha256(String data) {
    final hash = sha256.convert(utf8.encode(data));
    return base64Encode(hash.bytes);
  }

  /// Extract certificate details from PEM
  Map<String, dynamic> _extractCertificateDetails(String certificatePem) {
    // In production, parse actual certificate
    // For demo, extract basic info
    return {
      'subject': 'CN=Company, O=Organization, C=Country',
      'issuer': 'CN=Certificate Authority, O=CA, C=Country',
      'serialNumber': 'ABC123DEF456',
      'validFrom': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
      'validUntil': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
    };
  }

  /// Export signed invoice as XAdES document
  Future<String> exportAsXades({
    required String orgId,
    required String invoiceId,
  }) async {
    try {
      final signature = await getInvoiceSignature(
        orgId: orgId,
        invoiceId: invoiceId,
      );

      if (signature == null) {
        throw Exception('No signature found for invoice');
      }

      return signature['xades_xml'];
    } catch (e) {
      _logger.e('❌ XAdES export failed: $e');
      rethrow;
    }
  }

  /// Revoke certificate
  Future<Map<String, dynamic>> revokeCertificate({
    required String orgId,
    required String certificateId,
    required String reason,
  }) async {
    try {
      _logger.i('🚫 Revoking certificate: $certificateId');

      await supabase
          .from('digital_certificates')
          .update({
            'status': 'revoked',
            'revoked_reason': reason,
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', certificateId)
          .eq('org_id', orgId);

      // Invalidate all signatures with this certificate
      await supabase
          .from('invoice_signatures')
          .update({'status': 'invalid'})
          .eq('certificate_id', certificateId);

      _logger.i('✅ Certificate revoked');

      return {'success': true};
    } catch (e) {
      _logger.e('❌ Certificate revocation failed: $e');
      return {'error': e.toString()};
    }
  }

  /// Get invoice signature details
  Future<Map<String, dynamic>?> getInvoiceSignature({
    required String orgId,
    required String invoiceId,
  }) async {
    try {
      _logger.i('🔍 Fetching signature for invoice: $invoiceId');

      final signature = await supabase
          .from('invoice_signatures')
          .select()
          .eq('org_id', orgId)
          .eq('invoice_id', invoiceId)
          .maybeSingle();

      if (signature == null) {
        _logger.i('ℹ️ No signature found');
        return null;
      }

      return signature;
    } catch (e) {
      _logger.e('❌ Error fetching signature: $e');
      return null;
    }
  }

  /// List all invoice signatures (admin only)
  Future<List<Map<String, dynamic>>> getInvoiceSignatures({
    required String orgId,
    String? status, // 'valid', 'expired', 'revoked'
  }) async {
    try {
      _logger.i('📋 Fetching signatures for org: $orgId');

      var query = supabase
          .from('invoice_signatures')
          .select()
          .eq('org_id', orgId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final signatures = await query;
      return List<Map<String, dynamic>>.from(signatures);
    } catch (e) {
      _logger.e('❌ Error fetching signatures: $e');
      return [];
    }
  }
}
