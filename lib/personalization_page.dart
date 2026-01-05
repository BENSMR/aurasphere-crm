import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/feature_personalization_service.dart';
import 'services/white_label_service.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  final featureService = FeaturePersonalizationService();
  final whiteLabelService = WhiteLabelService();

  List<Map<String, dynamic>> allFeatures = [];
  List<String> selectedMobileFeatures = [];
  List<String> selectedTabletFeatures = [];
  
  // White-label settings
  String? logoUrl;
  String primaryColor = '#007BFF';
  String secondaryColor = '#6C757D';
  String accentColor = '#28A745';
  bool watermarkEnabled = false;
  String watermarkText = 'AuraSphere CRM';

  bool loading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Load all features
      allFeatures = featureService.getAllAvailableFeatures();

      // Load mobile features
      final mobileFeatures = await featureService.getPersonalizedFeatures(
        userId: userId!,
        deviceType: 'mobile',
      );
      selectedMobileFeatures =
          mobileFeatures.map((f) => f['id'] as String).toList();

      // Load tablet features
      final tabletFeatures = await featureService.getPersonalizedFeatures(
        userId: userId!,
        deviceType: 'tablet',
      );
      selectedTabletFeatures =
          tabletFeatures.map((f) => f['id'] as String).toList();

      // Load white-label settings
      final orgId = await _getOrgId();
      if (orgId != null) {
        final settings = await whiteLabelService.getWhiteLabelSettings(orgId);
        logoUrl = settings['logo_url'];
        primaryColor = settings['primary_color'] ?? '#007BFF';
        secondaryColor = settings['secondary_color'] ?? '#6C757D';
        accentColor = settings['accent_color'] ?? '#28A745';
        watermarkEnabled = settings['watermark_enabled'] ?? false;
        watermarkText = settings['watermark_text'] ?? 'AuraSphere CRM';
      }

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      print('❌ Error initializing: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> _getOrgId() async {
    try {
      final result = await supabase
          .from('org_members')
          .select('org_id')
          .eq('user_id', userId!)
          .maybeSingle();
      return result?['org_id'];
    } catch (e) {
      print('❌ Error getting org ID: $e');
      return null;
    }
  }

  Future<void> _toggleFeature(String featureId, bool isMobile) async {
    try {
      final deviceType = isMobile ? 'mobile' : 'tablet';
      await featureService.toggleFeature(
        userId: userId!,
        deviceType: deviceType,
        featureId: featureId,
      );

      if (isMobile) {
        final features = await featureService.getPersonalizedFeatures(
          userId: userId!,
          deviceType: 'mobile',
        );
        setState(() {
          selectedMobileFeatures =
              features.map((f) => f['id'] as String).toList();
        });
      } else {
        final features = await featureService.getPersonalizedFeatures(
          userId: userId!,
          deviceType: 'tablet',
        );
        setState(() {
          selectedTabletFeatures =
              features.map((f) => f['id'] as String).toList();
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feature ${isMobile ? 'mobile' : 'tablet'} updated')),
        );
      }
    } catch (e) {
      print('❌ Error toggling feature: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateColor(String colorType, String newColor) async {
    try {
      final orgId = await _getOrgId();
      if (orgId == null) return;

      String primaryCol = colorType == 'primary' ? newColor : primaryColor;
      String secondaryCol =
          colorType == 'secondary' ? newColor : secondaryColor;
      String accentCol = colorType == 'accent' ? newColor : accentColor;

      await whiteLabelService.updateBrandColors(
        orgId: orgId,
        primaryColor: primaryCol,
        secondaryColor: secondaryCol,
        accentColor: accentCol,
      );

      setState(() {
        if (colorType == 'primary') primaryColor = newColor;
        if (colorType == 'secondary') secondaryColor = newColor;
        if (colorType == 'accent') accentColor = newColor;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Color updated')),
        );
      }
    } catch (e) {
      print('❌ Error updating color: $e');
    }
  }

  Future<void> _toggleWatermark() async {
    try {
      final orgId = await _getOrgId();
      if (orgId == null) return;

      await whiteLabelService.updateWatermark(
        orgId: orgId,
        enabled: !watermarkEnabled,
        watermarkText: watermarkText,
        opacity: 0.1,
      );

      setState(() => watermarkEnabled = !watermarkEnabled);
    } catch (e) {
      print('❌ Error toggling watermark: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalization'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.phone_android), text: 'Mobile Features'),
            Tab(icon: Icon(Icons.palette), text: 'Branding'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Mobile Features Tab
          _buildFeaturesTab('mobile'),
          
          // Branding Tab
          _buildBrandingTab(),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(String deviceType) {
    final selected = deviceType == 'mobile' ? selectedMobileFeatures : selectedTabletFeatures;
    final maxFeatures = deviceType == 'mobile'
        ? FeaturePersonalizationService.MOBILE_MAX_FEATURES
        : FeaturePersonalizationService.TABLET_MAX_FEATURES;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Features',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select up to $maxFeatures features to display on your ${deviceType == 'mobile' ? 'phone' : 'tablet'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selected: ${selected.length}/$maxFeatures',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected.length <= maxFeatures
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Features by category
        ...featureService.getAllCategories().map((category) {
          final categoryFeatures = featureService.getFeaturesByCategory(category);
          return ExpansionTile(
            title: Text(category.toUpperCase()),
            children: categoryFeatures.map((feature) {
              final isSelected = selected.contains(feature['id']);
              return CheckboxListTile(
                title: Text(feature['name']),
                subtitle: Text(feature['description']),
                value: isSelected,
                onChanged: (value) async {
                  if (value == true && selected.length >= maxFeatures) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Max $maxFeatures features allowed'),
                        ),
                      );
                    }
                    return;
                  }
                  await _toggleFeature(feature['id'] as String, deviceType == 'mobile');
                },
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildBrandingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Logo Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (logoUrl != null)
                  Image.network(
                    logoUrl!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    // TODO: Implement image picker and upload
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image upload coming soon')),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Logo'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Colors Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brand Colors',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildColorPickerRow('Primary Color', primaryColor, 'primary'),
                const SizedBox(height: 12),
                _buildColorPickerRow(
                    'Secondary Color', secondaryColor, 'secondary'),
                const SizedBox(height: 12),
                _buildColorPickerRow('Accent Color', accentColor, 'accent'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Watermark Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invoice Watermark',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Switch(
                      value: watermarkEnabled,
                      onChanged: (_) => _toggleWatermark(),
                    ),
                  ],
                ),
                if (watermarkEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: TextEditingController(text: watermarkText),
                      decoration: InputDecoration(
                        hintText: 'Watermark text',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        watermarkText = value;
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerRow(String label, String color, String type) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: _hexToColor(color),
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            // TODO: Implement color picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Color picker coming soon')),
            );
          },
          child: const Text('Pick'),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }
}
