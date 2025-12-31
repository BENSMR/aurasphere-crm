// lib/onboarding_survey.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

class OnboardingSurvey extends StatefulWidget {
  const OnboardingSurvey({super.key});

  @override
  State<OnboardingSurvey> createState() => _OnboardingSurveyState();
}

class _OnboardingSurveyState extends State<OnboardingSurvey> {
  final supabase = Supabase.instance.client;
  int _step = 0;
  String? _businessType;
  String? _teamSize;
  final List<String> _goals = [];

  final _businessTypes = [
    {'type': 'freelancer', 'title': 'Solo freelancer', 'subtitle': 'Designers, developers, consultants'},
    {'type': 'trades', 'title': 'Trades business', 'subtitle': 'Plumbers, electricians, workshops'},
  ];

  final _teamSizes = [
    'Just me',
    '2-5 people',
    '6-10 people',
    '11-20 people',
    '20+ people',
  ];

  final _goalOptions = [
    'Track invoices & payments',
    'Manage client relationships',
    'Automate expense tracking',
    'Generate financial reports',
    'Team collaboration',
    'AI-powered insights',
  ];

  Future<void> _completeOnboarding() async {
    try {
      // Save onboarding data
      await supabase.from('user_preferences').upsert({
        'user_id': supabase.auth.currentUser?.id,
        'onboarding_completed': true,
        'business_type': _businessType,
        'team_size': _teamSize,
        'goals': _goals,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    }
  }

  Widget _buildStep0() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.waving_hand, size: 80, color: Colors.indigo),
        const SizedBox(height: 24),
        const Text(
          'Welcome to AuraSphere!',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Let\'s personalize your experience',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          ),
          onPressed: () => setState(() => _step = 1),
          child: const Text('Get Started', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How do you work?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ..._businessTypes.map((type) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              type['title']!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                type['subtitle']!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            trailing: _businessType == type['type']
                ? const Icon(Icons.check_circle, color: Colors.indigo, size: 32)
                : const Icon(Icons.circle_outlined, color: Colors.grey, size: 32),
            onTap: () => setState(() => _businessType = type['type']),
          ),
        )),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: _businessType != null ? () => setState(() => _step = 2) : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s your team size?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ..._teamSizes.map((size) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RadioListTile<String>(
            title: Text(size, style: const TextStyle(fontSize: 18)),
            value: size,
            groupValue: _teamSize,
            onChanged: (val) => setState(() => _teamSize = val),
            activeColor: Colors.indigo,
          ),
        )),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: _teamSize != null ? () => setState(() => _step = 3) : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are your main goals?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select all that apply',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        ..._goalOptions.map((goal) => CheckboxListTile(
          title: Text(goal, style: const TextStyle(fontSize: 16)),
          value: _goals.contains(goal),
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _goals.add(goal);
              } else {
                _goals.remove(goal);
              }
            });
          },
          activeColor: Colors.indigo,
        )),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 2),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: _goals.isNotEmpty ? _completeOnboarding : null,
              child: const Text('Complete'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Progress indicator
                    if (_step > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          children: List.generate(3, (index) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                                decoration: BoxDecoration(
                                  color: index < _step ? Colors.indigo : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    // Content
                    if (_step == 0) _buildStep0(),
                    if (_step == 1) _buildStep1(),
                    if (_step == 2) _buildStep2(),
                    if (_step == 3) _buildStep3(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
