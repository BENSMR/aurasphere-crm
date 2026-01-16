import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'landing_page_animated.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';
import 'forgot_password_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';

const supabaseUrl = 'https://lxufgembtogmsvwhdvq.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4dWZnemVtYnRvZ21zdndoZHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTAxMTAsImV4cCI6MjA4NDEyNjExMH0.5Ha4bS4HeuMEqqalpPa_wCSol116rxlllR5s__kVtFs';

void main() async {
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ FLUTTER ERROR: ${details.exception}');
  };
  
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
