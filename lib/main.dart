import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'landing_page_animated.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';
import 'forgot_password_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';

const supabaseUrl = 'https://fppmuibvpxrkwmymszhd.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlna3ZncnZyZHBibXVueHdoa2F4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQyNDUyMDAsImV4cCI6MjAyMDI0NTIwMH0.LMQFPSP8JVqVdP_sKHbQWqfyV8tHzM1KI5tLQ7vPczs';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraSphere',
      theme: ThemeData(primaryColor: const Color(0xFF007BFF)),
      initialRoute: '/',
      routes: {
        '/': (c) => const LandingPageAnimated(),
        '/sign-in': (c) => const SignInPage(),
        '/sign-up': (c) => const SignUpPage(),
        '/forgot-password': (c) => const ForgotPasswordPage(),
        '/dashboard': (c) => const DashboardPage(),
        '/home': (c) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        if ((settings.name == '/dashboard' || settings.name == '/home') && 
            Supabase.instance.client.auth.currentUser == null) {
          return MaterialPageRoute(builder: (c) => const SignInPage());
        }
        return null;
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (c) => const LandingPageAnimated()),
    );
  }
}
