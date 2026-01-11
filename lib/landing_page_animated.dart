import 'package:flutter/material.dart';

class LandingPageAnimated extends StatefulWidget {
  const LandingPageAnimated({super.key});

  @override
  State<LandingPageAnimated> createState() => _LandingPageAnimatedState();
}

class _LandingPageAnimatedState extends State<LandingPageAnimated> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNavBar(isMobile),
            _buildHeroSection(isMobile),
            _buildValueSection(isMobile),
            _buildStatsSection(isMobile),
            _buildPricingSection(isMobile),
            _buildTestimonialsSection(isMobile),
            _buildCTASection(),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF0056CC)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'AS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AuraSphere',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          if (!isMobile)
            Row(
              children: [
                const SizedBox(width: 40),
              ],
            ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/sign-in'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007BFF),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 10,
              ),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 80,
        horizontal: isMobile ? 16 : 40,
      ),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isMobile
                ? 'Manage Your Trades'
                : 'Manage Your Trades, Grow Your Business',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 52,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All-in-one CRM for tradespeople. Jobs, invoices, teams, and AI insights in one platform.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 13 : 16,
              color: const Color(0xFF6C757D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 32,
                    vertical: isMobile ? 10 : 14,
                  ),
                ),
                child: Text(
                  'Start Free Trial',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF007BFF), width: 2),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 32,
                    vertical: isMobile ? 10 : 14,
                  ),
                ),
                child: Text(
                  'Learn More',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007BFF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueSection(bool isMobile) {
    final values = [
      ('⚡ Fast', 'Real-time updates and instant notifications'),
      ('🔒 Secure', 'Bank-level encryption and compliance'),
      ('🤖 AI-Powered', 'Autonomous agents analyze your business'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 40,
      ),
      color: const Color(0xFFF8FAFC),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Why AuraSphere?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: values
                      .map((v) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _valueItem(v.$1, v.$2),
                          ))
                      .toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: values
                      .map((v) => Expanded(
                            child: _valueItem(v.$1, v.$2),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _valueItem(String title, String desc) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6C757D),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 40,
      ),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statItem('10K+', 'Active Users'),
                    const SizedBox(height: 24),
                    _statItem('50M+', 'Transactions'),
                    const SizedBox(height: 24),
                    _statItem('99.9%', 'Uptime'),
                    const SizedBox(height: 24),
                    _statItem('24/7', 'Support'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('10K+', 'Active Users'),
                    _statItem('50M+', 'Transactions'),
                    _statItem('99.9%', 'Uptime'),
                    _statItem('24/7', 'Support'),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF007BFF),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(bool isMobile) {
    final plans = [
      {
        'name': 'Solo',
        'price': '\$29/mo',
        'desc': 'For solopreneurs',
        'features': ['1 user', 'Core CRM', 'Jobs & Invoices', 'Email support'],
        'popular': false,
      },
      {
        'name': 'Team',
        'price': '\$79/mo',
        'desc': 'Most popular',
        'features': ['3 users', 'Everything in Solo', 'Team tools', 'AI insights', 'Priority support'],
        'popular': true,
      },
      {
        'name': 'Workshop',
        'price': '\$199/mo',
        'desc': 'For teams',
        'features': ['7 users', 'Everything in Team', 'Unlimited features', 'API access', '24/7 support'],
        'popular': false,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 40,
      ),
      color: const Color(0xFFF8FAFC),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Simple Pricing',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '14-day free trial. No credit card needed.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6C757D),
            ),
          ),
          const SizedBox(height: 32),
          isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: plans
                      .map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _pricingCard(p, isMobile),
                          ))
                      .toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: plans
                      .map((p) => Expanded(
                            child: _pricingCard(p, isMobile),
                          ))
                      .toList()
                      .fold<List<Widget>>(
                        [],
                        (list, card) {
                          if (list.isNotEmpty) list.add(const SizedBox(width: 16));
                          list.add(card);
                          return list;
                        },
                      ),
                ),
        ],
      ),
    );
  }

  Widget _pricingCard(Map plan, bool isMobile) {
    final isPopular = plan['popular'] as bool;
    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isPopular ? const Color(0xFF007BFF) : const Color(0xFFE0E0E0),
          width: isPopular ? 2 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007BFF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              plan['name'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan['desc'] as String,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6C757D),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              plan['price'] as String,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? const Color(0xFF007BFF) : Colors.white,
                  side: isPopular ? null : const BorderSide(color: Color(0xFF007BFF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPopular ? Colors.white : const Color(0xFF007BFF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...((plan['features'] as List).map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialsSection(bool isMobile) {
    final testimonials = [
      {
        'name': 'Sarah Johnson',
        'role': 'Plumbing',
        'quote': 'Cut my admin time in half!',
      },
      {
        'name': 'Mike Chen',
        'role': 'Electrical',
        'quote': 'AI insights helped win better jobs.',
      },
      {
        'name': 'Lisa Martinez',
        'role': 'HVAC',
        'quote': 'Communication is instant & seamless.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 40,
      ),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Loved by Tradespeople',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: testimonials
                      .map((t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _testimonialCard(t),
                          ))
                      .toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: testimonials
                      .map((t) => Expanded(
                            child: _testimonialCard(t),
                          ))
                      .toList()
                      .fold<List<Widget>>(
                        [],
                        (list, card) {
                          if (list.isNotEmpty) list.add(const SizedBox(width: 16));
                          list.add(card);
                          return list;
                        },
                      ),
                ),
        ],
      ),
    );
  }

  Widget _testimonialCard(Map testimonial) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (i) => Icon(Icons.star, color: Colors.amber, size: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              testimonial['quote'] as String,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              testimonial['name'] as String,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              testimonial['role'] as String,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF007BFF), Color(0xFF0056CC)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ready to transform your business?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of tradespeople already using AuraSphere',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/sign-up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: const Text(
              'Start Your Free Trial',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007BFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 48,
        horizontal: isMobile ? 16 : 40,
      ),
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF0056CC)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    'AS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AuraSphere',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '© 2026 AuraSphere. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
