import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoicePersonalizationPage extends StatefulWidget {
  const InvoicePersonalizationPage({super.key});

  @override
  State<InvoicePersonalizationPage> createState() =>
      _InvoicePersonalizationPageState();
}

class _InvoicePersonalizationPageState extends State<InvoicePersonalizationPage> {
  final supabase = Supabase.instance.client;
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _invoiceNoteController = TextEditingController();

  bool _showWatermark = true;
  String? _logoPath;
  String _selectedTemplate = 'modern';

  @override
  void initState() {
    super.initState();
    if (supabase.auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    } else {
      _loadSavedSettings();
    }
  }

  Future<void> _loadSavedSettings() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final settings = await supabase
          .from('invoice_settings')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (settings != null && mounted) {
        setState(() {
          _companyNameController.text = settings['company_name'] ?? '';
          _companyAddressController.text = settings['company_address'] ?? '';
          _companyPhoneController.text = settings['company_phone'] ?? '';
          _companyEmailController.text = settings['company_email'] ?? '';
          _invoiceNoteController.text = settings['invoice_note'] ?? '';
          _selectedTemplate = settings['template'] ?? 'modern';
          _showWatermark = settings['show_watermark'] ?? true;
          _logoPath = settings['logo_url'];
        });
      }
    } catch (e) {
      print('Error loading invoice settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('invoice_settings').upsert({
        'user_id': userId,
        'company_name': _companyNameController.text,
        'company_address': _companyAddressController.text,
        'company_phone': _companyPhoneController.text,
        'company_email': _companyEmailController.text,
        'invoice_note': _invoiceNoteController.text,
        'template': _selectedTemplate,
        'show_watermark': _showWatermark,
        'logo_url': _logoPath,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invoice settings saved successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error saving invoice settings: $e');
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _invoiceNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive auth check: prevent render if not authenticated
    if (supabase.auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Redirecting to login...')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Personalization'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            const Text(
              'Logo & Branding',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  if (_logoPath != null)
                    Container(
                      width: 200,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logo upload coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Logo'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PNG, JPG, or SVG • Max 2MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Watermark Section
            const Text(
              'Invoice Watermark',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Show Watermark'),
              subtitle: const Text(
                'Display "DRAFT" or "PAID" watermark on invoices',
              ),
              value: _showWatermark,
              onChanged: (value) {
                if (mounted) {
                  setState(() => _showWatermark = value ?? false);
                }
              },
            ),
            const SizedBox(height: 24),

            // Invoice Template Selection
            const Text(
              'Invoice Template',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                buildTemplateOption(
                  title: 'Modern',
                  description: 'Clean, minimalist design with blue accent',
                  isSelected: _selectedTemplate == 'modern',
                  onTap: () =>
                      setState(() => _selectedTemplate = 'modern'),
                ),
                const SizedBox(height: 12),
                buildTemplateOption(
                  title: 'Classic',
                  description: 'Traditional invoice style with grid',
                  isSelected: _selectedTemplate == 'classic',
                  onTap: () =>
                      setState(() => _selectedTemplate = 'classic'),
                ),
                const SizedBox(height: 12),
                buildTemplateOption(
                  title: 'Professional',
                  description: 'Corporate style with detailed sections',
                  isSelected: _selectedTemplate == 'professional',
                  onTap: () =>
                      setState(() => _selectedTemplate = 'professional'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Company Information
            const Text(
              'Company Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: 'Company Name',
                hintText: 'Your Business Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyAddressController,
              decoration: InputDecoration(
                labelText: 'Company Address',
                hintText: '123 Main St, City, State 12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyPhoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '(555) 123-4567',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _companyEmailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'contact@yourcompany.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Default Invoice Note
            const Text(
              'Default Invoice Note',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _invoiceNoteController,
              decoration: InputDecoration(
                labelText: 'Invoice Footer Note',
                hintText:
                    'e.g., Thank you for your business! Payment due within 30 days.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Preview Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mock Invoice Preview
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_showWatermark)
                          Center(
                            child: Text(
                              'DRAFT',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _companyNameController.text.isEmpty
                              ? 'Your Company Name'
                              : _companyNameController.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _companyAddressController.text.isEmpty
                              ? '123 Main St, City, State 12345'
                              : _companyAddressController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'INVOICE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Invoice #',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('INV-001'),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Jan 1, 2025'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Total: \$0.00',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          _invoiceNoteController.text.isEmpty
                              ? 'Thank you for your business!'
                              : _invoiceNoteController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget buildTemplateOption({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        subtitle: Text(description),
        trailing: Radio<String>(
          value: title.toLowerCase(),
          groupValue: _selectedTemplate,
          onChanged: (_) => onTap(),
        ),
      ),
    );
  }
}
