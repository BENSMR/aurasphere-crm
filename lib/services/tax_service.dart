// lib/services/tax_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class TaxService {
  // Lazy load Supabase only when needed
  static SupabaseClient get supabase => Supabase.instance.client;

  // VAT rates by country (EU standard rates)
  static const Map<String, double> _vatRates = {
    'AT': 0.20, // Austria
    'BE': 0.21, // Belgium
    'BG': 0.20, // Bulgaria
    'HR': 0.25, // Croatia
    'CY': 0.19, // Cyprus
    'CZ': 0.21, // Czech Republic
    'DK': 0.25, // Denmark
    'EE': 0.20, // Estonia
    'FI': 0.24, // Finland
    'FR': 0.20, // France
    'DE': 0.19, // Germany
    'GR': 0.24, // Greece
    'HU': 0.27, // Hungary
    'IE': 0.23, // Ireland
    'IT': 0.22, // Italy
    'LV': 0.21, // Latvia
    'LT': 0.21, // Lithuania
    'LU': 0.17, // Luxembourg
    'MT': 0.18, // Malta
    'NL': 0.21, // Netherlands
    'PL': 0.23, // Poland
    'PT': 0.23, // Portugal
    'RO': 0.19, // Romania
    'SK': 0.20, // Slovakia
    'SI': 0.22, // Slovenia
    'ES': 0.21, // Spain
    'SE': 0.25, // Sweden
    'GB': 0.20, // United Kingdom (for reference)
    'CH': 0.077, // Switzerland
    'NO': 0.25, // Norway
    'AE': 0.05, // UAE
    'SA': 0.15, // Saudi Arabia
    'QA': 0.00, // Qatar (no VAT)
    'KW': 0.00, // Kuwait (no VAT)
    'BH': 0.12, // Bahrain
    'OM': 0.00, // Oman (no VAT)
    'US': 0.00, // USA (varies by state, default to 0)
  };

  /// Get VAT rate for a country code
  static double getVatRate(String countryCode) {
    return _vatRates[countryCode.toUpperCase()] ?? 0.0;
  }

  /// Calculate tax amount from subtotal and tax rate
  static double calculateTaxAmount(double subtotal, double taxRate) {
    return subtotal * taxRate;
  }

  /// Calculate total from subtotal and tax rate
  static double calculateTotal(double subtotal, double taxRate) {
    final taxAmount = calculateTaxAmount(subtotal, taxRate);
    return subtotal + taxAmount;
  }

  /// Get tax rate for a client based on their country
  static Future<double> getClientTaxRate(String clientId) async {
    try {
      final client = await supabase
          .from('clients')
          .select('country')
          .eq('id', clientId)
          .maybeSingle();

      if (client != null && client['country'] != null) {
        return getVatRate(client['country']);
      }
    } catch (e) {
      _logger.e('Error getting client tax rate: $e');
    }
    return 0.0; // Default to no tax
  }

  /// Get tax rate for organization based on their country
  static Future<double> getOrganizationTaxRate(String orgId) async {
    try {
      // Check if auto_tax is enabled in settings
      final settings = await supabase
          .from('user_preferences')
          .select('features')
          .eq('org_id', orgId)
          .maybeSingle();

      if (settings != null && settings['features'] != null) {
        final features = settings['features'] as Map<String, dynamic>;
        final autoTax = features['auto_tax'] ?? false;

        if (autoTax) {
          // Get organization country
          final org = await supabase
              .from('organizations')
              .select('country')
              .eq('id', orgId)
              .maybeSingle();

          if (org != null && org['country'] != null) {
            return getVatRate(org['country']);
          }
        }
      }
    } catch (e) {
      _logger.e('Error getting organization tax rate: $e');
    }
    return 0.0; // Default to no tax
  }

  /// Calculate invoice totals with tax
  static Map<String, double> calculateInvoiceTotals(
    List<Map<String, dynamic>> items,
    double taxRate,
  ) {
    double subtotal = 0.0;

    for (final item in items) {
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
      subtotal += quantity * unitPrice;
    }

    final taxAmount = calculateTaxAmount(subtotal, taxRate);
    final total = subtotal + taxAmount;

    return {
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
    };
  }

  /// Format currency amount
  static String formatCurrency(double amount, String currency) {
    final currencySymbol = _getCurrencySymbol(currency);
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ';
      case 'SAR':
        return 'ر.س';
      case 'QAR':
        return 'ر.ق';
      case 'KWD':
        return 'د.ك';
      case 'BHD':
        return 'د.ب';
      case 'OMR':
        return 'ر.ع';
      default:
        return currency;
    }
  }
}