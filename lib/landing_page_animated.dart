import 'package:flutter/material.dart';

class LandingPageAnimated extends StatefulWidget {
  const LandingPageAnimated({super.key});

  @override
  State<LandingPageAnimated> createState() => _LandingPageAnimatedState();
}

class _LandingPageAnimatedState extends State<LandingPageAnimated> with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final Animation<double> _heroOpacity;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _heroOpacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _HeaderSection(),
                _HeroSection(opacity: _heroOpacity),
                _CoreOfferSection(),
                _FeaturesSection(),
                _SyncSection(),
                _PricingSection(),
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

// ================== HEADER SECTION ==================
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 100 : 24,
        vertical: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.work, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Text(
                'AuraSphere CRM',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF007BFF),
                ),
              ),
            ],
          ),
          // Auth Links
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                child: const Text('Sign In', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================== HERO SECTION ==================
class _HeroSection extends StatelessWidget {
  final Animation<double> opacity;

  const _HeroSection({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: opacity,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 600 ? 100 : 24,
            vertical: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width > 800 ? 700 : double.infinity,
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, height: 1.05),
                    children: [
                      TextSpan(text: 'Your Business, ', style: const TextStyle(color: Colors.black)),
                      TextSpan(text: 'Professionally Yours.', style: const TextStyle(color: Color(0xFF007BFF))),
                    ],
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width > 800 ? 650 : double.infinity,
                child: Text(
                  'AuraSphere gives you a real business identity — your own website, professional email, and full CRM — all with real-time sync across mobile and desktop.',
                  style: const TextStyle(fontSize: 20, color: Color(0xFF495057), height: 1.5),
                ),
              ),
              const SizedBox(height: 40),
              
              // Trial Banner - GOLD & GREEN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '✨ 7-Day Free Trial - No Credit Card Required',
                      style: TextStyle(
                        fontSize: 19,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              
              // Primary CTA - ELECTRIC BLUE
              SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Start Free Trial →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================== CORE OFFER SECTION ==================
class _CoreOfferSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Text(
            'We Build Your Professional Business Identity',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF007BFF)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Every subscription includes your own website and professional email — at no extra cost.',
            style: TextStyle(fontSize: 19, color: Color(0xFF495057)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 70),
          
          // Core Offer Cards
          SizedBox(
            height: 400,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CoreCard(
                  title: 'Your Website',
                  content: 'Complete contact site with:\n• Google Maps\n• WhatsApp button\n• Business info\n• Mobile-optimized',
                  color: const Color(0xFF007BFF),
                  icon: Icons.language,
                ),
                const SizedBox(width: 30),
                _CoreCard(
                  title: 'Professional Email',
                  content: 'Your own email addresses:\n• contact@yourbusiness.online\n• jobs@yourbusiness.online\n• invoices@yourbusiness.online',
                  color: const Color(0xFFFFD700),
                  icon: Icons.mail,
                ),
                const SizedBox(width: 30),
                _CoreCard(
                  title: 'Full CRM Suite',
                  content: 'Complete business management:\n• Job tracking\n• Invoicing\n• Client management\n• Team collaboration',
                  color: const Color(0xFF10B981),
                  icon: Icons.dashboard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoreCard extends StatelessWidget {
  final String title, content;
  final Color color;
  final IconData icon;

  const _CoreCard({
    required this.title,
    required this.content,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(fontSize: 17, color: Color(0xFF495057), height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ================== FEATURES SECTION ==================
class _FeaturesSection extends StatelessWidget {
  final mobileFeatures = const [
    'Manage all business contacts',
    'Organize tasks & deadlines',
    'Scan receipts with OCR',
    'Track wallet & transactions',
    'Control ecosystem & integrations',
    'Real-time analytics & insights',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Column(
        children: [
          const Text(
            '📱 Best Features on Mobile • 💻 Full Suite on Desktop',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF007BFF)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Work anywhere — your business follows you.',
            style: TextStyle(fontSize: 19, color: Color(0xFF495057)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 70),
          
          // Mobile Features List
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '📱 MOBILE - 6 Best Features',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF007BFF)),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    itemCount: mobileFeatures.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                mobileFeatures[index],
                                style: const TextStyle(fontSize: 18, color: Color(0xFF495057)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== SYNC SECTION ==================
class _SyncSection extends StatelessWidget {
  final syncFeatures = const [
    '✅ All data synced real-time across mobile, tablet, and desktop',
    '✅ Log expense on phone → See on desktop instantly',
    '✅ Update invoice on desktop → Visible on mobile instantly',
    '✅ Multiple users editing → All changes sync automatically',
    '✅ Mobile works offline → Auto-syncs when reconnected',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6F0FF), Color(0xFF007BFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '✨ Unified Platform Features',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: MediaQuery.of(context).size.width > 600 ? 800 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: syncFeatures.map((feature) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.sync, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== PRICING SECTION ==================
class _PricingSection extends StatelessWidget {
  final plans = const [
    {
      'name': 'Solo Tradesperson',
      'price': '\$9.99',
      'desc': 'Up to 1 member',
      'features': [
        '1 WhatsApp number',
        '25 jobs/month',
        'Full CRM suite',
        '5 AI agents',
        'OCR receipt scanning',
        'Multi-currency + tax',
        'yourbusiness.online',
        '3 professional emails'
      ],
    },
    {
      'name': 'Small Team',
      'price': '\$15',
      'desc': 'Up to 3 team members',
      'features': [
        '3 WhatsApp numbers',
        '60 jobs/month',
        'Team collaboration',
        '5 AI agents',
        'OCR receipt scanning',
        'Multi-currency + tax',
        'yourbusiness.shop',
        '3 professional emails'
      ],
      'popular': true,
    },
    {
      'name': 'Workshop',
      'price': '\$29',
      'desc': 'Up to 7 team members',
      'features': [
        '7 WhatsApp numbers',
        'Unlimited jobs',
        'Advanced analytics',
        '5 AI agents',
        'OCR receipt scanning',
        'Multi-currency + tax',
        'yourbusiness.pro',
        '5 professional emails'
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Column(
        children: [
          const Text(
            'Subscription Plans',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'All plans include: 7-day trial, business identity, real-time sync, offline mobile',
            style: TextStyle(fontSize: 19, color: Color(0xFF495057)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
          SizedBox(
            height: 600,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                final isPopular = (plan['popular'] as bool?) == true;
                return Container(
                  width: 340,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'MOST POPULAR',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _PricingCard(
                        name: plan['name'] as String,
                        price: plan['price'] as String,
                        desc: plan['desc'] as String,
                        features: List<String>.from(plan['features'] as List),
                        isPopular: isPopular,
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

class _PricingCard extends StatelessWidget {
  final String name, price, desc;
  final List<String> features;
  final bool isPopular;

  const _PricingCard({
    required this.name,
    required this.price,
    required this.desc,
    required this.features,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
          border: isPopular
              ? Border.all(color: const Color(0xFFFFD700), width: 2.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isPopular ? const Color(0xFFFFD700) : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(desc, style: const TextStyle(color: Color(0xFF6C757D), fontSize: 16)),
              const SizedBox(height: 26),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const TextSpan(
                      text: '/month',
                      style: TextStyle(fontSize: 18, color: Color(0xFF6C757D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Flexible(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(feature, style: const TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Start Free Trial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
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
          colors: [Color(0xFFFFD700), Color(0xFF007BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            'Get Started Now',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Work on your phone. Access full power on desktop. Everything syncs automatically.',
            style: TextStyle(color: Colors.black87, fontSize: 19, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('📱 Access App', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/feature-personalization'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('⚙️ Customize Layout', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            '✅ 7-day free trial • No credit card required • Cancel anytime',
            style: TextStyle(color: Colors.black87, fontSize: 16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.work, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              const Text(
                'AuraSphere CRM',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Professional business identity for independent professionals — with real-time sync across all devices',
            style: TextStyle(color: Color(0xFF495057), fontSize: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                child: const Text('Sign In', style: TextStyle(color: Color(0xFF495057), fontSize: 16)),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF495057), fontSize: 16)),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/sign-up'),
                child: const Text('Create Account', style: TextStyle(color: Color(0xFF495057), fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
