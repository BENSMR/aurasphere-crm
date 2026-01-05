import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PrepaymentCodeService {
  final supabase = Supabase.instance.client;

  // Plan pricing
  static const Map<String, double> planPrices = {
    'solo': 9.99,
    'team': 15.00,
    'workshop': 29.00,
  };

  // Restricted regions (African countries without Stripe/Paddle access)
  static const List<String> restrictedRegions = [
    // North Africa
    'TN', // Tunisia
    'EG', // Egypt
    'MA', // Morocco
    'DZ', // Algeria
    'LY', // Libya
    'SD', // Sudan
    'MR', // Mauritania
    
    // West Africa
    'ML', // Mali
    'BF', // Burkina Faso
    'SN', // Senegal
    'CI', // Côte d'Ivoire
    'BJ', // Benin
    'TG', // Togo
    'NE', // Niger
    'GH', // Ghana
    'LR', // Liberia
    'SL', // Sierra Leone
    'GW', // Guinea-Bissau
    'GM', // Gambia
    'CV', // Cape Verde
    'MU', // Mauritius
    
    // Central Africa
    'CM', // Cameroon
    'GA', // Gabon
    'CG', // Congo
    'CD', // Democratic Republic of Congo
    'TD', // Chad
    'CF', // Central African Republic
    'ST', // São Tomé and Príncipe
    'GQ', // Equatorial Guinea
    'AO', // Angola
    
    // East Africa
    'ET', // Ethiopia
    'KE', // Kenya
    'UG', // Uganda
    'TZ', // Tanzania
    'RW', // Rwanda
    'BI', // Burundi
    'SO', // Somalia
    'DJ', // Djibouti
    'ER', // Eritrea
    'SC', // Seychelles
    'KM', // Comoros
    
    // Southern Africa
    'ZM', // Zambia
    'ZW', // Zimbabwe
    'MW', // Malawi
    'MZ', // Mozambique
    'NA', // Namibia
    'BW', // Botswana
    'LS', // Lesotho
    'SZ', // Eswatini
    'ZA', // South Africa
  ];

  /// Region names map for display
  static const Map<String, String> regionNames = {
    // North Africa
    'TN': '🇹🇳 Tunisia',
    'EG': '🇪🇬 Egypt',
    'MA': '🇲🇦 Morocco',
    'DZ': '🇩🇿 Algeria',
    'LY': '🇱🇾 Libya',
    'SD': '🇸🇩 Sudan',
    'MR': '🇲🇷 Mauritania',
    
    // West Africa
    'ML': '🇲🇱 Mali',
    'BF': '🇧🇫 Burkina Faso',
    'SN': '🇸🇳 Senegal',
    'CI': '🇨🇮 Côte d\'Ivoire',
    'BJ': '🇧🇯 Benin',
    'TG': '🇹🇬 Togo',
    'NE': '🇳🇪 Niger',
    'GH': '🇬🇭 Ghana',
    'LR': '🇱🇷 Liberia',
    'SL': '🇸🇱 Sierra Leone',
    'GW': '🇬🇼 Guinea-Bissau',
    'GM': '🇬🇲 Gambia',
    'CV': '🇨🇻 Cape Verde',
    'MU': '🇲🇺 Mauritius',
    
    // Central Africa
    'CM': '🇨🇲 Cameroon',
    'GA': '🇬🇦 Gabon',
    'CG': '🇨🇬 Congo',
    'CD': '🇨🇩 DR Congo',
    'TD': '🇹🇩 Chad',
    'CF': '🇨🇫 Central African Republic',
    'ST': '🇸🇹 São Tomé and Príncipe',
    'GQ': '🇬🇶 Equatorial Guinea',
    'AO': '🇦🇴 Angola',
    
    // East Africa
    'ET': '🇪🇹 Ethiopia',
    'KE': '🇰🇪 Kenya',
    'UG': '🇺🇬 Uganda',
    'TZ': '🇹🇿 Tanzania',
    'RW': '🇷🇼 Rwanda',
    'BI': '🇧🇮 Burundi',
    'SO': '🇸🇴 Somalia',
    'DJ': '🇩🇯 Djibouti',
    'ER': '🇪🇷 Eritrea',
    'SC': '🇸🇨 Seychelles',
    'KM': '🇰🇲 Comoros',
    
    // Southern Africa
    'ZM': '🇿🇲 Zambia',
    'ZW': '🇿🇼 Zimbabwe',
    'MW': '🇲🇼 Malawi',
    'MZ': '🇲🇿 Mozambique',
    'NA': '🇳🇦 Namibia',
    'BW': '🇧🇼 Botswana',
    'LS': '🇱🇸 Lesotho',
    'SZ': '🇸🇿 Eswatini',
    'ZA': '🇿🇦 South Africa',
  };

  /// Region groupings for UI organization
  static const Map<String, List<String>> regionsByContinent = {
    'North Africa': ['TN', 'EG', 'MA', 'DZ', 'LY', 'SD', 'MR'],
    'West Africa': ['ML', 'BF', 'SN', 'CI', 'BJ', 'TG', 'NE', 'GH', 'LR', 'SL', 'GW', 'GM', 'CV', 'MU'],
    'Central Africa': ['CM', 'GA', 'CG', 'CD', 'TD', 'CF', 'ST', 'GQ', 'AO'],
    'East Africa': ['ET', 'KE', 'UG', 'TZ', 'RW', 'BI', 'SO', 'DJ', 'ER', 'SC', 'KM'],
    'Southern Africa': ['ZM', 'ZW', 'MW', 'MZ', 'NA', 'BW', 'LS', 'SZ', 'ZA'],
  };

  /// Subscription duration options (in months)
  static const Map<String, int> subscriptionDurations = {
    '1month': 1,
    '3months': 3,
    '6months': 6,
    '12months': 12,
  };

  /// Display names for durations
  static const Map<String, String> durationDisplayNames = {
    '1month': '1 Month',
    '3months': '3 Months',
    '6months': '6 Months',
    '12months': '1 Year',
  };

  /// Generate batch of prepayment codes for admin
  Future<List<String>> generateCodes({
    required String planId, // solo, team, workshop
    required int quantity,
    required String region, // TN, EG, MA
    required String duration, // 1month, 3months, 6months, 12months
    int? expiryDays = 365,
    required String generatedBy, // admin user_id
  }) async {
    try {
      if (!subscriptionDurations.containsKey(duration)) {
        throw Exception('Invalid duration: $duration');
      }

      List<String> generatedCodes = [];
      final codeExpiryDate = DateTime.now().add(Duration(days: expiryDays ?? 365));

      for (int i = 0; i < quantity; i++) {
        final code = _generateUniqueCode(region, planId, duration);

        await supabase.from('prepayment_codes').insert({
          'code': code,
          'plan_id': planId,
          'region': region,
          'subscription_duration': subscriptionDurations[duration], // months
          'status': 'active', // active, redeemed, expired
          'created_by': generatedBy,
          'created_at': DateTime.now().toIso8601String(),
          'valid_until': codeExpiryDate.toIso8601String(),
          'redeemed_by': null,
          'redeemed_at': null,
          'subscription_active_until': null, // Set on redemption
        });

        generatedCodes.add(code);
      }

      print('✅ Generated ${generatedCodes.length} codes for $planId ($duration) in $region');
      return generatedCodes;
    } catch (e) {
      print('❌ Error generating codes: $e');
      throw Exception('Failed to generate codes: $e');
    }
  }

  /// Validate and redeem code
  Future<Map<String, dynamic>> redeemCode({
    required String code,
    required String userId,
  }) async {
    try {
      // Fetch code
      final response = await supabase
          .from('prepayment_codes')
          .select()
          .eq('code', code.toUpperCase())
          .single();

      final codeData = response;

      // Validate status
      if (codeData['status'] == 'redeemed') {
        throw Exception('Code has already been redeemed');
      }
      if (codeData['status'] == 'expired') {
        throw Exception('Code has expired');
      }
      if (codeData['status'] != 'active') {
        throw Exception('Invalid code status');
      }

      // Check expiry
      final expiryDate = DateTime.parse(codeData['valid_until'] as String);
      if (DateTime.now().isAfter(expiryDate)) {
        // Mark as expired
        await supabase
            .from('prepayment_codes')
            .update({'status': 'expired'})
            .eq('id', codeData['id']);
        throw Exception('Code has expired');
      }

      // Calculate subscription end date
      final durationMonths = codeData['subscription_duration'] as int? ?? 1;
      final subscriptionActiveUntil =
          DateTime.now().add(Duration(days: durationMonths * 30));

      // Mark code as redeemed
      await supabase
          .from('prepayment_codes')
          .update({
            'status': 'redeemed',
            'redeemed_by': userId,
            'redeemed_at': DateTime.now().toIso8601String(),
            'subscription_active_until': subscriptionActiveUntil.toIso8601String(),
          })
          .eq('id', codeData['id']);

      // Update user subscription
      await supabase.from('users').update({
        'prepayment_code_id': codeData['id'],
        'activation_method': 'prepayment_code',
        'subscription_plan': codeData['plan_id'],
        'subscription_active_until': subscriptionActiveUntil.toIso8601String(),
      }).eq('id', userId);

      // Log to audit
      await supabase.from('prepayment_code_audit').insert({
        'code_id': codeData['id'],
        'action': 'redeemed',
        'performed_by': userId,
        'performed_at': DateTime.now().toIso8601String(),
        'details': {
          'plan': codeData['plan_id'],
          'region': codeData['region'],
          'duration_months': durationMonths,
          'active_until': subscriptionActiveUntil.toIso8601String(),
        }
      });

      return {
        'success': true,
        'planId': codeData['plan_id'],
        'region': codeData['region'],
        'price': planPrices[codeData['plan_id']] ?? 0.0,
        'duration': durationMonths,
        'activeUntil': subscriptionActiveUntil.toIso8601String(),
        'message': 'Code redeemed successfully! Plan activated for $durationMonths month(s).',
      };
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Invalid code');
      }
      throw Exception('Error validating code: ${e.message}');
    } catch (e) {
      throw Exception('Error redeeming code: $e');
    }
  }

  /// Check if code is valid (without redeeming)
  Future<Map<String, dynamic>> validateCode(String code) async {
    try {
      final response = await supabase
          .from('prepayment_codes')
          .select()
          .eq('code', code.toUpperCase())
          .single();

      final codeData = response;

      // Check status
      if (codeData['status'] == 'redeemed') {
        return {
          'valid': false,
          'error': 'Code already redeemed',
          'data': null,
        };
      }

      // Check expiry
      final expiryDate = DateTime.parse(codeData['valid_until'] as String);
      if (DateTime.now().isAfter(expiryDate)) {
        return {
          'valid': false,
          'error': 'Code expired',
          'data': null,
        };
      }

      final durationMonths = codeData['subscription_duration'] as int? ?? 1;
      final durationName = durationDisplayNames[
              _getDurationKey(durationMonths)] ??
          '$durationMonths Month(s)';

      return {
        'valid': true,
        'error': null,
        'data': {
          'id': codeData['id'],
          'plan_id': codeData['plan_id'],
          'region': codeData['region'],
          'price': planPrices[codeData['plan_id']] ?? 0.0,
          'subscription_duration': durationMonths,
          'duration_name': durationName,
          'expiresOn': codeData['valid_until'],
          'status': codeData['status'],
        }
      };
    } catch (e) {
      return {
        'valid': false,
        'error': 'Invalid code',
        'data': null,
      };
    }
  }

  /// Get code usage stats (admin only)
  Future<Map<String, dynamic>> getCodeStats(String adminUserId) async {
    try {
      // Verify admin status
      final adminCheck = await supabase
          .from('users')
          .select('role')
          .eq('id', adminUserId)
          .single();

      if (adminCheck['role'] != 'admin') {
        throw Exception('Unauthorized: Admin access required');
      }

      // Get stats
      final response = await supabase.from('prepayment_codes').select();
      final allCodes = response as List;

      final stats = {
        'total': allCodes.length,
        'active': allCodes.where((c) => c['status'] == 'active').length,
        'redeemed': allCodes.where((c) => c['status'] == 'redeemed').length,
        'expired': allCodes.where((c) => c['status'] == 'expired').length,
        'byPlan': {
          'solo': allCodes.where((c) => c['plan_id'] == 'solo').length,
          'team': allCodes.where((c) => c['plan_id'] == 'team').length,
          'workshop': allCodes.where((c) => c['plan_id'] == 'workshop').length,
        },
        'byRegion': {
          'TN': allCodes.where((c) => c['region'] == 'TN').length,
          'EG': allCodes.where((c) => c['region'] == 'EG').length,
          'MA': allCodes.where((c) => c['region'] == 'MA').length,
        },
        'byDuration': {
          '1month': allCodes.where((c) => c['subscription_duration'] == 1).length,
          '3months':
              allCodes.where((c) => c['subscription_duration'] == 3).length,
          '6months':
              allCodes.where((c) => c['subscription_duration'] == 6).length,
          '12months':
              allCodes.where((c) => c['subscription_duration'] == 12).length,
        },
      };

      return stats;
    } catch (e) {
      throw Exception('Error fetching code stats: $e');
    }
  }

  /// Check if user's region requires prepayment code
  static bool isRestrictedRegion(String? countryCode) {
    return countryCode != null &&
        restrictedRegions.contains(countryCode.toUpperCase());
  }

  /// Helper to get duration key from months
  String _getDurationKey(int months) {
    switch (months) {
      case 1:
        return '1month';
      case 3:
        return '3months';
      case 6:
        return '6months';
      case 12:
        return '12months';
      default:
        return '1month';
    }
  }

  /// Generate unique code format: AURA-TUN-2024-1M-ABC123
  String _generateUniqueCode(String region, String planId, String duration) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = md5
        .convert(utf8.encode(timestamp + planId + region + duration))
        .toString()
        .substring(0, 6)
        .toUpperCase();
    final year = DateTime.now().year;
    final durationSuffix = _getDurationSuffix(duration);

    return 'AURA-$region-$year-$durationSuffix-$randomPart';
  }

  /// Get duration suffix (1M, 3M, 6M, 1Y)
  String _getDurationSuffix(String duration) {
    switch (duration) {
      case '1month':
        return '1M';
      case '3months':
        return '3M';
      case '6months':
        return '6M';
      case '12months':
        return '1Y';
      default:
        return '1M';
    }
  }

  /// Export codes as CSV (admin)
  String exportCodesToCSV(List<Map<String, dynamic>> codes) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Code,Plan,Region,Duration(Months),Status,ValidUntil,RedeemedBy,RedeemedAt');

    for (final code in codes) {
      buffer.writeln(
        '${code['code']},${code['plan_id']},${code['region']},${code['subscription_duration']},${code['status']},${code['valid_until']},${code['redeemed_by'] ?? ''},${code['redeemed_at'] ?? ''}',
      );
    }

    return buffer.toString();
  }
}
