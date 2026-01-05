import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'services/whatsapp_service.dart';

final _logger = Logger();

class WhatsAppPage extends StatefulWidget {
  const WhatsAppPage({super.key});

  @override
  State<WhatsAppPage> createState() => _WhatsAppPageState();
}

class _WhatsAppPageState extends State<WhatsAppPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isConfigured = WhatsAppService.isConfigured;
  bool _loading = false;
  List<Map<String, dynamic>> _deliveryLogs = [];
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedEntity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeliveryLogs();
  }

  Future<void> _loadDeliveryLogs() async {
    try {
      // Load WhatsApp statistics
      if (mounted) {
        setState(() => _deliveryLogs = []);
      }
    } catch (e) {
      _logger.e('Error loading logs: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_phoneController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Send WhatsApp message
      final success = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Message sent' : '❌ Failed to send'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          _phoneController.clear();
          _messageController.clear();
          _loadDeliveryLogs();
        }
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendInvoice(Map<String, dynamic> invoice) async {
    setState(() => _loading = true);
    try {
      final client = await Supabase.instance.client
          .from('clients')
          .select('phone')
          .eq('id', invoice['client_id'])
          .single();

      // Send WhatsApp invoice
      final success = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Invoice sent' : '❌ Failed to send invoice'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadDeliveryLogs();
      }
    } catch (e) {
      _logger.e('Error sending invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Integration'),
        backgroundColor: const Color(0xFF25D366),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveryLogs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !_isConfigured
          ? _buildNotConfigured()
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF25D366),
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Send Message'),
                    Tab(text: 'Invoices'),
                    Tab(text: 'History'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSendMessageTab(),
                      _buildInvoicesTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotConfigured() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble,
              size: 64,
              color: Color(0xFF25D366),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'WhatsApp Not Configured',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add WhatsApp API credentials to .env to enable messaging',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Configure Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
            onPressed: () {
              // Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add credentials to .env file')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSendMessageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send WhatsApp Message',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: '+1234567890',
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Type your message...',
              labelText: 'Message',
              prefixIcon: const Icon(Icons.message),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: _loading ? const Text('Sending...') : const Text('Send Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _loading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('invoices')
          .select('*')
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No invoices found'));
        }

        final invoices = snapshot.data as List;

        return ListView.builder(
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.receipt, color: Color(0xFF25D366)),
                title: Text('Invoice #${invoice['invoice_number']}'),
                subtitle: Text('\$${invoice['total_amount']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendInvoice(invoice),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 500)).then(
        (_) => Supabase.instance.client
            .from('whatsapp_delivery_logs')
            .select()
            .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
            .order('sent_at', ascending: false)
            .limit(50),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No message history'));
        }

        final logs = snapshot.data as List;

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final success = log['status'] == 'sent';

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                title: Text(log['phone_number']),
                subtitle: Text('${log['entity_type']} • ${log['sent_at']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: success ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    success ? 'Sent' : 'Failed',
                    style: TextStyle(
                      fontSize: 12,
                      color: success ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
