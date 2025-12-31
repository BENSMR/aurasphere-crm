// lib/team_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pricing_page.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> members = [];
  Map<String, dynamic>? organization;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      // Get organization info
      final orgData = await supabase
          .from('organizations')
          .select('id, name, plan, max_users')
          .eq('owner_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      // Get team members
      List<Map<String, dynamic>> memberData = [];
      if (orgData != null) {
        final membersResponse = await supabase
            .from('org_members')
            .select('*, users(email)')
            .eq('org_id', orgData['id']);
        memberData = membersResponse;
      }

      if (mounted) {
        setState(() {
          organization = orgData;
          members = memberData;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading team: $e')),
        );
      }
    }
  }

  Future<void> _addTeamMember() async {
    if (organization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No organization found. Please create one first.')),
      );
      return;
    }

    final emailCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team Member'),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'colleague@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _inviteTeamMember(emailCtrl.text.trim());
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteTeamMember(String email) async {
    if (email.isEmpty || organization == null) return;

    try {
      // Check member count against plan limit
      final response = await supabase
          .from('org_members')
          .select('id')
          .count(CountOption.exact);
      final memberCount = response.count;

      final maxUsers = organization!['plan'] == 'solo_trades' ? 1 : 
                      organization!['plan'] == 'small_team' ? 3 : 7;

      if (memberCount >= maxUsers) {
        // Show upgrade dialog
        _showUpgradeDialog('Upgrade to add more team members!');
        return;
      }

      // Check if user already exists
      final existingUser = await supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser == null) {
        // Send invitation email (implement via Edge Function or email service)
        await supabase.from('team_invitations').insert({
          'org_id': organization!['id'],
          'email': email,
          'invited_by': supabase.auth.currentUser?.id,
          'status': 'pending',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invitation sent to $email')),
          );
        }
      } else {
        // Add existing user to organization
        await supabase.from('org_members').insert({
          'org_id': organization!['id'],
          'user_id': existingUser['id'],
          'role': 'member',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$email added to team')),
          );
        }
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding member: $e')),
        );
      }
    }
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.orange),
            SizedBox(width: 12),
            Text('Upgrade Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to add more team members:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Small Team: Up to 7 users (€15/month)'),
            const Text('• Growing Team: Up to 12 users (€29/month)'),
            const Text('• Enterprise: Unlimited users (Custom pricing)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PricingPage()),
              );
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team Member'),
        content: const Text('Are you sure you want to remove this member from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('org_members').delete().eq('id', memberId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed from team')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing member: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        actions: [
          if (organization != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Chip(
                avatar: const Icon(Icons.people, size: 16),
                label: Text(
                  '${members.length}/${organization!['max_users']} users',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : organization == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.business, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No organization found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PricingPage()),
                          );
                        },
                        child: const Text('Create Organization'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Organization info
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.indigo.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.business, size: 32, color: Colors.indigo),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  organization!['name'] ?? 'My Organization',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${organization!['plan']} Plan',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.workspace_premium, size: 16),
                            label: const Text('Upgrade'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PricingPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Team members list
                    Expanded(
                      child: members.isEmpty
                          ? const Center(child: Text('No team members yet'))
                          : ListView.builder(
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                final user = member['users'] as Map<String, dynamic>?;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo,
                                    child: Text(
                                      (user?['email'] ?? 'U').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user?['email'] ?? 'Unknown'),
                                  subtitle: Text(member['role'] ?? 'member'),
                                  trailing: member['role'] != 'owner'
                                      ? IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => _removeMember(member['id']),
                                        )
                                      : const Chip(
                                          label: Text('Owner', style: TextStyle(fontSize: 12)),
                                          backgroundColor: Colors.green,
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: organization != null
          ? FloatingActionButton(
              onPressed: _addTeamMember,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}
