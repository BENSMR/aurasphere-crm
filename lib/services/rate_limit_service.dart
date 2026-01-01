import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

/// Rate Limiting Service
/// Prevents brute force attacks by limiting login attempts
/// 
/// Rules:
/// - Max 5 failed attempts per email per 5 minutes
/// - Max 10 failed attempts per IP per 5 minutes
/// - Blocks further attempts after limits exceeded
class RateLimitService {
  static final RateLimitService _instance = RateLimitService._internal();
  
  factory RateLimitService() => _instance;
  
  RateLimitService._internal();

  final supabase = Supabase.instance.client;
  
  // Time window for rate limiting (5 minutes)
  static const Duration _timeWindow = Duration(minutes: 5);
  
  // Max attempts in time window
  static const int _maxAttemptsPerEmail = 5;
  static const int _maxAttemptsPerIP = 10;

  /// Check if a user/IP has exceeded rate limit
  /// Returns true if request is allowed, false if blocked
  Future<bool> isAllowed({
    required String userEmail,
    required String ipAddress,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final timeWindowStart = now.subtract(_timeWindow);

      // Check email-based rate limit
      final emailAttempts = await supabase
          .from('rate_limits')
          .select('id')
          .eq('user_email', userEmail)
          .gte('attempted_at', timeWindowStart.toIso8601String())
          .eq('success', false)
          .count();

      if (emailAttempts >= _maxAttemptsPerEmail) {
        _logger.w('🚫 Rate limit exceeded for email: $userEmail (${emailAttempts} attempts)');
        return false;
      }

      // Check IP-based rate limit
      final ipAttempts = await supabase
          .from('rate_limits')
          .select('id')
          .eq('attempt_ip', ipAddress)
          .gte('attempted_at', timeWindowStart.toIso8601String())
          .eq('success', false)
          .count();

      if (ipAttempts >= _maxAttemptsPerIP) {
        _logger.w('🚫 Rate limit exceeded for IP: $ipAddress (${ipAttempts} attempts)');
        return false;
      }

      _logger.d('✅ Rate limit check passed for $userEmail');
      return true;
    } catch (e) {
      _logger.e('❌ Rate limit check error: $e');
      // On error, allow request (fail open, not closed)
      return true;
    }
  }

  /// Record a login attempt
  /// Call this AFTER attempting login to track success/failure
  Future<void> recordAttempt({
    required String userEmail,
    required String ipAddress,
    required bool success,
  }) async {
    try {
      await supabase.from('rate_limits').insert({
        'user_email': userEmail,
        'attempt_ip': ipAddress,
        'success': success,
        'attempted_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (success) {
        _logger.i('✅ Successful login recorded for $userEmail');
      } else {
        _logger.w('❌ Failed login attempt recorded for $userEmail');
      }
    } catch (e) {
      _logger.e('❌ Failed to record attempt: $e');
      // Don't fail the auth flow if logging fails
    }
  }

  /// Get remaining attempts for an email
  /// Returns number of attempts remaining in current window (or 0 if blocked)
  Future<int> getRemainingAttempts({
    required String userEmail,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final timeWindowStart = now.subtract(_timeWindow);

      final attempts = await supabase
          .from('rate_limits')
          .select('id')
          .eq('user_email', userEmail)
          .gte('attempted_at', timeWindowStart.toIso8601String())
          .eq('success', false)
          .count();

      final remaining = (_maxAttemptsPerEmail - attempts).clamp(0, _maxAttemptsPerEmail);
      _logger.d('📊 Remaining attempts for $userEmail: $remaining');
      return remaining;
    } catch (e) {
      _logger.e('❌ Error getting remaining attempts: $e');
      return _maxAttemptsPerEmail;
    }
  }

  /// Clear all attempts for a user (e.g., after successful login)
  Future<void> clearAttempts({
    required String userEmail,
  }) async {
    try {
      await supabase
          .from('rate_limits')
          .delete()
          .eq('user_email', userEmail);

      _logger.i('✅ Cleared rate limit attempts for $userEmail');
    } catch (e) {
      _logger.e('❌ Failed to clear attempts: $e');
    }
  }

  /// Get user's IP address (for web, get from browser if available)
  /// Note: On web, you may need to use an external service for accurate IP
  /// since browsers don't expose IP for security reasons
  static String? getUserIPAddress() {
    // On web, IP detection requires backend support
    // For now, use a placeholder or get from external service
    // In production, call a backend function to get the user's IP
    return null; // Will be handled in sign_in_page.dart
  }
}
