import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class LandingPageAnimated extends StatelessWidget {
  const LandingPageAnimated({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("✅ REAL ANIMATED LANDING PAGE"),
        backgroundColor: Colors.green,
        elevation: 2,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Hero Section with Animation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      '✅ AuraSphere CRM',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007BFF),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Stop Losing Jobs to Spreadsheets',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'The sovereign CRM for tradespeople — EU-hosted, zero tracking.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Main CTA Button
              ElevatedButton(
                onPressed: () {
                  _logger.d('Get Started tapped');
                  Navigator.pushNamed(context, '/sign-in');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Features Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      'Everything You Need',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _FeatureCard(
                          icon: Icons.work_outline,
                          title: 'Job Management',
                          description: 'Track jobs and tasks',
                          onTap: () => _logger.d('Job Management tapped'),
                        ),
                        _FeatureCard(
                          icon: Icons.receipt_long,
                          title: 'Invoicing',
                          description: 'Professional invoices',
                          onTap: () => _logger.d('Invoicing tapped'),
                        ),
                        _FeatureCard(
                          icon: Icons.people,
                          title: 'Client Database',
                          description: 'Organize customers',
                          onTap: () => _logger.d('Client Database tapped'),
                        ),
                        _FeatureCard(
                          icon: Icons.assignment_outlined,
                          title: 'Team Dispatch',
                          description: 'Assign and track',
                          onTap: () => _logger.d('Team Dispatch tapped'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Secondary CTA
              ElevatedButton.outlined(
                onPressed: () {
                  _logger.d('Pricing tapped');
                  Navigator.pushNamed(context, '/sign-in');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007BFF),
                  side: const BorderSide(color: Color(0xFF007BFF), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Pricing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                color: Colors.grey[100],
                width: double.infinity,
                child: Column(
                  children: [
                    const Text(
                      'AuraSphere CRM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'EU-hosted • Zero tracking • GDPR compliant',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '© 2025 AuraSphere. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF007BFF)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
