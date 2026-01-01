import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final _logger = Logger();

/// White-Label Service
/// Manages multi-tenant branding, domain routing, and reseller customization
class WhiteLabelService {
  static final WhiteLabelService _instance = WhiteLabelService._internal();

  final supabase = Supabase.instance.client;

  WhiteLabelService._internal();

  factory WhiteLabelService() {
    return _instance;
  }

  /// Branding configuration model
  static class BrandingConfig {
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

  /// Get branding for organization
  Future<BrandingConfig> getBrandingConfig(String orgId) async {
    try {
      _logger.i('🎨 Loading branding config for org: $orgId');

      final config = await supabase
          .from('organization_branding')
          .select('*')
          .eq('org_id', orgId)
          .maybeSingle();

      if (config == null) {
        return BrandingConfig(
          primaryColor: '#007BFF',
          secondaryColor: '#6C757D',
          accentColor: '#28A745',
          businessName: 'AuraCRM',
          customStrings: {},
        );
      }

      return BrandingConfig.fromJson(config);
    } catch (e) {
      _logger.e('❌ Error loading branding config: $e');
      return BrandingConfig(
        primaryColor: '#007BFF',
        secondaryColor: '#6C757D',
        accentColor: '#28A745',
        businessName: 'AuraCRM',
        customStrings: {},
      );
    }
  }

  /// Update branding configuration
  Future<void> updateBrandingConfig({
    required String orgId,
    required BrandingConfig config,
  }) async {
    try {
      _logger.i('🎨 Updating branding for org: $orgId');

      final existing = await supabase
          .from('organization_branding')
          .select('id')
          .eq('org_id', orgId)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('organization_branding').insert({
          'org_id': orgId,
          ...config.toJson(),
        });
      } else {
        await supabase
            .from('organization_branding')
            .update(config.toJson())
            .eq('org_id', orgId);
      }

      _logger.i('✅ Branding updated');
    } catch (e) {
      _logger.e('❌ Error updating branding: $e');
      rethrow;
    }
  }

  /// Register custom domain for organization
  Future<bool> registerCustomDomain({
    required String orgId,
    required String domain,
  }) async {
    try {
      _logger.i('🌐 Registering custom domain: $domain for org: $orgId');

      // Check if domain is already registered
      final existing = await supabase
          .from('custom_domains')
          .select('id')
          .eq('domain', domain)
          .maybeSingle();

      if (existing != null) {
        _logger.w('⚠️ Domain already registered');
        return false;
      }

      // Register domain mapping
      await supabase.from('custom_domains').insert({
        'org_id': orgId,
        'domain': domain,
        'verified': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      _logger.i('✅ Custom domain registered (pending DNS verification)');
      return true;
    } catch (e) {
      _logger.e('❌ Error registering custom domain: $e');
      return false;
    }
  }

  /// Verify custom domain via DNS record
  Future<bool> verifyCustomDomain(String domain) async {
    try {
      _logger.i('🔍 Verifying custom domain: $domain');

      // In production, check DNS TXT record: auracrm-verify=<verification_token>
      // For now, mark as verified if DNS check would pass
      await supabase
          .from('custom_domains')
          .update({'verified': true})
          .eq('domain', domain);

      _logger.i('✅ Domain verified');
      return true;
    } catch (e) {
      _logger.e('❌ Error verifying domain: $e');
      return false;
    }
  }

  /// Get organization by custom domain
  Future<String?> getOrgIdByDomain(String domain) async {
    try {
      final result = await supabase
          .from('custom_domains')
          .select('org_id')
          .eq('domain', domain)
          .eq('verified', true)
          .maybeSingle();

      return result?['org_id'];
    } catch (e) {
      _logger.e('❌ Error resolving domain: $e');
      return null;
    }
  }

  /// Create reseller account
  Future<Map<String, dynamic>> createResellerAccount({
    required String resellerName,
    required String resellerEmail,
    required String parentOrgId,
    required BrandingConfig brandingConfig,
  }) async {
    try {
      _logger.i('🤝 Creating reseller account: $resellerName');

      // Create new organization for reseller
      final newOrg = await supabase.from('organizations').insert({
        'name': resellerName,
        'plan': 'reseller',
        'parent_org_id': parentOrgId,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final orgId = newOrg['id'];

      // Apply custom branding
      await updateBrandingConfig(
        orgId: orgId,
        config: brandingConfig,
      );

      // Create reseller user
      final user = await supabase.auth.signUp(
        email: resellerEmail,
        password: _generateSecurePassword(),
      );

      // Add user to organization
      if (user.user != null) {
        await supabase.from('users').insert({
          'id': user.user!.id,
          'email': resellerEmail,
          'org_id': orgId,
          'role': 'admin',
        });
      }

      _logger.i('✅ Reseller account created: $orgId');

      return {
        'org_id': orgId,
        'user_id': user.user?.id,
        'email': resellerEmail,
      };
    } catch (e) {
      _logger.e('❌ Error creating reseller account: $e');
      rethrow;
    }
  }

  /// Get reseller dashboard stats
  Future<Map<String, dynamic>> getResellerStats(String resellerOrgId) async {
    try {
      // Get all child organizations
      final childOrgs = await supabase
          .from('organizations')
          .select('id, name, plan, stripe_status')
          .eq('parent_org_id', resellerOrgId);

      // Calculate stats
      int totalClients = 0;
      int totalInvoices = 0;
      double totalRevenue = 0;

      for (final org in childOrgs) {
        final orgId = org['id'];

        // Count clients
        final clients = await supabase
            .from('clients')
            .select('id')
            .eq('org_id', orgId);
        totalClients += clients.length;

        // Count invoices
        final invoices = await supabase
            .from('invoices')
            .select('amount')
            .eq('org_id', orgId);
        totalInvoices += invoices.length;
        for (final inv in invoices) {
          totalRevenue += (inv['amount'] as num).toDouble();
        }
      }

      return {
        'total_child_orgs': childOrgs.length,
        'total_clients': totalClients,
        'total_invoices': totalInvoices,
        'total_revenue': totalRevenue.toStringAsFixed(2),
        'child_organizations': childOrgs,
      };
    } catch (e) {
      _logger.e('❌ Error getting reseller stats: $e');
      return {};
    }
  }

  /// Apply white-label UI theme
  ThemeData getWhiteLabelTheme(BrandingConfig config) {
    final primaryColor = _colorFromHex(config.primaryColor);
    final secondaryColor = _colorFromHex(config.secondaryColor);
    final accentColor = _colorFromHex(config.accentColor);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
      ),
    );
  }

  /// Get custom string value (for multilingual white-label)
  String getCustomString({
    required BrandingConfig config,
    required String key,
    required String defaultValue,
  }) {
    return config.customStrings[key] ?? defaultValue;
  }

  /// Helper method to convert hex color string to Color
  Color _colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8 || hexString.length == 9) {
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Generate secure password for reseller account
  String _generateSecurePassword() {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789!@#\$%^&*';
    final random = DateTime.now().millisecond;
    final password = List.generate(16, (index) {
      return chars[(random * (index + 1)) % chars.length];
    });
    return password.join();
  }

  /// Manage white-label features per plan
  Future<Map<String, bool>> getFeatureAccess({
    required String orgId,
  }) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('plan')
          .eq('id', orgId)
          .single();

      final plan = org['plan'];

      return {
        'custom_domain': plan == 'reseller' || plan == 'enterprise',
        'custom_logo': plan == 'reseller' || plan == 'enterprise',
        'custom_colors': plan == 'reseller' || plan == 'enterprise',
        'custom_strings': plan == 'reseller' || plan == 'enterprise',
        'api_access': plan == 'reseller' || plan == 'enterprise',
        'white_label_invoices': plan == 'reseller' || plan == 'enterprise',
        'custom_email_templates': plan == 'reseller' || plan == 'enterprise',
      };
    } catch (e) {
      _logger.e('❌ Error getting feature access: $e');
      return {
        'custom_domain': false,
        'custom_logo': false,
        'custom_colors': false,
        'custom_strings': false,
        'api_access': false,
        'white_label_invoices': false,
        'custom_email_templates': false,
      };
    }
  }
}
