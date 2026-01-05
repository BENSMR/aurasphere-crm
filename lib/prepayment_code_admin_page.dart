import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/prepayment_code_service.dart';

class PrepaymentCodeAdminPage extends StatefulWidget {
  const PrepaymentCodeAdminPage({super.key});

  @override
  State<PrepaymentCodeAdminPage> createState() => _PrepaymentCodeAdminPageState();
}

class _PrepaymentCodeAdminPageState extends State<PrepaymentCodeAdminPage> {
  late TextEditingController _quantityController;
  String _selectedPlan = 'solo';
  String _selectedRegion = 'TN';
  String _selectedDuration = '12months'; // NEW: Duration selector
  int _expiryDays = 365;
  bool _loading = false;
  String? _message;
  List<String> _generatedCodes = [];
  Map<String, dynamic>? _stats;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '10');
    _loadStats();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final codeService = PrepaymentCodeService();
      final stats = await codeService.getCodeStats(userId);

      setState(() => _stats = stats);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
    }
  }

  Future<void> _generateCodes() async {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      setState(() => _message = 'Enter a valid quantity');
      return;
    }

    if (quantity > 500) {
      setState(() => _message = 'Maximum 500 codes per batch');
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _message = 'Not authenticated');
      return;
    }

    setState(() => _loading = true);

    try {
      final codeService = PrepaymentCodeService();
      final codes = await codeService.generateCodes(
        planId: _selectedPlan,
        quantity: quantity,
        region: _selectedRegion,
        duration: _selectedDuration, // NEW: Pass duration
        expiryDays: _expiryDays,
        generatedBy: userId,
      );

      setState(() {
        _generatedCodes = codes;
        _message = '✅ Generated $quantity codes successfully!';
      });

      _loadStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codes generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _message = '❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _copyToClipboard() {
    final text = _generatedCodes.join('\n');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Codes copied to clipboard')),
    );
    // Note: Use flutter/services Clipboard in production
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepayment Code Generator'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats section
            if (_stats != null) ...[
              Text(
                'Code Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: isMobile ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard('Total', _stats!['total'].toString(), Colors.blue),
                  _buildStatCard('Active', _stats!['active'].toString(), Colors.green),
                  _buildStatCard('Redeemed', _stats!['redeemed'].toString(), Colors.orange),
                  _buildStatCard('Expired', _stats!['expired'].toString(), Colors.red),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Generator section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate New Codes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Plan selection
                    Text('Plan', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(label: Text('Solo'), value: 'solo'),
                        ButtonSegment(label: Text('Team'), value: 'team'),
                        ButtonSegment(label: Text('Workshop'), value: 'workshop'),
                      ],
                      selected: {_selectedPlan},
                      onSelectionChanged: (selected) {
                        setState(() => _selectedPlan = selected.first);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Region selection (UPDATED - All African regions)
                    Text('Region / Country', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _buildRegionSelector(),
                    const SizedBox(height: 24),

                    // Duration selection (NEW)
                    Text('Subscription Duration',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(label: Text('1 Month'), value: '1month'),
                        ButtonSegment(label: Text('3 Months'), value: '3months'),
                        ButtonSegment(label: Text('6 Months'), value: '6months'),
                        ButtonSegment(label: Text('1 Year'), value: '12months'),
                      ],
                      selected: {_selectedDuration},
                      onSelectionChanged: (selected) {
                        setState(() => _selectedDuration = selected.first);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quantity input
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'Number of codes to generate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: 'codes',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Expiry selection
                    Text('Valid For', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Slider(
                      value: _expiryDays.toDouble(),
                      min: 30,
                      max: 730,
                      divisions: 14,
                      label: '$_expiryDays days',
                      onChanged: (value) {
                        setState(() => _expiryDays = value.toInt());
                      },
                    ),
                    Text(
                      'Expires in $_expiryDays days (${DateTime.now().add(Duration(days: _expiryDays)).toString().split(' ')[0]})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _generateCodes,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Generate Codes'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message
            if (_message != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message!.startsWith('✅')
                      ? Colors.green[50]
                      : Colors.red[50],
                  border: Border.all(
                    color: _message!.startsWith('✅')
                        ? Colors.green[300]!
                        : Colors.red[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('✅')
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Generated codes display
            if (_generatedCodes.isNotEmpty) ...[
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
                            'Generated Codes (${_generatedCodes.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          _generatedCodes.join('\n'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '⚠️ Save these codes. They cannot be recovered if lost.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build region selector with grouped continents
  Widget _buildRegionSelector() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: PrepaymentCodeService.regionsByContinent.entries
            .map((continent) {
          final regions = continent.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  continent.key,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: regions
                      .map((region) {
                        final isSelected = _selectedRegion == region;
                        final displayName =
                            PrepaymentCodeService.regionNames[region] ??
                                region;
                        return FilterChip(
                          label: Text(displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedRegion = region);
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.blue[100],
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue[700]!
                                : Colors.transparent,
                            width: 2,
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }}