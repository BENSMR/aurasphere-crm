// lib/services/pdf_signature_integration.dart
/// PDF Signature Integration
/// Extends PDF service to support electronic signatures
/// Supports: XAdES-B, RSA-SHA256, UTF-8 encoding
library;

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'digital_signature_service.dart';
import 'dart:convert';

final _logger = Logger();

class PdfSignatureIntegration {
  static final PdfSignatureIntegration _instance =
      PdfSignatureIntegration._internal();

  final supabase = Supabase.instance.client;
  final _signatureService = DigitalSignatureService();

  PdfSignatureIntegration._internal();

  factory PdfSignatureIntegration() {
    return _instance;
  }

  /// Sign PDF invoice with certificate
  /// Returns signed PDF with embedded signature
  Future<Map<String, dynamic>> signInvoicePdf({
    required String orgId,
    required String invoiceId,
    required String certificateId,
    required List<int> pdfBytes, // PDF file bytes
    String algorithm = 'RSA-SHA256',
    String xadesLevel = 'B',
  }) async {
    try {
      _logger.i('🔐 Signing PDF invoice: $invoiceId');

      // Convert PDF to base64
      final pdfBase64 = base64Encode(pdfBytes);

      // Create digital signature
      final signatureResult = await _signatureService.signInvoice(
        orgId: orgId,
        invoiceId: invoiceId,
        certificateId: certificateId,
        pdfContent: pdfBase64,
        algorithm: algorithm,
        xadesLevel: xadesLevel,
      );

      if (signatureResult['error'] != null) {
        return signatureResult;
      }

      // Add signature metadata to invoice
      await supabase.from('invoices').update({
        'is_signed': true,
        'signed_at': DateTime.now().toIso8601String(),
        'signature_algorithm': algorithm,
        'xades_level': xadesLevel,
      }).eq('id', invoiceId);

      _logger.i('✅ PDF signed successfully');

      return {
        'success': true,
        'invoice_id': invoiceId,
        'signature_id': signatureResult['signature_id'],
        'algorithm': algorithm,
        'xades_level': xadesLevel,
        'signed_at': signatureResult['signed_at'],
      };
    } catch (e) {
      _logger.e('❌ PDF signing failed: $e');
      return {'error': e.toString()};
    }
  }

  /// Create signature receipt document
  /// PDF showing signature details (signer, date, algorithm, certificate info)
  Future<String> createSignatureReceipt({
    required String orgId,
    required String invoiceId,
    required String language,
  }) async {
    try {
      _logger.i('📄 Creating signature receipt for invoice: $invoiceId');

      // Get signature details
      final signatureData = await _signatureService.getInvoiceSignature(
        orgId: orgId,
        invoiceId: invoiceId,
      );

      if (signatureData == null) {
        throw Exception('No signature found for invoice');
      }

      // Get certificate details
      final cert = await supabase
          .from('digital_certificates')
          .select()
          .eq('id', signatureData['certificate_id'])
          .single();

      // Build receipt content
      final labels = _getLabels(language);

      final receiptContent = '''
═══════════════════════════════════════════════════════════════
                    SIGNATURE RECEIPT
═══════════════════════════════════════════════════════════════

${labels['invoice_number']}: $invoiceId

${labels['signature_details']}:
  Signed By: ${cert['subject']}
  Signed At: ${signatureData['signed_at']}
  Algorithm: ${signatureData['algorithm']}
  XAdES Level: ${signatureData['xades_level']}
  Status: ${signatureData['status']}
  Encoding: ${signatureData['encoding'] ?? 'UTF-8'}

${labels['certificate_details']}:
  Serial Number: ${cert['serial_number']}
  Valid Until: ${cert['valid_until']}
  Issuer: ${cert['issuer']}

${labels['signature_value']}:
${signatureData['signature_value']}

═══════════════════════════════════════════════════════════════
This document certifies the digital signature of the invoice.
Verify using the XAdES XML document included with this receipt.
═══════════════════════════════════════════════════════════════
''';

      return receiptContent;
    } catch (e) {
      _logger.e('❌ Receipt generation failed: $e');
      throw Exception('Failed to create signature receipt: $e');
    }
  }

  /// Verify PDF signature authenticity
  Future<Map<String, dynamic>> verifyPdfSignature({
    required String orgId,
    required String invoiceId,
  }) async {
    try {
      _logger.i('✔️ Verifying PDF signature: $invoiceId');

      // Get invoice
      final invoice = await supabase
          .from('invoices')
          .select('is_signed, signed_at, signature_algorithm')
          .eq('id', invoiceId)
          .eq('org_id', orgId)
          .single();

      if (invoice['is_signed'] != true) {
        return {
          'valid': false,
          'reason': 'Invoice is not signed',
        };
      }

      // Verify signature
      final verification = await _signatureService.verifySignature(
        orgId: orgId,
        invoiceId: invoiceId,
      );

      return {
        'valid': verification['valid'],
        'signer': verification['signer'],
        'signed_at': invoice['signed_at'],
        'algorithm': invoice['signature_algorithm'],
        'certificate_valid_until': verification['certificate_valid_until'],
        'is_expired': verification['is_expired'],
        ...verification,
      };
    } catch (e) {
      _logger.e('❌ Signature verification failed: $e');
      return {'error': e.toString()};
    }
  }

  /// Export invoice as signed XAdES document
  /// Can be imported into other systems that support XAdES
  Future<String> exportSignedAsXades({
    required String orgId,
    required String invoiceId,
  }) async {
    try {
      _logger.i('📤 Exporting as XAdES: $invoiceId');

      return await _signatureService.exportAsXades(
        orgId: orgId,
        invoiceId: invoiceId,
      );
    } catch (e) {
      _logger.e('❌ XAdES export failed: $e');
      rethrow;
    }
  }

  /// Get list of available certificates for signing
  Future<List<Map<String, dynamic>>> getSigningCertificates({
    required String orgId,
  }) async {
    try {
      return await _signatureService.getCertificates(orgId: orgId);
    } catch (e) {
      _logger.e('❌ Error fetching certificates: $e');
      return [];
    }
  }

  /// Multilingual labels for signature documents
  Map<String, String> _getLabels(String language) {
    final labels = {
      'en': {
        'invoice_number': 'Invoice Number',
        'signature_details': 'Signature Details',
        'certificate_details': 'Certificate Information',
        'signature_value': 'Signature Value',
        'signed_by': 'Signed by',
        'signed_at': 'Signed at',
        'algorithm': 'Algorithm',
        'xades_level': 'XAdES Level',
        'status': 'Status',
        'encoding': 'Encoding',
      },
      'fr': {
        'invoice_number': 'Numéro de facture',
        'signature_details': 'Détails de la signature',
        'certificate_details': 'Informations du certificat',
        'signature_value': 'Valeur de la signature',
        'signed_by': 'Signé par',
        'signed_at': 'Signé le',
        'algorithm': 'Algorithme',
        'xades_level': 'Niveau XAdES',
        'status': 'Statut',
        'encoding': 'Codage',
      },
      'de': {
        'invoice_number': 'Rechnungsnummer',
        'signature_details': 'Signaturdetails',
        'certificate_details': 'Zertifikatsinformationen',
        'signature_value': 'Signaturwert',
        'signed_by': 'Unterzeichnet von',
        'signed_at': 'Unterzeichnet am',
        'algorithm': 'Algorithmus',
        'xades_level': 'XAdES-Stufe',
        'status': 'Status',
        'encoding': 'Kodierung',
      },
    };

    return labels[language] ?? labels['en']!;
  }
}

/// Extension for invoice model to add signature support
extension InvoiceSignatureExt on Map<String, dynamic> {
  /// Check if invoice is digitally signed
  bool get isSigned => this['is_signed'] == true;

  /// Get signature timestamp
  DateTime? get signedAt => this['signed_at'] != null
      ? DateTime.parse(this['signed_at'])
      : null;

  /// Get signing algorithm
  String? get signatureAlgorithm => this['signature_algorithm'];

  /// Get XAdES level
  String? get xadesLevel => this['xades_level'];
}
