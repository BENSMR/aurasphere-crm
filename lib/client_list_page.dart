// lib/client_list_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> clients = [];
  bool loading = true;
  bool showHealth = true; // Default to true

  Future<void> _loadClients() async {
    setState(() => loading = true);
    try {
      // Load clients
      final data = await supabase.from('clients').select();
      
      // Check feature preferences
      bool healthEnabled = true; // Default
      try {
        final prefs = await supabase
            .from('user_preferences')
            .select('features')
            .eq('user_id', supabase.auth.currentUser!.id)
            .single();
        final features = prefs['features'] as Map<String, dynamic>?;
        healthEnabled = features?['client_health'] == true;
      } catch (e) {
        // Use default if preferences don't exist
      }
      
      if (mounted) {
        setState(() {
          clients = data;
          showHealth = healthEnabled;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addClient() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await supabase.from('clients').insert({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
              });
              Navigator.pop(context);
              _loadClients();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  double _calculateHealth(Map<String, dynamic> client) {
    final lastContact = DateTime.tryParse(client['last_contact'] ?? '') ?? DateTime(2000);
    final daysSince = DateTime.now().difference(lastContact).inDays;
    final health = max(0.0, 100.0 - (daysSince * 0.8));
    return min(100.0, health);
  }

  Color _getHealthColor(double health) {
    if (health >= 70) return Colors.green;
    if (health >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          DropdownButton<Locale>(
            value: Localizations.localeOf(context),
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            dropdownColor: Colors.indigo,
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('English', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: Locale('fr'), child: Text('Français', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: Locale('it'), child: Text('Italiano', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: Locale('mt'), child: Text('Malti', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: Locale('ar'), child: Text('العربية', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (locale) async {
              if (locale != null) {
                try {
                  // Save to user_preferences table
                  await supabase.from('user_preferences').upsert({
                    'user_id': supabase.auth.currentUser?.id,
                    'language': locale.languageCode,
                  });
                  // Update app locale through root widget
                  if (mounted) {
                    // TODO: Implement locale update mechanism
                    // final state = context.findAncestorStateOfType<_AurasphereCRMState>();
                    // state?.updateLocale(locale);
                  }
                } catch (e) {
                  // Ignore if table doesn't exist yet
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await supabase.auth.signOut(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : clients.isEmpty
              ? const Center(child: Text('No clients yet'))
              : ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final c = clients[index];
                    
                    if (showHealth) {
                      // Show health indicators
                      final health = _calculateHealth(c);
                      final healthColor = _getHealthColor(health);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: healthColor,
                          child: Text(
                            '${health.toInt()}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(c['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['email'] ?? ''),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: health / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: healthColor,
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.favorite, color: healthColor, size: 20),
                      );
                    } else {
                      // Simple list without health indicators
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Text(
                            c['name'].substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(c['name']),
                        subtitle: Text(c['email'] ?? ''),
                      );
                    }
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _addClient, child: const Icon(Icons.add)),
    );
  }
}
