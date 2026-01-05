import 'dart:convert' as convert;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Company Profile Service
/// Manages organization details, company registration, tax information,
/// branding, and complete company structure configuration
class CompanyProfileService {
  static final CompanyProfileService _instance =
      CompanyProfileService._internal();

  final supabase = Supabase.instance.client;

  CompanyProfileService._internal();

  factory CompanyProfileService() {
    return _instance;
  }

  /// Get complete company profile
  Future<Map<String, dynamic>> getCompanyProfile(String orgId) async {
    try {
      _logger.i('📋 Fetching company profile for org: $orgId');

      final profile = await supabase
          .from('company_profiles')
          .select('*')
          .eq('org_id', orgId)
          .maybeSingle();

      if (profile == null) {
        _logger.i('ℹ️ No profile found, returning empty template');
        return _getEmptyProfile(orgId);
      }

      _logger.i('✅ Company profile loaded');
      return profile;
    } catch (e) {
      _logger.e('❌ Error fetching company profile: $e');
      return _getEmptyProfile(orgId);
    }
  }

  /// Create/update company profile with all details
  Future<Map<String, dynamic>> updateCompanyProfile({
    required String orgId,
    required String companyName,
    required String companyRegistration,
    required String taxNumber,
    required String businessType,
    required String industry,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    required String phoneNumber,
    required String email,
    required String website,
    required String logoUrl,
    required String primaryColor,
    required String secondaryColor,
    required String accentColor,
  }) async {
    try {
      _logger.i('💾 Updating company profile for: $companyName');

      final data = {
        'org_id': orgId,
        'company_name': companyName,
        'company_registration': companyRegistration,
        'tax_number': taxNumber,
        'business_type': businessType,
        'industry': industry,
        'address': address,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'country': country,
        'phone_number': phoneNumber,
        'email': email,
        'website': website,
        'logo_url': logoUrl,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'accent_color': accentColor,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await supabase
          .from('company_profiles')
          .upsert(data, onConflict: 'org_id')
          .select()
          .single();

      _logger.i('✅ Company profile updated successfully');
      return {'success': true, 'data': result};
    } catch (e) {
      _logger.e('❌ Error updating company profile: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get empty profile template
  Map<String, dynamic> _getEmptyProfile(String orgId) {
    return {
      'org_id': orgId,
      'company_name': '',
      'company_registration': '',
      'tax_number': '',
      'business_type': '', // 'freelancer' or 'trades'
      'industry': '',
      'address': '',
      'city': '',
      'state': '',
      'zip_code': '',
      'country': '',
      'phone_number': '',
      'email': '',
      'website': '',
      'logo_url': null,
      'primary_color': '#007BFF',
      'secondary_color': '#6C757D',
      'accent_color': '#28A745',
      'created_at': null,
      'updated_at': null,
    };
  }

  /// Upload company logo
  Future<Map<String, dynamic>> uploadCompanyLogo({
    required String orgId,
    required String logoBase64,
  }) async {
    try {
      _logger.i('📤 Uploading company logo');

      final fileName = '${orgId}_logo_${DateTime.now().millisecondsSinceEpoch}.png';

      // Upload to storage
      await supabase.storage
          .from('company-logos')
          .uploadBinary(
            fileName,
            convert.base64Decode(logoBase64),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final logoUrl =
          supabase.storage.from('company-logos').getPublicUrl(fileName);

      // Update profile
      await supabase
          .from('company_profiles')
          .update({'logo_url': logoUrl})
          .eq('org_id', orgId);

      _logger.i('✅ Logo uploaded: $logoUrl');
      return {'success': true, 'logo_url': logoUrl};
    } catch (e) {
      _logger.e('❌ Error uploading logo: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get company branding colors
  Future<Map<String, dynamic>> getCompanyBranding(String orgId) async {
    try {
      final profile = await getCompanyProfile(orgId);
      return {
        'primary_color': profile['primary_color'] ?? '#007BFF',
        'secondary_color': profile['secondary_color'] ?? '#6C757D',
        'accent_color': profile['accent_color'] ?? '#28A745',
        'logo_url': profile['logo_url'],
        'company_name': profile['company_name'],
      };
    } catch (e) {
      _logger.e('❌ Error getting branding: $e');
      return {
        'primary_color': '#007BFF',
        'secondary_color': '#6C757D',
        'accent_color': '#28A745',
      };
    }
  }

  /// Validate company registration details
  bool validateCompanyDetails({
    required String companyName,
    required String taxNumber,
    required String email,
  }) {
    if (companyName.isEmpty) {
      _logger.w('⚠️ Company name is empty');
      return false;
    }
    if (taxNumber.isEmpty) {
      _logger.w('⚠️ Tax number is empty');
      return false;
    }
    if (!email.contains('@')) {
      _logger.w('⚠️ Invalid email format');
      return false;
    }
    return true;
  }

  /// Get company statistics
  Future<Map<String, dynamic>> getCompanyStats(String orgId) async {
    try {
      _logger.i('📊 Getting company statistics');

      final profile = await getCompanyProfile(orgId);

      // Get team count
      final teamResult = await supabase
          .from('org_members')
          .select('id')
          .eq('org_id', orgId)
          .count();

      // Get active devices
      final devicesResult = await supabase
          .from('device_management')
          .select('id')
          .eq('org_id', orgId)
          .eq('is_active', true)
          .count();

      return {
        'company_name': profile['company_name'],
        'team_members': teamResult,
        'active_devices': devicesResult,
        'industry': profile['industry'],
        'business_type': profile['business_type'],
        'profile_complete':
            _isProfileComplete(profile) ? 100 : _getProfileCompletion(profile),
      };
    } catch (e) {
      _logger.e('❌ Error getting stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Check if profile is complete
  bool _isProfileComplete(Map<String, dynamic> profile) {
    return profile['company_name']?.isNotEmpty == true &&
        profile['company_registration']?.isNotEmpty == true &&
        profile['tax_number']?.isNotEmpty == true &&
        profile['address']?.isNotEmpty == true &&
        profile['email']?.isNotEmpty == true;
  }

  /// Get profile completion percentage
  int _getProfileCompletion(Map<String, dynamic> profile) {
    int completed = 0;
    int total = 10;

    if (profile['company_name']?.isNotEmpty == true) completed++;
    if (profile['company_registration']?.isNotEmpty == true) completed++;
    if (profile['tax_number']?.isNotEmpty == true) completed++;
    if (profile['business_type']?.isNotEmpty == true) completed++;
    if (profile['address']?.isNotEmpty == true) completed++;
    if (profile['city']?.isNotEmpty == true) completed++;
    if (profile['email']?.isNotEmpty == true) completed++;
    if (profile['phone_number']?.isNotEmpty == true) completed++;
    if (profile['logo_url'] != null) completed++;
    if (profile['website']?.isNotEmpty == true) completed++;

    return ((completed / total) * 100).toInt();
  }

  /// Export company profile as JSON
  Future<String> exportProfile(String orgId) async {
    try {
      final profile = await getCompanyProfile(orgId);
      final jsonString = profile.toString();
      _logger.i('✅ Profile exported');
      return jsonString;
    } catch (e) {
      _logger.e('❌ Error exporting profile: $e');
      return '';
    }
  }
}

// Helper for base64 decoding
List<int> base64Decode(String input) {
  const String base64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final List<int> bytes = [];
  
  for (int i = 0; i < input.length; i += 4) {
    int b1 = base64.indexOf(input[i]);
    int b2 = i + 1 < input.length ? base64.indexOf(input[i + 1]) : 0;
    int b3 = i + 2 < input.length ? base64.indexOf(input[i + 2]) : 0;
    int b4 = i + 3 < input.length ? base64.indexOf(input[i + 3]) : 0;

    bytes.add((b1 << 2) | (b2 >> 4));
    if (b3 > 0) bytes.add((b2 << 4) | (b3 >> 2));
    if (b4 > 0) bytes.add((b3 << 6) | b4);
  }
  return bytes;
}
