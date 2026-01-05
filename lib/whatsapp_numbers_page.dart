import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhatsAppNumbersPage extends StatefulWidget {
  const WhatsAppNumbersPage({super.key});

  @override
  State<WhatsAppNumbersPage> createState() => _WhatsAppNumbersPageState();
}

class _WhatsAppNumbersPageState extends State<WhatsAppNumbersPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  String phone = '';
  String label = 'Owner';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auth guard: redirect to home if not logged in
    if (supabase.auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Secondary auth check
    if (supabase.auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Numbers'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add number form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number (digits only)',
                          hintText: 'e.g., 1234567890',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (!RegExp(r'^[0-9]{8,15}$').hasMatch(v)) {
                            return 'Invalid phone (8-15 digits only)';
                          }
                          return null;
                        },
                        onChanged: (v) => setState(() => phone = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Label',
                          hintText: 'e.g., Owner, Manager, Support',
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Label is required';
                          }
                          return null;
                        },
                        onChanged: (v) => setState(() => label = v),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _addNumber,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(_isLoading ? 'Adding...' : 'Add Number'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // List existing numbers
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchWhatsAppNumbers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('❌ Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final numbers = snapshot.data ?? [];

                if (numbers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_disabled, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No WhatsApp numbers added yet'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: numbers.length,
                  itemBuilder: (context, index) {
                    final number = numbers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.message, color: Colors.green),
                        title: Text(
                          '+${number['phone']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(number['label'] ?? 'Unlabeled'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNumber(
                            number['id'],
                            number['phone'],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNumber() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      // Get user's organization plan
      final profile = await supabase
          .from('profiles')
          .select('plan')
          .eq('user_id', userId)
          .maybeSingle();

      int maxNumbers = 1; // Default solo plan
      if (profile?['plan'] == 'team') maxNumbers = 3;
      if (profile?['plan'] == 'workshop') maxNumbers = 7;

      // Check current count before adding
      final countResponse = await supabase
          .from('whatsapp_numbers')
          .select('id')
          .eq('user_id', userId);

      final currentCount = countResponse.length;

      if (currentCount >= maxNumbers) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Limit reached! Your ${profile?['plan'] ?? 'Solo'} plan allows $maxNumbers number(s). '
                'Upgrade to add more.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      await supabase.from('whatsapp_numbers').insert({
        'phone': phone,
        'label': label,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ WhatsApp number added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          phone = '';
          label = 'Owner';
        });

        // Trigger rebuild of list
        setState(() {});
      }
    } catch (e) {
      print('❌ Error adding WhatsApp number: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteNumber(String id, String phone) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete WhatsApp Number'),
        content: Text('Are you sure you want to delete +$phone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('whatsapp_numbers').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Number deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Trigger rebuild
        setState(() {});
      }
    } catch (e) {
      print('❌ Error deleting WhatsApp number: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<dynamic>> _fetchWhatsAppNumbers() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      
      final response = await supabase
          .from('whatsapp_numbers')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response ?? [];
    } catch (e) {
      print('❌ Error fetching WhatsApp numbers: $e');
      rethrow;
    }
  }
}
