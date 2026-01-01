import 'package:flutter/material.dart';

class LandingPageAnimated extends StatelessWidget {
  const LandingPageAnimated({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00FF7F), Color(0xFF007BFF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Badge - Free Trial
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Text(
                    '🎉 3 Days Free Trial - No Credit Card Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Main Headline
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Stop Losing Jobs to Spreadsheets',
                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subheadline
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'The sovereign CRM for tradespeople built to scale your business',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Main CTA Button
                SizedBox(
                  width: 280,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Start 3-Day Free Trial',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007BFF),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Secondary CTA - Subscription Offer
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '💰 LIMITED TIME OFFER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '50% OFF',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'First 2 Months',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text(
                          'Claim Discount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Trust Badges
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Text(
                        'Trusted by 500+ tradespeople',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TrustBadge(icon: '✓', label: 'No CC Required'),
                          const SizedBox(width: 20),
                          _TrustBadge(icon: '🔒', label: 'EU Hosted'),
                          const SizedBox(width: 20),
                          _TrustBadge(icon: '🌍', label: 'GDPR Safe'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80),
                
                // ==================== PAIN POINTS SECTION ====================
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      const Text(
                        'The Problem',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _PainPointCard(
                              icon: '📝',
                              title: 'Lost in Spreadsheets',
                              description: 'Hours wasted managing jobs in Excel instead of growing your business',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _PainPointCard(
                              icon: '⏰',
                              title: 'Slow Invoicing',
                              description: 'Takes 30 minutes to create each invoice. Payments delayed.',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _PainPointCard(
                              icon: '😤',
                              title: 'No Client Visibility',
                              description: 'Clients confused about job status, pricing, and payment terms',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ==================== FEATURES SECTION ====================
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Text(
                        'Our Solution',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Everything you need to run your trade business professionally',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _FeatureCard('🎯', 'Job Tracking', 'Track jobs from quote to completion'),
                          _FeatureCard('📊', 'Business Analytics', 'Revenue, profit & performance insights'),
                          _FeatureCard('💰', 'AI Invoicing', 'Generate invoices in seconds'),
                          _FeatureCard('👥', 'Team Dispatch', 'Assign jobs and track team in real-time'),
                          _FeatureCard('🤖', 'AI Assistant', 'Voice commands in 9 languages'),
                          _FeatureCard('📱', 'Mobile Ready', 'Works perfectly on any device'),
                          _FeatureCard('🌍', '9 Languages', 'English, French, Italian, Arabic & more'),
                          _FeatureCard('💳', '40+ Tax Systems', 'Auto-calculate taxes for any country'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ==================== TESTIMONIALS SECTION ====================
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  color: Colors.blue[50],
                  child: Column(
                    children: [
                      const Text(
                        'Loved by 500+ Tradespeople',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _TestimonialCard(
                            name: 'Ahmed K.',
                            role: 'Plumber, Dubai',
                            quote: 'Invoices in Arabic? Finally! Got paid 2x faster with AuraSphere.',
                            rating: 5,
                          ),
                          _TestimonialCard(
                            name: 'Jean P.',
                            role: 'Electrician, Paris',
                            quote: 'Saves me 5 hours every week. Best CRM for tradespeople.',
                            rating: 5,
                          ),
                          _TestimonialCard(
                            name: 'Maria L.',
                            role: 'Contractor, Spain',
                            quote: 'My team loves it. Professional invoices, real-time dispatch. Worth it!',
                            rating: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ==================== FOOTER ====================
                Container(
                  padding: const EdgeInsets.all(40),
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AuraSphere CRM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Built for tradespeople, by tradespeople',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Product',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/pricing'),
                                child: const Text(
                                  'Pricing',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Features',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Company',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'About',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Contact',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 20),
                      const Text(
                        '© 2025 AuraSphere. All rights reserved. Built in Europe, trusted worldwide.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

class _PainPointCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _PainPointCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _FeatureCard(this.icon, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardWidth = isMobile ? double.infinity : 200.0;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String role;
  final String quote;
  final int rating;

  const _TestimonialCard({
    required this.name,
    required this.role,
    required this.quote,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardWidth = isMobile ? double.infinity : 300.0;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stars
            Row(
              children: List.generate(
                rating,
                (index) => const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
              ),
            ),
            const SizedBox(height: 12),
            // Quote
            Text(
              '"$quote"',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            // Name & Role
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final String icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
