// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sign_in_page.dart';
import 'home_page.dart';
import 'onboarding_survey.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _shouldShowOnboarding(SupabaseClient supabase) async {
    try {
      // Check if user preferences exist and onboarding is complete
      final prefs = await supabase
          .from('user_preferences')
          .select('features, onboarding_completed')
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      if (prefs == null) return true; // New user

      // Check if behavioral onboarding is enabled
      final features = prefs['features'] as Map<String, dynamic>?;
      final behavioralEnabled = features?['behavioral_onboarding'] == true;

      // Check if onboarding was completed
      final isCompleted = prefs['onboarding_completed'] == true;

      // Show onboarding if enabled and not completed
      return behavioralEnabled && !isCompleted;
    } catch (e) {
      // If error (e.g., table doesn't exist), assume new user
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        
        if (session == null) {
          return const SignInPage();
        }

        // Check if we should show onboarding
        return FutureBuilder<bool>(
          future: _shouldShowOnboarding(supabase),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final showOnboarding = onboardingSnapshot.data ?? false;
            return showOnboarding ? const OnboardingSurvey() : const HomePage();
          },
        );
      },
    );
  }
}
