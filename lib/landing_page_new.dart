import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                _HeroSection(),
                _PainPoints(),
                _Features(),
                _SocialProof(),
                _FinalCTA(),
                _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== HERO SECTION ==================
class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 80 : 20,
        vertical: 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LOGO + NAV
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007BFF), Color(0xFFFFD700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.work, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AuraSphere',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF007BFF),
                    ),
                  ),
                ],
              ),
              // LOGIN + LOGOUT BUTTONS
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully')),
                      );
                    },
                    child: const Text('Log Out', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 80),
          
          // HEADLINE
          SizedBox(
            width: MediaQuery.of(context).size.width > 700 ? 600 : double.infinity,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.1),
                children: [
                  const TextSpan(text: 'CRM Built for '),
                  TextSpan(
                    text: 'Tradespeople',
                    style: const TextStyle(color: Color(0xFF007BFF)),
                  ),
                ],
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 24),
          
          // SUBHEADLINE
          SizedBox(
            width: MediaQuery.of(context).size.width > 700 ? 500 : double.infinity,
            child: Text(
              'Manage jobs, clients, and invoices in one place — no tech skills needed. 3-day free trial, no credit card.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // PRIMARY CTA - SIGN UP
          SizedBox(
            width: MediaQuery.of(context).size.width > 600 ? 300 : double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Free Trial'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '✅ No credit card • 3 days full access • Cancel anytime',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          
          const SizedBox(height: 60),
          
          // HERO IMAGE PLACEHOLDER
          Container(
            height: MediaQuery.of(context).size.width > 700 ? 400 : 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'App Screenshot: Job Tracking + Invoicing',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== PAIN POINTS ==================
class _PainPoints extends StatelessWidget {
  final pains = [
    {'icon': Icons.receipt_long, 'title': 'Lost Invoices', 'desc': 'Chasing late payments? Get paid faster.'},
    {'icon': Icons.schedule, 'title': 'Double-Booked Jobs', 'desc': 'See your whole team\'s schedule in one place.'},
    {'icon': Icons.inventory_2, 'title': 'Stock Surprises', 'desc': 'Low pipe alerts before you leave the warehouse.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Tradespeople told us their biggest headaches:',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pains.length,
              itemBuilder: (context, index) {
                final pain = pains[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(pain['icon'], color: Colors.red, size: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pain['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pain['desc'] as String,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================== FEATURES ==================
class _Features extends StatelessWidget {
  final features = [
    {'icon': Icons.work, 'title': 'Job Tracking', 'desc': 'Status, materials, photos, and client notes in one place'},
    {'icon': Icons.receipt, 'title': 'AI Invoicing', 'desc': '"Create invoice for Ahmed 300 AED" → done in 10 seconds'},
    {'icon': Icons.group, 'title': 'Team Dispatch', 'desc': 'Assign jobs, track location, see live availability'},
    {'icon': Icons.language, 'title': '9 Languages', 'desc': 'EN/FR/AR/IT/DE/ES/MT + Arabic dialects'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Column(
        children: [
          const Text(
            'Everything You Need, Nothing You Don\'t',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            children: features.map((feature) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 90) / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (feature['icon'] == Icons.work) ? Colors.blue.withValues(alpha: 0.1) :
                                (feature['icon'] == Icons.receipt) ? Colors.orange.withValues(alpha: 0.1) :
                                (feature['icon'] == Icons.group) ? Colors.green.withValues(alpha: 0.1) :
                                Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        feature['icon'],
                        color: (feature['icon'] == Icons.work) ? Colors.blue :
                                (feature['icon'] == Icons.receipt) ? Colors.orange :
                                (feature['icon'] == Icons.group) ? Colors.green :
                                Colors.purple,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feature['desc'] as String,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ================== SOCIAL PROOF ==================
class _SocialProof extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Text(
            'Trusted by 500+ Trades Across 12 Countries',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TestimonialCard(
                name: 'Ahmed K.',
                role: 'Plumber, Dubai',
                quote: 'Invoices in Arabic? Yes! Got paid 2x faster.',
                color: Colors.blue,
              ),
              _TestimonialCard(
                name: 'Jean P.',
                role: 'Electrician, Paris',
                quote: 'Finally, a CRM that doesn\'t look like accounting software.',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name, role, quote;
  final Color color;
  const _TestimonialCard({
    required this.name,
    required this.role,
    required this.quote,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.person, color: color, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"$quote"',
            style: const TextStyle(fontStyle: FontStyle.italic, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ================== FINAL CTA ==================
class _FinalCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00FF7F), Color(0xFF007BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Ditch Spreadsheets?',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Join 500+ trades saving 10+ hours/week',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 250,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              child: const Text('Start Free Trial →'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No credit card • Cancel anytime • EU-hosted',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ================== FOOTER ==================
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AuraSphere CRM',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF007BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Sovereign CRM for tradespeople — EU-hosted, zero tracking',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 30,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _FooterLink('Privacy'),
              _FooterLink('Terms'),
              _FooterLink('Support'),
              _FooterLink('GDPR'),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Operated by Black Diamond LTD (UIC: 207807571), Sofia, Bulgaria',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}
