import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/feature_personalization_service.dart';

class FeaturePersonalizationPage extends StatefulWidget {
  const FeaturePersonalizationPage({super.key});

  @override
  State<FeaturePersonalizationPage> createState() =>
      _FeaturePersonalizationPageState();
}

class _FeaturePersonalizationPageState extends State<FeaturePersonalizationPage> {
  final supabase = Supabase.instance.client;
  final personalizationService = FeaturePersonalizationService();

  late String selectedDeviceType = 'mobile';
  late List<Map<String, dynamic>> selectedFeatures = [];
  late List<Map<String, dynamic>> availableFeatures = [];
  late int maxFeatures = FeaturePersonalizationService.MOBILE_MAX_FEATURES;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  Future<void> _loadFeatures() async {
    setState(() => loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final features = await personalizationService.getPersonalizedFeatures(
        userId: userId,
        deviceType: selectedDeviceType,
      );

      maxFeatures = selectedDeviceType == 'mobile'
          ? FeaturePersonalizationService.MOBILE_MAX_FEATURES
          : FeaturePersonalizationService.TABLET_MAX_FEATURES;

      setState(() {
        selectedFeatures = features;
        availableFeatures = personalizationService.getAllAvailableFeatures();
        loading = false;
      });
    } catch (e) {
      print('❌ Error loading features: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _saveChanges() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final featureIds = selectedFeatures.map((f) => f['id'] as String).toList();
      
      await personalizationService.savePersonalizedFeatures(
        userId: userId,
        deviceType: selectedDeviceType,
        selectedFeatureIds: featureIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Features saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await personalizationService.resetToDefaults(
        userId: userId,
        deviceType: selectedDeviceType,
      );

      await _loadFeatures();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Reset to defaults')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  void _toggleFeature(Map<String, dynamic> feature) {
    final featureId = feature['id'] as String;
    final isSelected = selectedFeatures.any((f) => f['id'] == featureId);

    setState(() {
      if (isSelected) {
        selectedFeatures.removeWhere((f) => f['id'] == featureId);
      } else {
        if (selectedFeatures.length < maxFeatures) {
          selectedFeatures.add(feature);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Max $maxFeatures features allowed'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _reorderFeatures(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = selectedFeatures.removeAt(oldIndex);
      selectedFeatures.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    print('Screen width: $screenWidth, isMobile: $isMobile');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Features'),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Type Selector
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device Type',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'mobile',
                                      label: Text('📱 Mobile (Max 8)'),
                                    ),
                                    ButtonSegment(
                                      value: 'tablet',
                                      label: Text('📱 Tablet (Max 12)'),
                                    ),
                                  ],
                                  selected: {selectedDeviceType},
                                  onSelectionChanged: (newSelection) {
                                    setState(() {
                                      selectedDeviceType = newSelection.first;
                                      _loadFeatures();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature Counter
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected: ${selectedFeatures.length} / $maxFeatures',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (selectedFeatures.length < maxFeatures)
                            Text(
                              '${maxFeatures - selectedFeatures.length} slots available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selected Features (Reorderable)
                  if (selectedFeatures.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Features (Drag to Reorder)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: _reorderFeatures,
                          children: [
                            for (int i = 0; i < selectedFeatures.length; i++)
                              _buildSelectedFeatureCard(
                                selectedFeatures[i],
                                i,
                                key: ValueKey(selectedFeatures[i]['id']),
                              ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Available Features
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCategories(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _resetToDefaults,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Defaults'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveChanges,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectedFeatureCard(
    Map<String, dynamic> feature,
    int index, {
    required Key key,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text('${index + 1}. ${feature['name']}'),
        subtitle: Text(feature['description'] as String),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _toggleFeature(feature),
        ),
      ),
    );
  }

  Widget _buildFeatureCategories() {
    final categories = personalizationService.getAllCategories();
    final selectedIds = selectedFeatures.map((f) => f['id']).toSet();

    return Column(
      children: [
        for (final category in categories)
          _buildCategorySection(category, selectedIds),
      ],
    );
  }

  Widget _buildCategorySection(String category, Set<dynamic> selectedIds) {
    final features = personalizationService.getFeaturesByCategory(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final feature in features)
              _buildFeatureChip(feature, selectedIds.contains(feature['id'])),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(
    Map<String, dynamic> feature,
    bool isSelected,
  ) {
    return FilterChip(
      label: Text(feature['name'] as String),
      selected: isSelected,
      onSelected: (_) => _toggleFeature(feature),
      avatar: isSelected
          ? const Icon(Icons.check_circle)
          : null,
      backgroundColor: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
      selectedColor: Colors.blue.shade300,
    );
  }
}
