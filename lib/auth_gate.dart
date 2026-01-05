import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'landing_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Check auth in background, don't block rendering
    _checkAuthInBackground();
  }

  Future<void> _checkAuthInBackground() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      // Silently fail - user stays on landing page
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show landing page immediately - navigate to dashboard if already logged in
    return const LandingPage();
  }
}
