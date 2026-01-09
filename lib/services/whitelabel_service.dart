import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

/// Branding configuration model
class BrandingConfig {
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String? logoUrl;
  final String? faviconUrl;
  final String businessName;
  final String? customDomain;
  final Map<String, String> customStrings;

  BrandingConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.logoUrl,
    this.faviconUrl,
    required this.businessName,
    this.customDomain,
    required this.customStrings,
  });

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    return BrandingConfig(
      primaryColor: json['primary_color'] ?? '#007BFF',
      secondaryColor: json['secondary_color'] ?? '#6C757D',
      accentColor: json['accent_color'] ?? '#28A745',
      logoUrl: json['logo_url'],
      faviconUrl: json['favicon_url'],
      businessName: json['business_name'] ?? 'AuraCRM',
      customDomain: json['custom_domain'],
      customStrings: Map<String, String>.from(json['custom_strings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
    'accent_color': accentColor,
    'logo_url': logoUrl,
    'favicon_url': faviconUrl,
    'business_name': businessName,
    'custom_domain': customDomain,
    'custom_strings': customStrings,
  };
}

/// White-Label Service
/// Manages multi-tenant branding, domain routing, and reseller customization
class WhiteLabelService {
  static final WhiteLabelService _instance = WhiteLabelService._internal();
  final supabase = Supabase.instance.client;

  WhiteLabelService._internal();

  factory WhiteLabelService() {
    return _instance;
  }

  /// Get branding for organization from database
  Future<BrandingConfig> getBrandingConfig(String orgId) async {
    try {
      _logger.i('🎨 Fetching branding config for org: $orgId');
      
      final result = await supabase
          .from('white_label_settings')
          .select()
          .eq('org_id', orgId)
          .maybeSingle();

      if (result != null) {
        _logger.i('✅ Custom branding loaded');
        return BrandingConfig.fromJson(result);
      }

      // Return default branding if no custom config
      _logger.i('ℹ️ No custom branding found, using defaults');
      return BrandingConfig(
        primaryColor: '#007BFF',
        secondaryColor: '#6C757D',
        accentColor: '#28A745',
        businessName: 'AuraCRM',
        customStrings: {},
      );
    } catch (e) {
      _logger.e('❌ Error fetching branding: $e');
      return BrandingConfig(
        primaryColor: '#007BFF',
        secondaryColor: '#6C757D',
        accentColor: '#28A745',
        businessName: 'AuraCRM',
        customStrings: {},
      );
    }
  }

  /// Update branding configuration in database
  Future<void> updateBrandingConfig({
    required String orgId,
    required BrandingConfig config,
  }) async {
    try {
      _logger.i('🎨 Updating branding for org: $orgId');
      
      await supabase.from('white_label_settings').upsert({
        'org_id': orgId,
        'primary_color': config.primaryColor,
        'secondary_color': config.secondaryColor,
        'accent_color': config.accentColor,
        'logo_url': config.logoUrl,
        'favicon_url': config.faviconUrl,
        'business_name': config.businessName,
        'custom_domain': config.customDomain,
        'custom_strings': config.customStrings,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'org_id');
      
      _logger.i('✅ Branding updated');
    } catch (e) {
      _logger.e('❌ Error updating branding: $e');
      rethrow;
    }
  }

  /// Get white-label theme based on branding config
  ThemeData getWhiteLabelTheme(BrandingConfig config) {
    return ThemeData(
      primaryColor: Color(int.parse('0xff${config.primaryColor.replaceFirst('#', '')}')),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(int.parse('0xff${config.primaryColor.replaceFirst('#', '')}')),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }

  /// Register custom domain
  Future<bool> registerCustomDomain({
    required String orgId,
    required String domain,
    required BrandingConfig config,
  }) async {
    try {
      _logger.i('🌐 Registering custom domain: $domain for org: $orgId');
      
      // Call Edge Function to validate and setup domain DNS
      final response = await supabase.functions.invoke(
        'register-custom-domain',
        body: {
          'org_id': orgId,
          'domain': domain,
          'branding': config.toJson(),
        },
      ) as Map<String, dynamic>;

      if (response['success'] == true) {
        // Update branding config with custom domain
        config = BrandingConfig(
          primaryColor: config.primaryColor,
          secondaryColor: config.secondaryColor,
          accentColor: config.accentColor,
          logoUrl: config.logoUrl,
          faviconUrl: config.faviconUrl,
          businessName: config.businessName,
          customDomain: domain,
          customStrings: config.customStrings,
        );
        await updateBrandingConfig(orgId: orgId, config: config);
        
        _logger.i('✅ Custom domain registered');
        return true;
      }
      
      _logger.w('⚠️ Domain registration failed: ${response['error'] ?? 'Unknown error'}');
      return false;
    } catch (e) {
      _logger.e('❌ Error registering domain: $e');
      return false;
    }
  }

  /// Setup email for custom domain (configure email routing)
  Future<bool> setupCustomEmail({
    required String orgId,
    required String domain,
    required String emailPrefix,
  }) async {
    try {
      _logger.i('📧 Setting up custom email: $emailPrefix@$domain');
      
      final response = await supabase.functions.invoke(
        'setup-custom-email',
        body: {
          'org_id': orgId,
          'domain': domain,
          'email_prefix': emailPrefix,
        },
      ) as Map<String, dynamic>;

      if (response['success'] == true) {
        _logger.i('✅ Custom email configured');
        return true;
      }
      
      _logger.w('⚠️ Email setup failed: ${response['error'] ?? 'Unknown error'}');
      return false;
    } catch (e) {
      _logger.e('❌ Error setting up email: $e');
      return false;
    }
  }

  /// Get tenant insights (usage, customization stats)
  Future<Map<String, dynamic>> getTenantInsights(String orgId) async {
    try {
      _logger.i('📊 Fetching tenant insights for org: $orgId');
      
      final config = await getBrandingConfig(orgId);
      
      final invoices = await supabase
          .from('invoices')
          .select('id')
          .eq('org_id', orgId);
      
      final jobs = await supabase
          .from('jobs')
          .select('id')
          .eq('org_id', orgId);
      
      final teamMembers = await supabase
          .from('org_members')
          .select('id')
          .eq('org_id', orgId);

      return {
        'org_id': orgId,
        'business_name': config.businessName,
        'custom_domain': config.customDomain,
        'total_invoices': invoices.length,
        'total_jobs': jobs.length,
        'team_size': teamMembers.length,
        'branding_customized': config.customDomain != null || config.logoUrl != null,
      };
    } catch (e) {
      _logger.e('❌ Error getting insights: $e');
      return {};
    }
  }

  /// Get all tenant brands (admin panel)
  Future<List<Map<String, dynamic>>> getAllTenantBrands() async {
    try {
      _logger.i('📋 Fetching all tenant branding configs');
      
      final results = await supabase.from('white_label_settings').select();
      
      _logger.i('✅ Fetched ${results.length} tenant brands');
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      _logger.e('❌ Error fetching tenant brands: $e');
      return [];
    }
  }
}
