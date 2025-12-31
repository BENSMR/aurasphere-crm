import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_page.dart';
import 'core/env_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await EnvLoader.init();
  } catch (e) {}
  try {
    final url = EnvLoader.get('SUPABASE_URL');
    final anonKey = EnvLoader.get('SUPABASE_ANON_KEY');
    if (url.isNotEmpty && anonKey.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
  } catch (e) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraSphere CRM',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007BFF))),
      debugShowCheckedModeBanner: false,
      home: const DashboardPage(),
    );
  }
}
