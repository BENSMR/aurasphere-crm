// lib/performance_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? stats;
  Map<String, dynamic>? invoiceStats;
  String? userPlan;

  @override
  void initState() {
    super.initState();
    if (supabase.auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    } else {
      _loadStats();
      _loadInvoiceStats();
    }
  }

  Future<void> _loadStats() async {
    final org = await supabase.from('organizations').select('id, plan').single();
    
    if (mounted) {
      setState(() => userPlan = org['plan']);
    }
    
    // Conversion rate: leads → invoices
    final leadResponse = await supabase
        .from('leads')
        .select('id')
        .eq('org_id', org['id'])
        .count(CountOption.exact);
    final leadCount = leadResponse.count;
    
    final invoiceResponse = await supabase
        .from('invoices')
        .select('id')
        .eq('org_id', org['id'])
        .not('lead_id', 'is', null)
        .count(CountOption.exact);
    final invoiceCount = invoiceResponse.count;
    
    // Avg. deal size
    final avgDeal = await supabase
        .from('invoices')
        .select('amount')
        .eq('org_id', org['id']);
    
    double avgValue = 0.0;
    if (avgDeal.isNotEmpty) {
      final total = avgDeal.fold<double>(0, (sum, inv) => sum + (inv['amount'] as num).toDouble());
      avgValue = total / avgDeal.length;
    }
    
    if (mounted) {
      setState(() => stats = {
        'leads': leadCount,
        'converted': invoiceCount,
        'conversion_rate': leadCount > 0 ? (invoiceCount / leadCount * 100).toStringAsFixed(1) : '0.0',
        'avg_deal': avgValue.toStringAsFixed(2),
      });
    }
  }

  Future<void> _loadInvoiceStats() async {
    try {
      final org = await supabase.from('organizations').select('id').single();
      
      // Avg payment time (calculate from paid invoices)
      final paidInvoices = await supabase
          .from('invoices')
          .select('sent_at, paid_at')
          .eq('org_id', org['id'])
          .eq('status', 'paid')
          .not('paid_at', 'is', null);
      
      double avgDays = 0.0;
      if (paidInvoices.isNotEmpty) {
        int totalDays = 0;
        for (final inv in paidInvoices) {
          final sentAt = DateTime.parse(inv['sent_at']);
          final paidAt = DateTime.parse(inv['paid_at']);
          totalDays += paidAt.difference(sentAt).inDays;
        }
        avgDays = totalDays / paidInvoices.length;
      }
      
      // Top service (most common in line_items)
      // Note: This is simplified - you'd need proper JSONB querying in production
      String topService = 'Service';
      
      // Overdue invoices
      final overdueResponse = await supabase
          .from('invoices')
          .select('id')
          .eq('org_id', org['id'])
          .eq('status', 'sent')
          .lt('due_date', DateTime.now().toIso8601String())
          .count(CountOption.exact);
      final overdue = overdueResponse.count;
      
      if (mounted) {
        setState(() => invoiceStats = {
          'avg_payment_days': avgDays.toStringAsFixed(1),
          'top_service': topService,
          'overdue_invoices': overdue,
        });
      }
    } catch (e) {
      print('Error loading invoice stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defensive auth check: prevent render if not authenticated
    if (supabase.auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Redirecting to login...')),
      );
    }

    if (stats == null || invoiceStats == null || userPlan == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userPlan == 'solo_trades') ...[
              // Solo Trades: Basic lead conversion metrics
              const Text('Lead Conversion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildStatCard('Leads This Month', stats!['leads'].toString(), Icons.people, Colors.blue),
              _buildStatCard('Converted to Invoices', stats!['converted'].toString(), Icons.check_circle, Colors.green),
              _buildStatCard('Avg. Invoice Value', '€${stats!['avg_deal']}', Icons.euro, Colors.purple),
            ] else ...[
              // Small Team & Workshop: Full analytics
              const Text('Lead Conversion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildStatCard('Leads This Month', stats!['leads'].toString(), Icons.people, Colors.blue),
              _buildStatCard('Converted to Clients', stats!['converted'].toString(), Icons.check_circle, Colors.green),
              _buildStatCard('Conversion Rate', '${stats!['conversion_rate']}%', Icons.trending_up, Colors.orange),
              _buildStatCard('Avg. Invoice Value', '€${stats!['avg_deal']}', Icons.euro, Colors.purple),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              const Text('Invoice Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildStatCard('Avg. Payment Time', '${invoiceStats!['avg_payment_days']} days', Icons.schedule, Colors.teal),
              _buildStatCard('Top Service', invoiceStats!['top_service'], Icons.star, Colors.amber),
              _buildStatCard('Overdue Invoices', invoiceStats!['overdue_invoices'].toString(), Icons.warning, Colors.red),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
