import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class for authentication checks across the app
class AuthHelper {
  /// Check if user is authenticated and redirect if not
  static void checkAuthAndRedirect(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      });
    }
  }

  /// Check authentication in both initState and build
  /// Returns true if user is authenticated, false otherwise
  static bool isAuthenticated() {
    return Supabase.instance.client.auth.currentUser != null;
  }

  /// Get current user ID or null if not authenticated
  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Get current user email or null if not authenticated
  static String? getCurrentUserEmail() {
    return Supabase.instance.client.auth.currentUser?.email;
  }

  /// Build an unauthenticated fallback widget
  static Widget buildAuthFallback() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Please sign in to access this page',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(_context ?? navigatorKey.currentContext!, '/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper context variable
  static BuildContext? _context;
  
  /// Initialize with context for fallback
  static void initialize(BuildContext context) {
    _context = context;
  }
}

/// Global navigator key for auth redirects
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
