import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final _logger = Logger();

/// Advanced Reporting Service
/// Generates custom reports with date ranges, charts, and PDF exports
class ReportingService {
  static final ReportingService _instance = ReportingService._internal();
  final supabase = Supabase.instance.client;

  ReportingService._internal();

  factory ReportingService() {
    return _instance;
  }

  /// Generate revenue report for date range
  Future<Map<String, dynamic>> generateRevenueReport({
    required String orgId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.i('📊 Generating revenue report: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // Get invoices in date range
      final invoices = await supabase
          .from('invoices')
          .select('amount, status, created_at, client_id')
          .eq('org_id', orgId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalRevenue = 0;
      double paidRevenue = 0;
      double pendingRevenue = 0;
      int totalInvoices = 0;
      int paidInvoices = 0;

      for (var invoice in invoices) {
        final amount = (invoice['amount'] as num).toDouble();
        totalRevenue += amount;
        totalInvoices++;

        if (invoice['status'] == 'paid') {
          paidRevenue += amount;
          paidInvoices++;
        } else if (invoice['status'] == 'pending' || invoice['status'] == 'sent') {
          pendingRevenue += amount;
        }
      }

      final paymentRate = totalInvoices > 0 ? (paidInvoices / totalInvoices * 100) : 0;

      return {
        'period': '${startDate.toShortDateString()} to ${endDate.toShortDateString()}',
        'total_revenue': totalRevenue.toStringAsFixed(2),
        'paid_revenue': paidRevenue.toStringAsFixed(2),
        'pending_revenue': pendingRevenue.toStringAsFixed(2),
        'total_invoices': totalInvoices,
        'paid_invoices': paidInvoices,
        'pending_invoices': totalInvoices - paidInvoices,
        'payment_rate': paymentRate.toStringAsFixed(1),
        'average_invoice': totalInvoices > 0 ? (totalRevenue / totalInvoices).toStringAsFixed(2) : '0.00',
      };
    } catch (e) {
      _logger.e('❌ Error generating revenue report: $e');
      rethrow;
    }
  }

  /// Generate profitability report
  Future<Map<String, dynamic>> generateProfitabilityReport({
    required String orgId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.i('💰 Generating profitability report');

      // Get invoices (revenue)
      final invoices = await supabase
          .from('invoices')
          .select('amount, status, created_at')
          .eq('org_id', orgId)
          .eq('status', 'paid')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      // Get expenses
      final expenses = await supabase
          .from('expenses')
          .select('amount, category, created_at')
          .eq('org_id', orgId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalRevenue = 0;
      double totalExpenses = 0;
      Map<String, double> expensesByCategory = {};

      for (var invoice in invoices) {
        totalRevenue += (invoice['amount'] as num).toDouble();
      }

      for (var expense in expenses) {
        final amount = (expense['amount'] as num).toDouble();
        totalExpenses += amount;

        final category = (expense['category'] as String?) ?? 'Other';
        expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount;
      }

      final grossProfit = totalRevenue - totalExpenses;
      final profitMargin = totalRevenue > 0 ? (grossProfit / totalRevenue * 100) : 0;

      return {
        'period': '${startDate.toShortDateString()} to ${endDate.toShortDateString()}',
        'total_revenue': totalRevenue.toStringAsFixed(2),
        'total_expenses': totalExpenses.toStringAsFixed(2),
        'gross_profit': grossProfit.toStringAsFixed(2),
        'profit_margin': profitMargin.toStringAsFixed(1),
        'expenses_by_category': expensesByCategory.map(
          (k, v) => MapEntry(k, v.toStringAsFixed(2)),
        ),
      };
    } catch (e) {
      _logger.e('❌ Error generating profitability report: $e');
      rethrow;
    }
  }

  /// Generate team performance report
  Future<Map<String, dynamic>> generateTeamPerformanceReport({
    required String orgId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.i('👥 Generating team performance report');

      // Get jobs by technician
      final jobs = await supabase
          .from('jobs')
          .select('assigned_to, status, created_at')
          .eq('org_id', orgId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      Map<String, dynamic> technicianStats = {};

      for (var job in jobs) {
        final techId = (job['assigned_to'] as String?) ?? 'Unassigned';
        if (!technicianStats.containsKey(techId)) {
          technicianStats[techId] = {
            'total_jobs': 0,
            'completed': 0,
            'in_progress': 0,
            'pending': 0,
          };
        }

        technicianStats[techId]['total_jobs']++;

        final status = job['status'] as String?;
        if (status == 'completed') {
          technicianStats[techId]['completed']++;
        } else if (status == 'in_progress') {
          technicianStats[techId]['in_progress']++;
        } else {
          technicianStats[techId]['pending']++;
        }
      }

      // Calculate completion rates
      for (var tech in technicianStats.entries) {
        final stats = tech.value;
        final completionRate = stats['total_jobs'] > 0
            ? ((stats['completed'] / stats['total_jobs']) * 100).toStringAsFixed(1)
            : '0.0';
        stats['completion_rate'] = completionRate;
      }

      return {
        'period': '${startDate.toShortDateString()} to ${endDate.toShortDateString()}',
        'total_jobs': jobs.length,
        'technician_stats': technicianStats,
      };
    } catch (e) {
      _logger.e('❌ Error generating team performance report: $e');
      rethrow;
    }
  }

  /// Get month-over-month comparison
  Future<Map<String, dynamic>> getMonthOverMonthComparison({
    required String orgId,
  }) async {
    try {
      _logger.i('📈 Generating month-over-month comparison');

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      final currentMonthReport = await generateRevenueReport(
        orgId: orgId,
        startDate: DateTime(now.year, now.month, 1),
        endDate: now,
      );

      final lastMonthReport = await generateRevenueReport(
        orgId: orgId,
        startDate: lastMonth,
        endDate: DateTime(lastMonth.year, lastMonth.month + 1, 0),
      );

      final currentRevenue = double.tryParse(currentMonthReport['total_revenue'] as String? ?? '0') ?? 0;
      final lastRevenue = double.tryParse(lastMonthReport['total_revenue'] as String? ?? '0') ?? 0;

      final growth = lastRevenue > 0 ? ((currentRevenue - lastRevenue) / lastRevenue * 100) : 0;

      return {
        'current_month': currentMonthReport,
        'last_month': lastMonthReport,
        'growth_percentage': growth.toStringAsFixed(1),
        'growth_amount': (currentRevenue - lastRevenue).toStringAsFixed(2),
      };
    } catch (e) {
      _logger.e('❌ Error generating MoM comparison: $e');
      rethrow;
    }
  }

  /// Export report as JSON (can be converted to PDF)
  Future<String> exportReportAsJson({
    required Map<String, dynamic> reportData,
    required String reportType,
  }) async {
    try {
      final exportData = {
        'report_type': reportType,
        'generated_at': DateTime.now().toIso8601String(),
        'data': reportData,
      };

      final jsonString = jsonEncode(exportData);
      _logger.i('✅ Report exported as JSON (${jsonString.length} bytes)');
      return jsonString;
    } catch (e) {
      _logger.e('❌ Error exporting report: $e');
      rethrow;
    }
  }
}

extension on DateTime {
  String toShortDateString() => '$day/${month.toString().padLeft(2, '0')}/$year';
}
