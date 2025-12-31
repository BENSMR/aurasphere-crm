import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
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
        horizontal: MediaQuery.of(context).size.width > 600 ? 100 : 24,
        vertical: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LOGO + LOGIN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFFFF6600)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.construction, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'AuraSphere',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0066FF),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
          
          // HEADLINE
          SizedBox(
            width: MediaQuery.of(context).size.width > 800 ? 700 : double.infinity,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, height: 1.05),
                children: [
                  TextSpan(text: 'Stop Losing Jobs to ', style: const TextStyle(color: Colors.black)),
                  TextSpan(text: 'Spreadsheets', style: const TextStyle(color: Color(0xFF0066FF))),
                ],
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 24),
          
          // SUBHEADLINE
          SizedBox(
            width: MediaQuery.of(context).size.width > 800 ? 600 : double.infinity,
            child: Text(
              'The only CRM built for tradespeople — manage jobs, invoices, and teams in one place. No tech skills needed.',
              style: const TextStyle(fontSize: 20, color: Color(0xFF495057), height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
          
          // PRIMARY CTA
          SizedBox(
            width: MediaQuery.of(context).size.width > 700 ? 400 : double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/sign-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Free Trial'),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '✅ No credit card • 3 days full access • Cancel anytime',
            style: const TextStyle(color: Color(0xFF6C757D), fontSize: 15),
          ),
          
          const SizedBox(height: 80),
          
          // HERO VISUAL
          Container(
            height: MediaQuery.of(context).size.width > 1000 ? 500 : 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Center(
              child: Text('App Demo: Job Tracking + Invoicing', style: TextStyle(color: Colors.grey)),
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
    {'icon': Icons.receipt_long, 'title': 'Lost Invoices', 'desc': 'Chasing late payments? Never lose money again.'},
    {'icon': Icons.schedule, 'title': 'Double-Booked Jobs', 'desc': 'See your whole team\'s schedule in one place.'},
    {'icon': Icons.inventory_2, 'title': 'Stock Surprises', 'desc': 'Low pipe alerts before you leave the warehouse.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
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
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pains.length,
              itemBuilder: (context, index) {
                final pain = pains[index];
                return Container(
                  width: 340,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(pain['icon'] as IconData, color: Colors.red, size: 32),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        pain['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pain['desc'] as String,
                        style: const TextStyle(color: Color(0xFF6C757D), fontSize: 17, height: 1.4),
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
    {'icon': Icons.auto_awesome, 'title': 'AI Invoicing', 'desc': '"Create invoice for Ahmed 300 AED" → done in 10 seconds'},
    {'icon': Icons.group, 'title': 'Team Dispatch', 'desc': 'Assign jobs, track location, and see live availability'},
    {'icon': Icons.language, 'title': '9 Languages', 'desc': 'EN/FR/AR/IT/DE/ES/MT + Arabic dialects'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Column(
        children: [
          Text(
            'Everything You Need, Nothing You Don\'t',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            children: features.map((feature) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 120) / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(feature['icon'] as IconData, color: const Color(0xFF0066FF), size: 36),
                          const SizedBox(height: 16),
                          Text(
                            feature['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            feature['desc'] as String,
                            style: const TextStyle(color: Color(0xFF6C757D), fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      color: Colors.grey[50],
      child: Column(
        children: [
          Text(
            'Trusted by 500+ Trades Across 12 Countries',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TestimonialCard(
                name: 'Ahmed K.',
                role: 'Plumber, Dubai',
                quote: 'Invoices in Arabic? Yes! Got paid 2x faster.',
                color: const Color(0xFF0066FF),
              ),
              const SizedBox(width: 30),
              _TestimonialCard(
                name: 'Jean P.',
                role: 'Electrician, Paris',
                quote: 'Finally, a CRM that doesn\'t look like accounting software.',
                color: const Color(0xFFFF6600),
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
      width: 360,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.person, color: color, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                  Text(role, style: const TextStyle(color: Color(0xFF6C757D), fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '"$quote"',
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 18, height: 1.5),
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF0066FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Ditch Spreadsheets Forever?',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Join 500+ trades saving 10+ hours/week with EU-hosted, zero-tracking infrastructure.',
            style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/sign-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0066FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
              ),
              child: const Text('Start Free Trial →'),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            '🔒 GDPR Compliant • No Credit Card • Cancel Anytime',
            style: TextStyle(color: Colors.white70, fontSize: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFFFF6600)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.construction, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                'AuraSphere CRM',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0066FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Sovereign CRM for tradespeople — EU-hosted, zero tracking, GDPR compliant',
            style: TextStyle(color: Color(0xFF6C757D), fontSize: 16),
          ),
          const SizedBox(height: 35),
          Wrap(
            spacing: 40,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: [
              _FooterLink('Privacy Policy', 'https://aura-sphere.app/privacy'),
              _FooterLink('Terms of Service', 'https://aura-sphere.app/terms'),
              _FooterLink('GDPR Compliance', 'https://aura-sphere.app/gdpr'),
              _FooterLink('Support', 'https://aura-sphere.app/support'),
            ],
          ),
          const SizedBox(height: 35),
          const Text(
            'Operated by Black Diamond LTD (UIC: 207807571), Sofia, Bulgaria',
            style: TextStyle(color: Color(0xFF6C757D), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final String url;
  const _FooterLink(this.text, this.url);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _launchURL(url),
      child: Text(text, style: const TextStyle(color: Color(0xFF0066FF), fontSize: 16)),
    );
  }
}

Future<void> _launchURL(String url) async {
  // For web, this can be a no-op or use JS interop
}
