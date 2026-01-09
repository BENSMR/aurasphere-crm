import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

/// Rate Limiting Service
/// Prevents abuse by limiting login attempts, API requests, and user actions
class RateLimitService {
  static final RateLimitService _instance = RateLimitService._internal();
  final supabase = Supabase.instance.client;
  
  // Configuration
  static const int MAX_LOGIN_ATTEMPTS = 5;
  static const Duration LOGIN_ATTEMPT_WINDOW = Duration(minutes: 15);
  static const int MAX_API_REQUESTS = 100;
  static const Duration API_REQUEST_WINDOW = Duration(minutes: 1);

  factory RateLimitService() => _instance;

  RateLimitService._internal();

  /// Record a login attempt and check if user is locked out
  Future<void> recordAttempt({
    required String userEmail,
    required String ipAddress,
    required bool success,
  }) async {
    try {
      _logger.i('📝 Recording login attempt for $userEmail from $ipAddress');
      
      await supabase.from('rate_limit_log').insert({
        'email': userEmail,
        'ip_address': ipAddress,
        'action': 'login',
        'success': success,
        'created_at': DateTime.now().toIso8601String(),
      });

      // If failed, check if should be locked
      if (!success) {
        final recentFailures = await supabase
            .from('rate_limit_log')
            .select('id')
            .eq('email', userEmail)
            .eq('action', 'login')
            .eq('success', false)
            .gt('created_at', DateTime.now().subtract(LOGIN_ATTEMPT_WINDOW).toIso8601String())
            .limit(1);

        final failureCount = recentFailures.length;

        if (failureCount >= MAX_LOGIN_ATTEMPTS) {
          _logger.w('⚠️ Too many login failures for $userEmail, locking account');
          
          await supabase
              .from('users')
              .update({'locked_until': DateTime.now().add(const Duration(minutes: 30)).toIso8601String()})
              .eq('email', userEmail);
        }
      }
      
      _logger.i('✅ Attempt recorded');
    } catch (e) {
      _logger.e('❌ Error recording attempt: $e');
    }
  }

  /// Get remaining login attempts for a user
  Future<int> getRemainingAttempts({
    required String userEmail,
  }) async {
    try {
      _logger.i('🔍 Checking remaining attempts for $userEmail');
      
      final result = await supabase
          .from('rate_limit_log')
          .select('id')
          .eq('email', userEmail)
          .eq('action', 'login')
          .eq('success', false)
          .gt('created_at', DateTime.now().subtract(LOGIN_ATTEMPT_WINDOW).toIso8601String());

      final failureCount = result.length;
      final remaining = MAX_LOGIN_ATTEMPTS - failureCount;
      _logger.i('✅ Remaining attempts: $remaining');
      
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      _logger.e('❌ Error checking attempts: $e');
      return MAX_LOGIN_ATTEMPTS; // Return max on error (fail open)
    }
  }

  /// Check if user/IP is allowed to make a request
  Future<bool> isAllowed({
    required String userEmail,
    required String ipAddress,
  }) async {
    try {
      // Check if user is locked out
      final userResult = await supabase
          .from('users')
          .select('locked_until')
          .eq('email', userEmail)
          .maybeSingle();

      if (userResult != null && userResult['locked_until'] != null) {
        final lockedUntil = DateTime.parse(userResult['locked_until']);
        if (DateTime.now().isBefore(lockedUntil)) {
          _logger.w('⚠️ User $userEmail is locked until ${lockedUntil.toString()}');
          return false;
        } else {
          // Unlock user
          await supabase
              .from('users')
              .update({'locked_until': null})
              .eq('email', userEmail);
        }
      }

      // Check API request rate limit
      final recentRequests = await supabase
          .from('rate_limit_log')
          .select('id')
          .eq('email', userEmail)
          .eq('action', 'api_request')
          .gt('created_at', DateTime.now().subtract(API_REQUEST_WINDOW).toIso8601String())
          .limit(1);

      final requestCount = recentRequests.length;

      if (requestCount >= MAX_API_REQUESTS) {
        _logger.w('⚠️ Rate limit exceeded for $userEmail');
        return false;
      }

      // Record this API request
      await supabase.from('rate_limit_log').insert({
        'email': userEmail,
        'ip_address': ipAddress,
        'action': 'api_request',
        'success': true,
        'created_at': DateTime.now().toIso8601String(),
      }).then((_) {
        _logger.i('✅ Request allowed for $userEmail');
      });

      return true;
    } catch (e) {
      _logger.e('❌ Error checking rate limit: $e');
      return true; // Fail open - allow request on error
    }
  }

  /// Clear rate limit records for a user
  Future<void> clearAttempts({
    required String userEmail,
  }) async {
    try {
      _logger.i('🔄 Clearing rate limit records for $userEmail');
      
      await supabase
          .from('rate_limit_log')
          .delete()
          .eq('email', userEmail);

      // Unlock user if locked
      await supabase
          .from('users')
          .update({'locked_until': null})
          .eq('email', userEmail);

      _logger.i('✅ Rate limit records cleared');
    } catch (e) {
      _logger.e('❌ Error clearing attempts: $e');
    }
  }

  /// Get IP address reputation (simple check)
  Future<bool> isIpSuspicious({
    required String ipAddress,
  }) async {
    try {
      _logger.i('🔍 Checking IP reputation: $ipAddress');
      
      // Count failed logins from this IP in last 1 hour
      final failedAttempts = await supabase
          .from('rate_limit_log')
          .select('id')
          .eq('ip_address', ipAddress)
          .eq('action', 'login')
          .eq('success', false)
          .gt('created_at', DateTime.now().subtract(const Duration(hours: 1)).toIso8601String())
          .limit(1);

      final failureCount = failedAttempts.length;
      final isSuspicious = failureCount > 10;
      
      if (isSuspicious) {
        _logger.w('⚠️ IP $ipAddress marked as suspicious ($failureCount failures)');
      }
      
      return isSuspicious;
    } catch (e) {
      _logger.e('❌ Error checking IP: $e');
      return false; // Fail open
    }
  }
}
