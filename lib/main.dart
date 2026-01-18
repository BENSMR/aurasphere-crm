import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'theme/modern_theme.dart';
import 'landing_page_animated.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';
import 'forgot_password_page.dart';

const supabaseUrl = 'https://lxufgzembtogmsvwhdvq.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4dWZnemVtYnRvZ21zdndoZHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTAxMTAsImV4cCI6MjA4NDEyNjExMH0.5Ha4bS4HeuMEqqalpPa_wCSol116rxlllR5s__kVtFs';

void main() async {
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) { print('ERROR: ' + details.exception.toString()); };
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraSphere CRM',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: ModernTheme.electricBlue, brightness: Brightness.light), fontFamily: 'Manrope'),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: ModernTheme.electricBlue, brightness: Brightness.dark), fontFamily: 'Manrope'),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (c) => const LandingPageAnimated(),
        '/sign-in': (c) => const SignInPage(),
        '/sign-up': (c) => const SignUpPage(),
        '/forgot-password': (c) => const ForgotPasswordPage(),
        '/dashboard': (c) => const DashboardScreen(),
        '/home': (c) => const DashboardScreen(),
      },
      onGenerateRoute: (settings) {
        if ((['/','/dashboard', '/home'].contains(settings.name)) && Supabase.instance.client.auth.currentUser == null) {
          return MaterialPageRoute(builder: (c) => const SignInPage());
        }
        return null;
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (c) => const LandingPageAnimated()),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (supabase.auth.currentUser == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🎯 AuraSphere CRM'), backgroundColor: ModernTheme.electricBlue, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('Welcome back! 👋', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: ModernTheme.electricBlue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(supabase.auth.currentUser?.email ?? 'User', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              const Text('✅ Your AuraSphere CRM Dashboard is LIVE!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 16),
              const Text('Built with Material 3, responsive design, and Supabase integration.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/'), child: const Text('Go Home')),
            ]))),
          ]),
        ),
      ),
    );
  }
}
