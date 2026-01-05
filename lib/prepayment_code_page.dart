import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/prepayment_code_service.dart';

class PrepaymentCodePage extends StatefulWidget {
  final String? detectedCountryCode; // Auto-detected region (optional)
  final VoidCallback onCodeRedeemed; // Callback after successful redemption

  const PrepaymentCodePage({
    super.key,
    this.detectedCountryCode,
    required this.onCodeRedeemed,
  });

  @override
  State<PrepaymentCodePage> createState() => _PrepaymentCodePageState();
}

class _PrepaymentCodePageState extends State<PrepaymentCodePage> {
  late TextEditingController _codeController;
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _codeDetails;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final codeService = PrepaymentCodeService();
      final validation = await codeService.validateCode(_codeController.text.trim());

      if (!validation['valid']) {
        setState(() {
          _errorMessage = validation['error'];
          _codeDetails = null;
        });
      } else {
        final data = validation['data'];
        setState(() {
          _codeDetails = {
            'planId': data['plan_id'],
            'region': data['region'],
            'price': data['price'],
            'duration': data['subscription_duration'],
            'expiresOn': data['expiresOn'],
          };
          _successMessage = 'Code is valid! ${data['plan_id'].toString().toUpperCase()} Plan for ${data['subscription_duration']} month(s)';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating code: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _redeemCode() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _errorMessage = 'User not authenticated');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final codeService = PrepaymentCodeService();
      final result = await codeService.redeemCode(
        code: _codeController.text.trim(),
        userId: userId,
      );

      setState(() {
        _successMessage = result['message'];
        _codeDetails = null;
      });

      // Wait 1 second, then callback to parent
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        widget.onCodeRedeemed();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error redeeming code: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Prepayment Code'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Activate Your Plan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your prepayment code to activate your subscription',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // Region info (if detected)
                if (widget.detectedCountryCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Region detected: ${_getRegionName(widget.detectedCountryCode!)}',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Code input field
                TextField(
                  controller: _codeController,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    labelText: 'Prepayment Code',
                    hintText: 'e.g., AURA-TUN-2024-ABC123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.card_giftcard),
                    suffixIcon: _codeController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _codeController.clear();
                              setState(() {
                                _codeDetails = null;
                                _errorMessage = null;
                              });
                            },
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Validate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading || _codeController.text.isEmpty
                        ? null
                        : _validateCode,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Validate Code'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Success message
                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Code details card
                if (_codeDetails != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Plan', _getDisplayName(_codeDetails!['planId'])),
                          _buildDetailRow('Price', '\$${_codeDetails!['price'].toStringAsFixed(2)}'),
                          _buildDetailRow('Duration', '${_codeDetails!['duration']} month(s)'),
                          _buildDetailRow('Region', _getRegionName(_codeDetails!['region'])),
                          _buildDetailRow('Valid Until', _formatDate(_codeDetails!['expiresOn'])),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _redeemCode,
                              icon: const Icon(Icons.check_circle),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Activate Plan'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Help section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need a code?',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Contact our support team to request a prepayment code for your region.',
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getRegionName(String code) {
    // Use region names from service
    return PrepaymentCodeService.regionNames[code.toUpperCase()] ?? code;
  }

  String _getDisplayName(String planId) {
    const names = {
      'solo': 'Solo - \$9.99/month',
      'team': 'Team - \$15.00/month',
      'workshop': 'Workshop - \$29.00/month',
    };
    return names[planId] ?? planId;
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
