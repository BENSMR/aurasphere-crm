import 'package:flutter_test/flutter_test.dart';
import 'package:aura_crm/validators/input_validators.dart';
import 'package:aura_crm/services/rate_limit_service.dart';

void main() {
  group('Input Validators Tests', () {
    test('validateEmail - valid emails', () {
      expect(InputValidators.validateEmail('user@example.com'), true);
      expect(InputValidators.validateEmail('john.doe@company.co.uk'), true);
      expect(InputValidators.validateEmail('test+tag@domain.com'), true);
    });

    test('validateEmail - invalid emails', () {
      expect(InputValidators.validateEmail('invalid.email'), false);
      expect(InputValidators.validateEmail('user@'), false);
      expect(InputValidators.validateEmail('@domain.com'), false);
      expect(InputValidators.validateEmail('user @example.com'), false);
    });

    test('validatePassword - strong password', () {
      expect(
          InputValidators.validatePassword('SecurePass123!'), true);
      expect(InputValidators.validatePassword('MyP@ssw0rd'), true);
      expect(InputValidators.validatePassword('Comp1ex#Pwd'), true);
    });

    test('validatePassword - weak password', () {
      expect(InputValidators.validatePassword('weak'), false); // Too short
      expect(
          InputValidators.validatePassword('nouppercase123!'), false); // No uppercase
      expect(InputValidators.validatePassword('NOLOWERCASE123!'), false); // No lowercase
      expect(InputValidators.validatePassword('NoNumbers!'), false); // No numbers
      expect(InputValidators.validatePassword('NoSpecial123'), false); // No special char
    });

    test('validatePhone - valid phone numbers', () {
      expect(InputValidators.validatePhone('+1234567890'), true);
      expect(InputValidators.validatePhone('+441234567890'), true);
      expect(InputValidators.validatePhone('+33123456789'), true);
    });

    test('validatePhone - invalid phone numbers', () {
      expect(InputValidators.validatePhone('12345'), false); // Too short
      expect(InputValidators.validatePhone('abc123456789'), false); // Contains letters
      expect(InputValidators.validatePhone('1234567890'), false); // Missing +
    });

    test('validateName - valid names', () {
      expect(InputValidators.validateName('John Doe'), true);
      expect(InputValidators.validateName('Mary-Jane'), true);
      expect(InputValidators.validateName("O'Brien"), true);
      expect(InputValidators.validateName('Jean-Pierre'), true);
    });

    test('validateName - invalid names', () {
      expect(InputValidators.validateName('John123'), false); // Contains numbers
      expect(InputValidators.validateName('Jane@Doe'), false); // Contains special char
      expect(InputValidators.validateName('JD'), false); // Too short
    });

    test('validateURL - valid URLs', () {
      expect(InputValidators.validateURL('https://example.com'), true);
      expect(InputValidators.validateURL('http://www.domain.co.uk'), true);
      expect(InputValidators.validateURL('https://subdomain.example.com/path'),
          true);
    });

    test('validateURL - invalid URLs', () {
      expect(InputValidators.validateURL('not a url'), false);
      expect(InputValidators.validateURL('ftp://example.com'), false); // Wrong protocol
      expect(InputValidators.validateURL('example.com'), false); // Missing protocol
    });

    test('sanitize - removes XSS vectors', () {
      expect(
          InputValidators.sanitize('<script>alert("XSS")</script>'),
          'alertXSS'); // Script tags removed
      expect(InputValidators.sanitize('<img src=x onerror="alert(1)">'),
          'imgsrcxalert1'); // Event handlers removed
      expect(
          InputValidators.sanitize('Normal text <!-- comment -->'),
          'Normal text  comment '); // Comments preserved but stripped
    });

    test('sanitize - preserves safe text', () {
      expect(InputValidators.sanitize('Hello World'), 'Hello World');
      expect(InputValidators.sanitize('Email: test@example.com'),
          'Email: test@example.com');
      expect(InputValidators.sanitize('Path: /home/user'), 'Path: /home/user');
    });

    test('getPasswordStrength - strength scoring', () {
      expect(InputValidators.getPasswordStrength('weak'), 0); // Invalid
      expect(InputValidators.getPasswordStrength('Weak1!'), 1); // Barely valid
      expect(InputValidators.getPasswordStrength('Medium123!Pass'), 3); // Medium
      expect(InputValidators.getPasswordStrength('VeryStr0ng!@#$%'), 4); // Strong
    });

    test('formatPhone - converts to E.164', () {
      expect(InputValidators.formatPhone('+1234567890'), '+1234567890');
      expect(InputValidators.formatPhone('1234567890'), '+1234567890'); // Adds +
    });

    test('validateAndSanitize - combined validation + sanitization', () {
      // Valid email with no XSS
      final result1 = InputValidators.validateAndSanitize(
          'test@example.com', 'email');
      expect(result1.isValid, true);
      expect(result1.sanitizedValue, 'test@example.com');

      // Invalid email
      final result2 = InputValidators.validateAndSanitize(
          'not an email', 'email');
      expect(result2.isValid, false);

      // Name with XSS attempt (should sanitize)
      final result3 = InputValidators.validateAndSanitize(
          'John<script>alert(1)</script>Doe', 'name');
      expect(result3.sanitizedValue, 'JohnalertDoe'); // XSS removed
    });
  });

  group('Rate Limiting Tests', () {
    final rateLimitService = RateLimitService();

    test('isAllowed - first attempt should be allowed', () async {
      final allowed = await rateLimitService.isAllowed('newuser@example.com', '192.168.1.1');
      expect(allowed, true);
    });

    test('recordAttempt - logs failed attempts', () async {
      const email = 'testuser@example.com';
      const ip = '192.168.1.100';
      
      // Record 3 failed attempts
      for (int i = 0; i < 3; i++) {
        await rateLimitService.recordAttempt(email, ip, false);
      }
      
      // 4th attempt should still be allowed (< 5 attempts)
      final allowed = await rateLimitService.isAllowed(email, ip);
      expect(allowed, true);
    });

    test('isAllowed - blocks after 5 failed attempts', () async {
      const email = 'blockeduser@example.com';
      const ip = '192.168.1.101';
      
      // Record 5 failed attempts
      for (int i = 0; i < 5; i++) {
        await rateLimitService.recordAttempt(email, ip, false);
      }
      
      // 6th attempt should be blocked
      final allowed = await rateLimitService.isAllowed(email, ip);
      expect(allowed, false);
    });

    test('clearAttempts - resets rate limit after successful login', () async {
      const email = 'successuser@example.com';
      const ip = '192.168.1.102';
      
      // Record 3 failed attempts
      for (int i = 0; i < 3; i++) {
        await rateLimitService.recordAttempt(email, ip, false);
      }
      
      // Clear attempts (successful login)
      await rateLimitService.clearAttempts(email);
      
      // Should be allowed again
      final allowed = await rateLimitService.isAllowed(email, ip);
      expect(allowed, true);
    });

    test('getRemainingAttempts - returns correct count', () async {
      const email = 'countuser@example.com';
      const ip = '192.168.1.103';
      
      // Record 2 failed attempts
      for (int i = 0; i < 2; i++) {
        await rateLimitService.recordAttempt(email, ip, false);
      }
      
      // Should have 3 remaining attempts (5 total - 2 used)
      final remaining = await rateLimitService.getRemainingAttempts(email);
      expect(remaining, 3);
    });

    test('IP-based rate limiting - blocks after 10 attempts from same IP', () async {
      const ip = '192.168.1.200';
      
      // Record 10 failed attempts from same IP with different emails
      for (int i = 0; i < 10; i++) {
        await rateLimitService.recordAttempt('user$i@example.com', ip, false);
      }
      
      // 11th attempt from same IP should be blocked (by IP)
      final allowed = await rateLimitService.isAllowed('user11@example.com', ip);
      expect(allowed, false);
    });
  });

  group('Password Validation Edge Cases', () {
    test('minimum length requirement (8 chars)', () {
      expect(InputValidators.validatePassword('Pass1!'), false); // 6 chars
      expect(InputValidators.validatePassword('Pass123!'), true); // 8 chars
    });

    test('uppercase requirement (at least 1)', () {
      expect(InputValidators.validatePassword('lowercase123!'), false);
      expect(InputValidators.validatePassword('Lower123!'), true);
    });

    test('lowercase requirement (at least 1)', () {
      expect(InputValidators.validatePassword('UPPERCASE123!'), false);
      expect(InputValidators.validatePassword('Upper123!'), true);
    });

    test('number requirement (at least 1)', () {
      expect(InputValidators.validatePassword('NoNumbers!'), false);
      expect(InputValidators.validatePassword('HasNumbers1!'), true);
    });

    test('special character requirement (at least 1)', () {
      expect(InputValidators.validatePassword('NoSpecial123'), false);
      expect(InputValidators.validatePassword('WithSpecial!123'), true);
    });
  });

  group('Email Validation Edge Cases', () {
    test('plus addressing (Gmail style)', () {
      expect(InputValidators.validateEmail('user+tag@example.com'), true);
    });

    test('subdomain email addresses', () {
      expect(InputValidators.validateEmail('user@mail.example.co.uk'), true);
    });

    test('consecutive dots should fail', () {
      expect(InputValidators.validateEmail('user..name@example.com'), false);
    });

    test('domain must have TLD', () {
      expect(InputValidators.validateEmail('user@domain'), false);
    });
  });

  group('Sanitization Security Tests', () {
    test('prevents script injection', () {
      final malicious = '<script>stealData()</script>';
      final sanitized = InputValidators.sanitize(malicious);
      expect(sanitized.contains('script'), false);
      expect(sanitized.contains('stealData'), true);
    });

    test('prevents event handler injection', () {
      final malicious = '<img src=x onerror="alert(1)">';
      final sanitized = InputValidators.sanitize(malicious);
      expect(sanitized.contains('onerror'), false);
    });

    test('removes iframe tags', () {
      final malicious = '<iframe src="http://evil.com"></iframe>';
      final sanitized = InputValidators.sanitize(malicious);
      expect(sanitized.contains('iframe'), false);
    });

    test('handles mixed content', () {
      final mixed = 'Hello <script>alert(1)</script> World';
      final sanitized = InputValidators.sanitize(mixed);
      expect(sanitized.contains('<script>'), false);
      expect(sanitized.contains('Hello'), true);
      expect(sanitized.contains('World'), true);
    });
  });
}
