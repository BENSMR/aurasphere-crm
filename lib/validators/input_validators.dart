/// Input Validation Service
/// Provides validators for email, password, phone, and other form fields
/// Prevents invalid data from entering the database and protects against XSS attacks
library;

class InputValidators {
  // Email regex (RFC 5322 simplified)
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&' "'" r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  // Phone regex (international format support)
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$', // E.164 format
  );

  // URL regex
  static final RegExp _urlRegex = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  /// Validate email address
  /// Returns error message if invalid, null if valid
  static String? validateEmail(String email) {
    email = email.trim();
    
    if (email.isEmpty) {
      return 'Email is required';
    }

    if (email.length > 254) {
      return 'Email is too long (max 254 characters)';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  /// Validate password strength
  /// Returns error message if weak, null if strong
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (password.length > 128) {
      return 'Password is too long (max 128 characters)';
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter (A-Z)';
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter (a-z)';
    }

    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number (0-9)';
    }

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:".<>?/\\|`~]'))) {
      return 'Password must contain at least one special character (!@#$%^&*)';
    }

    return null; // Valid
  }

  /// Get password strength score (0-4)
  /// 0 = very weak, 1 = weak, 2 = fair, 3 = good, 4 = strong
  static int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;

    return score.clamp(0, 4);
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int score) {
    switch (score) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Format and validate phone number
  /// Returns formatted phone number (E.164) if valid, null if invalid
  static String? formatPhone(String phone) {
    // Remove all non-digit and plus characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) {
      return null;
    }

    // Ensure it starts with + for international format
    final formatted = cleaned.startsWith('+') ? cleaned : '+$cleaned';

    if (!_phoneRegex.hasMatch(formatted)) {
      return null; // Invalid format
    }

    return formatted;
  }

  /// Validate phone number
  /// Returns error message if invalid, null if valid
  static String? validatePhone(String phone) {
    phone = phone.trim();

    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    if (phone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (phone.length > 15) {
      return 'Phone number is too long';
    }

    final formatted = formatPhone(phone);
    if (formatted == null) {
      return 'Please enter a valid phone number (e.g., +1234567890)';
    }

    return null; // Valid
  }

  /// Validate URL
  /// Returns error message if invalid, null if valid
  static String? validateURL(String url) {
    url = url.trim();

    if (url.isEmpty) {
      return 'URL is required';
    }

    if (url.length > 2048) {
      return 'URL is too long (max 2048 characters)';
    }

    if (!_urlRegex.hasMatch(url)) {
      return 'Please enter a valid URL (must start with http:// or https://)';
    }

    return null; // Valid
  }

  /// Validate name field
  /// Returns error message if invalid, null if valid
  static String? validateName(String name) {
    name = name.trim();

    if (name.isEmpty) {
      return 'Name is required';
    }

    if (name.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (name.length > 100) {
      return 'Name is too long (max 100 characters)';
    }

    // Only allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null; // Valid
  }

  /// Validate number field
  /// Returns error message if invalid, null if valid
  static String? validateNumber(String value, {int? min, int? max}) {
    value = value.trim();

    if (value.isEmpty) {
      return 'Value is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (min != null && number < min) {
      return 'Value must be at least $min';
    }

    if (max != null && number > max) {
      return 'Value must be at most $max';
    }

    return null; // Valid
  }

  /// Sanitize input to prevent XSS attacks
  /// Removes dangerous HTML/JavaScript characters
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Validate and sanitize input
  /// Returns tuple of (isValid, sanitized value, error message)
  static (bool, String, String?) validateAndSanitize(
    String input, {
    required String type, // 'email', 'password', 'phone', 'name', 'url'
    String? customError,
  }) {
    final sanitized = sanitize(input);

    String? error;
    switch (type.toLowerCase()) {
      case 'email':
        error = validateEmail(sanitized);
        break;
      case 'password':
        error = validatePassword(sanitized);
        break;
      case 'phone':
        error = validatePhone(sanitized);
        break;
      case 'name':
        error = validateName(sanitized);
        break;
      case 'url':
        error = validateURL(sanitized);
        break;
      default:
        error = customError;
    }

    return (error == null, sanitized, error ?? customError);
  }
}
