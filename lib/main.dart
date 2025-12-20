import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth_gate.dart';
import 'services/aura_security.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const AurasphereCRM());
}

class AurasphereCRM extends StatefulWidget {
  const AurasphereCRM({super.key});

  @override
  State<AurasphereCRM> createState() => _AurasphereCRMState();
}

class _AurasphereCRMState extends State<AurasphereCRM> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final supabase = Supabase.instance.client;
      // Get user preferences
      final prefs = await supabase
          .from('user_preferences')
          .select('language, features')
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();
      
      // Set language
      final userLang = prefs?['language'] ?? 'en';
      setState(() => _locale = Locale(userLang));
      
      // Initialize PKI encryption if enabled
      final features = prefs?['features'] as Map<String, dynamic>?;
      final pkiMode = features?['pki_mode'] == true;
      
      if (pkiMode && !AuraSecurity.isInitialized) {
        await AuraSecurity.initPKI();
        print('🔐 PKI-Grade Encryption: ACTIVE');
      }
    } catch (e) {
      // Ignore errors - use default settings
      print('⚠️ Failed to load user preferences: $e');
    }
  }

  void updateLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurasphere CRM',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),      // English
        Locale('fr'),      // French
        Locale('it'),      // Italian
        Locale('de'),      // German
        Locale('es'),      // Spanish
        Locale('mt'),      // Maltese
        Locale('ar'),      // Arabic (Standard)
        Locale('ar', 'EG'),// Arabic (Egyptian)
        Locale('ar', 'MA'),// Arabic (Moroccan)
      ],
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        return Directionality(
          textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}
