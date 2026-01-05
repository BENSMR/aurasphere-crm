import 'dart:convert' as convert;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// White-Label & Personalization Service
/// Allows organizations to customize branding across the platform:
/// - Upload custom logo
/// - Set custom brand colors
/// - Add watermark to documents/invoices
/// - Customize UI appearance
class WhiteLabelService {
  static final WhiteLabelService _instance = WhiteLabelService._internal();
  
  final supabase = Supabase.instance.client;

  WhiteLabelService._internal();

  factory WhiteLabelService() {
    return _instance;
  }

  /// Get white-label settings for an organization
  Future<Map<String, dynamic>> getWhiteLabelSettings(String orgId) async {
    try {
      _logger.i('📋 Fetching white-label settings for org: $orgId');

      final settings = await supabase
          .from('white_label_settings')
          .select('*')
          .eq('org_id', orgId)
          .maybeSingle();

      if (settings == null) {
        _logger.i('ℹ️ No white-label settings found, using defaults');
        return _getDefaultSettings();
      }

      _logger.i('✅ White-label settings loaded');
      return settings;
    } catch (e) {
      _logger.e('❌ Error fetching white-label settings: $e');
      return _getDefaultSettings();
    }
  }

  /// Get default white-label settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'org_id': '',
      'logo_url': null,
      'primary_color': '#007BFF', // Electric Blue
      'secondary_color': '#6C757D', // Gray
      'accent_color': '#28A745', // Green
      'watermark_enabled': false,
      'watermark_text': 'AuraSphere CRM',
      'watermark_opacity': 0.1,
      'company_name': 'AuraSphere CRM',
      'support_email': 'support@aurasphere.com',
      'website_url': 'https://aurasphere.com',
      'custom_domain': null,
      'hide_branding': false,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Upload custom logo
  Future<Map<String, dynamic>> uploadLogo({
    required String orgId,
    required String logoBase64,
  }) async {
    try {
      _logger.i('📤 Uploading custom logo for org: $orgId');

      // Upload to Supabase storage
      final fileName = '${orgId}_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      
      await supabase.storage
          .from('org-logos')
          .uploadBinary(
            fileName,
            convert.base64Decode(logoBase64),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final logoUrl = supabase.storage
          .from('org-logos')
          .getPublicUrl(fileName);

      // Update settings
      await supabase
          .from('white_label_settings')
          .upsert({
            'org_id': orgId,
            'logo_url': logoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'org_id');

      _logger.i('✅ Logo uploaded successfully: $logoUrl');

      return {
        'success': true,
        'logo_url': logoUrl,
        'file_name': fileName,
      };
    } catch (e) {
      _logger.e('❌ Error uploading logo: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update brand colors
  Future<Map<String, dynamic>> updateBrandColors({
    required String orgId,
    required String primaryColor,
    required String secondaryColor,
    required String accentColor,
  }) async {
    try {
      _logger.i('🎨 Updating brand colors for org: $orgId');

      // Validate hex color format
      if (!_isValidHexColor(primaryColor) ||
          !_isValidHexColor(secondaryColor) ||
          !_isValidHexColor(accentColor)) {
        return {'success': false, 'error': 'Invalid hex color format'};
      }

      await supabase
          .from('white_label_settings')
          .upsert({
            'org_id': orgId,
            'primary_color': primaryColor,
            'secondary_color': secondaryColor,
            'accent_color': accentColor,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'org_id');

      _logger.i('✅ Brand colors updated');

      return {
        'success': true,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'accent_color': accentColor,
      };
    } catch (e) {
      _logger.e('❌ Error updating brand colors: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update watermark settings
  Future<Map<String, dynamic>> updateWatermark({
    required String orgId,
    required bool enabled,
    required String watermarkText,
    required double opacity,
  }) async {
    try {
      _logger.i('💧 Updating watermark for org: $orgId');

      if (opacity < 0 || opacity > 1) {
        return {'success': false, 'error': 'Opacity must be between 0 and 1'};
      }

      await supabase
          .from('white_label_settings')
          .upsert({
            'org_id': orgId,
            'watermark_enabled': enabled,
            'watermark_text': watermarkText,
            'watermark_opacity': opacity,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'org_id');

      _logger.i('✅ Watermark settings updated');

      return {
        'success': true,
        'watermark_enabled': enabled,
        'watermark_text': watermarkText,
        'watermark_opacity': opacity,
      };
    } catch (e) {
      _logger.e('❌ Error updating watermark: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update company information
  Future<Map<String, dynamic>> updateCompanyInfo({
    required String orgId,
    required String companyName,
    required String supportEmail,
    required String websiteUrl,
  }) async {
    try {
      _logger.i('🏢 Updating company info for org: $orgId');

      await supabase
          .from('white_label_settings')
          .upsert({
            'org_id': orgId,
            'company_name': companyName,
            'support_email': supportEmail,
            'website_url': websiteUrl,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'org_id');

      _logger.i('✅ Company info updated');

      return {
        'success': true,
        'company_name': companyName,
        'support_email': supportEmail,
        'website_url': websiteUrl,
      };
    } catch (e) {
      _logger.e('❌ Error updating company info: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Enable/disable branding
  Future<Map<String, dynamic>> setHideBranding({
    required String orgId,
    required bool hide,
  }) async {
    try {
      _logger.i('${hide ? '🚫' : '✅'} Setting hide branding: $hide');

      await supabase
          .from('white_label_settings')
          .upsert({
            'org_id': orgId,
            'hide_branding': hide,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'org_id');

      _logger.i('✅ Branding visibility updated');

      return {
        'success': true,
        'hide_branding': hide,
      };
    } catch (e) {
      _logger.e('❌ Error updating branding: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reset to default white-label settings
  Future<Map<String, dynamic>> resetToDefaults(String orgId) async {
    try {
      _logger.i('🔄 Resetting white-label settings to defaults');

      final defaults = _getDefaultSettings();
      defaults['org_id'] = orgId;

      await supabase
          .from('white_label_settings')
          .upsert(defaults, onConflict: 'org_id');

      _logger.i('✅ Settings reset to defaults');

      return {'success': true};
    } catch (e) {
      _logger.e('❌ Error resetting settings: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get white-label settings for UI theme application
  Future<Map<String, dynamic>> getThemeColors(String orgId) async {
    try {
      final settings = await getWhiteLabelSettings(orgId);

      return {
        'primaryColor': settings['primary_color'] ?? '#007BFF',
        'secondaryColor': settings['secondary_color'] ?? '#6C757D',
        'accentColor': settings['accent_color'] ?? '#28A745',
        'logoUrl': settings['logo_url'],
        'companyName': settings['company_name'] ?? 'AuraSphere CRM',
      };
    } catch (e) {
      _logger.e('❌ Error getting theme colors: $e');
      return {
        'primaryColor': '#007BFF',
        'secondaryColor': '#6C757D',
        'accentColor': '#28A745',
      };
    }
  }

  /// Helper: Validate hex color format
  bool _isValidHexColor(String color) {
    if (!color.startsWith('#') || color.length != 7) {
      return false;
    }
    
    try {
      int.parse(color.substring(1), radix: 16);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get statistics on white-label usage
  Future<Map<String, dynamic>> getWhiteLabelStats({
    required String orgId,
  }) async {
    try {
      _logger.i('📊 Getting white-label stats');

      final settings = await getWhiteLabelSettings(orgId);

      return {
        'org_id': orgId,
        'has_custom_logo': settings['logo_url'] != null,
        'has_custom_colors': true, // Always true if settings exist
        'watermark_enabled': settings['watermark_enabled'] ?? false,
        'branding_hidden': settings['hide_branding'] ?? false,
        'custom_domain': settings['custom_domain'],
        'last_updated': settings['updated_at'],
      };
    } catch (e) {
      _logger.e('❌ Error getting white-label stats: $e');
      return {'error': e.toString()};
    }
  }
}

// Helper extension to decode base64
extension Base64Decode on String {
  List<int> base64Decode() {
    // Using dart:convert for base64 decoding
    final bytes = <int>[];
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    
    var i = 0;
    while (i < length) {
      final b1 = chars.indexOf(this[i++]);
      final b2 = i < length ? chars.indexOf(this[i++]) : 0;
      final b3 = i < length ? chars.indexOf(this[i++]) : 0;
      final b4 = i < length ? chars.indexOf(this[i++]) : 0;

      bytes.add((b1 << 2) | (b2 >> 4));
      if (b3 > 0 || i < length) bytes.add((b2 << 4) | (b3 >> 2));
      if (b4 > 0 || i < length) bytes.add((b3 << 6) | b4);
    }
    return bytes;
  }
}
