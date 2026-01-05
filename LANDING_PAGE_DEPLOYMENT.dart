import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool isAnnualBilling = false;

  // Brand colors
  static const Color electricBlue = Color(0xFF007BFF);
  static const Color goldYellow = Color(0xFFFFD700);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1F2937);
  static const Color lightGray = Color(0xFFF3F4F6);

  final whatsappNumber = '+359892123456'; // Replace with your WhatsApp number

  Future<void> _launchWhatsApp() async {
    final message = Uri.encodeComponent(
      'Hi! I\'m interested in AuraSphere CRM. Can you tell me more?',
    );
    final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$message';
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _navigateToRoute(String route) async {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(isMobile),
            _buildTrialBanner(),
            _buildFeaturesSection(isMobile),
            _buildBusinessIdentitySection(isMobile),
            _buildPricingSection(isMobile),
            _buildEcosystemSection(isMobile),
            _buildTestimonialSection(isMobile),
            _buildFinalCTASection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===== APP BAR =====
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: white,
      elevation: 1,
      shadowColor: Colors.black12,
      title: Row(
        children: [
          const Icon(Icons.business, color: electricBlue, size: 28),
          const SizedBox(width: 8),
          const Text(
            'AuraSphere CRM',
            style: TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _navigateToRoute('/sign-in'),
          icon: const Icon(Icons.login, color: electricBlue),
          label: const Text(
            'Sign In',
            style: TextStyle(color: electricBlue, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => _navigateToRoute('/sign-up'),
          style: FilledButton.styleFrom(
            backgroundColor: electricBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Create Account'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ===== HERO SECTION =====
  Widget _buildHeroSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: isMobile ? 40 : 80,
      ),
      color: lightGray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Your Business, Professionally Yours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 48,
              fontWeight: FontWeight.bold,
              color: darkText,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Get your own yourbusiness.online — a real domain you own forever. Plus professional email, job management, invoicing, and real-time team sync.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: () => _navigateToRoute('/sign-up'),
                style: FilledButton.styleFrom(
                  backgroundColor: electricBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Start Free Trial',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton(
                onPressed: _launchWhatsApp,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: electricBlue, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.message, color: electricBlue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Message on WhatsApp',
                      style: TextStyle(
                        color: electricBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== TRIAL BANNER =====
  Widget _buildTrialBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFFEF3C7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard, color: emeraldGreen, size: 24),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              '7-Day Free Trial - No Credit Card Required',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FEATURES SECTION =====
  Widget _buildFeaturesSection(bool isMobile) {
    final features = [
      {
        'icon': Icons.business_center,
        'title': 'Business Identity',
        'description': 'Real domain, professional email, branded website',
      },
      {
        'icon': Icons.message,
        'title': 'WhatsApp Integration',
        'description': '1-tap messaging with clients and team members',
      },
      {
        'icon': Icons.assignment,
        'title': 'Job Management',
        'description': 'Create, track, and complete jobs efficiently',
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Advanced Invoicing',
        'description': 'Professional invoices with automatic calculations',
      },
      {
        'icon': Icons.people,
        'title': 'Client Hub',
        'description': 'Centralized client database and communication',
      },
      {
        'icon': Icons.sync,
        'title': 'Real-Time Sync',
        'description': 'Live updates across all devices and team members',
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 60,
      ),
      child: Column(
        children: [
          const Text(
            'Everything You Need',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        feature['icon'] as IconData,
                        color: electricBlue,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature['description'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== BUSINESS IDENTITY SECTION =====
  Widget _buildBusinessIdentitySection(bool isMobile) {
    final items = [
      {
        'icon': Icons.language,
        'title': 'Real Domain',
        'description': 'yourbusiness.online - a domain you own forever',
      },
      {
        'icon': Icons.mail,
        'title': 'Professional Email',
        'description': '3-5 professional email addresses included',
      },
      {
        'icon': Icons.web,
        'title': 'Branded Website',
        'description': 'Simple website to showcase your services',
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 60,
      ),
      color: lightGray,
      child: Column(
        children: [
          const Text(
            'Build Your Business Identity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                color: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: emeraldGreen,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['description'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== PRICING SECTION =====
  Widget _buildPricingSection(bool isMobile) {
    final plans = [
      {
        'name': 'CRM Solo',
        'monthlyPrice': 9.99,
        'annualPrice': 99.99,
        'users': 1,
        'jobs': '25/month',
        'popular': false,
        'features': [
          'Real domain (yourbusiness.online)',
          '1-3 professional emails',
          'Job management',
          'Basic invoicing',
          'Client database',
          'Single user',
        ],
      },
      {
        'name': 'CRM Team',
        'monthlyPrice': 15,
        'annualPrice': 126,
        'users': 3,
        'jobs': '60/month',
        'popular': true,
        'features': [
          'Real domain (yourbusiness.online)',
          '3-5 professional emails',
          'Job management & dispatch',
          'Advanced invoicing',
          'Client database',
          'Up to 3 users',
          'Team collaboration',
          'Real-time sync',
        ],
      },
      {
        'name': 'CRM Workshop',
        'monthlyPrice': 29.99,
        'annualPrice': 299.99,
        'users': 7,
        'jobs': 'Unlimited',
        'popular': false,
        'features': [
          'Real domain (yourbusiness.online)',
          '5+ professional emails',
          'Job management & dispatch',
          'Advanced invoicing',
          'Client database',
          'Up to 7 users',
          'Team collaboration',
          'Real-time sync',
          'Priority support',
        ],
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 60,
      ),
      child: Column(
        children: [
          const Text(
            'Simple, Transparent Pricing',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 20),
          // Billing toggle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => setState(() => isAnnualBilling = false),
                  style: TextButton.styleFrom(
                    backgroundColor: !isAnnualBilling ? white : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'Monthly',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !isAnnualBilling ? electricBlue : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => isAnnualBilling = true),
                  style: TextButton.styleFrom(
                    backgroundColor: isAnnualBilling ? white : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'Annual (Save 30%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isAnnualBilling ? emeraldGreen : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Plan cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.9,
            ),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index] as Map<String, dynamic>;
              final price = isAnnualBilling ? plan['annualPrice'] : plan['monthlyPrice'];
              return _buildPricingCard(plan, price);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> plan, dynamic price) {
    final isPopular = plan['popular'] as bool;
    return Stack(
      children: [
        Card(
          elevation: isPopular ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPopular
                ? const BorderSide(color: goldYellow, width: 2)
                : const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          color: isPopular ? const Color(0xFFFFFBF0) : white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: electricBlue,
                        ),
                      ),
                      TextSpan(
                        text: isAnnualBilling ? '/year' : '/month',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${plan['users']} user${plan['users'] > 1 ? 's' : ''} • ${plan['jobs']} jobs',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _navigateToRoute('/sign-up'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isPopular ? goldYellow : electricBlue,
                    foregroundColor: isPopular ? darkText : white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (plan['features'] as List).length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check, color: emeraldGreen, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (plan['features'] as List)[index] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  height: 1.3,
                                ),
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
        ),
        if (isPopular)
          Positioned(
            top: -12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: goldYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ===== ECOSYSTEM SECTION =====
  Widget _buildEcosystemSection(bool isMobile) {
    final products = [
      {
        'name': 'AuraPost',
        'price': '\$6/mo',
        'description': 'Social media content scheduler',
        'icon': Icons.schedule,
      },
      {
        'name': 'AuraLink',
        'price': '\$5/mo',
        'description': 'Link shortener & analytics',
        'icon': Icons.link,
      },
      {
        'name': 'AuraShield',
        'price': '\$5/mo',
        'description': 'Data security & backups',
        'icon': Icons.shield,
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 60,
      ),
      color: lightGray,
      child: Column(
        children: [
          const Text(
            'The AuraSphere Ecosystem',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Extend your business with add-on products',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.1,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 0,
                color: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        product['icon'] as IconData,
                        color: electricBlue,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['price'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: electricBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product['description'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== TESTIMONIAL SECTION =====
  Widget _buildTestimonialSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 60,
      ),
      child: Column(
        children: [
          const Text(
            'Trusted by Professionals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 40),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Column(
                children: [
                  const Text(
                    '"Before AuraSphere, I was just a name in a chat. Now I\'m a legitimate business with my own domain, professional email, and organized job management. My clients take me seriously, and I take myself seriously too."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkText,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Maria K.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const Text(
                    'Electrical Contractor, Sofia',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FINAL CTA SECTION =====
  Widget _buildFinalCTASection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [goldYellow, electricBlue],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Ready to Take Your Business Professional?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join hundreds of professionals already using AuraSphere CRM',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: white,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => _navigateToRoute('/sign-up'),
            style: FilledButton.styleFrom(
              backgroundColor: white,
              foregroundColor: electricBlue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Start Your 7-Day Free Trial',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FOOTER =====
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: darkText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Built by Black Diamond LTD',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sofia, Bulgaria • UIC: 2078007571',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'We build ethical, privacy-first tools for freelancers and professionals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFD1D5DB),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => launchUrl(Uri.parse('https://aura-sphere.app/privacy')),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                ),
              ),
              const Text(' • ', style: TextStyle(color: Color(0xFFD1D5DB))),
              TextButton(
                onPressed: () => launchUrl(Uri.parse('https://aura-sphere.app/terms')),
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                ),
              ),
              const Text(' • ', style: TextStyle(color: Color(0xFFD1D5DB))),
              TextButton(
                onPressed: () => launchUrl(Uri.parse('https://aura-sphere.app/contact')),
                child: const Text(
                  'Contact',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
