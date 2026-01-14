// lib/services/waste_detection_service.dart
/// FinOps Cloud Waste Detection Engine
/// Analyzes cloud expenses to identify optimization opportunities
/// Saves 28% average cloud waste (target: <10%)
/// 
/// Waste Categories:
/// - Idle resources (<5% CPU for 7+ days)
/// - Over-provisioned instances
/// - Unused services (CDN, backups)
/// - Unattached storage
/// - Data transfer costs
/// - Old snapshots
/// - Orphaned IPs
/// - Unused reserved instances

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

class WasteDetectionService {
  static final WasteDetectionService _instance = WasteDetectionService._internal();
  
  factory WasteDetectionService() => _instance;
  
  WasteDetectionService._internal();

  final supabase = Supabase.instance.client;

  /// Analyze cloud expenses for waste patterns
  /// Returns waste findings with severity and potential savings
  Future<Map<String, dynamic>> analyzeCloudExpenses({
    required String orgId,
    required String expenseId,
    required String provider, // 'aws', 'azure', 'gcp'
    required Map<String, dynamic> billData,
  }) async {
    try {
      _logger.i('🔍 Analyzing cloud expenses for waste (Provider: $provider)');

      final findings = <Map<String, dynamic>>[];
      double totalPotentialSavings = 0;

      // 1. IDLE RESOURCES: Compute instances with <5% CPU for 7+ days
      final idleResources = _detectIdleResources(billData, provider);
      findings.addAll(idleResources['findings']);
      totalPotentialSavings += idleResources['savings'] as double;

      // 2. OVER-PROVISIONED: Instance types larger than needed
      final overProvisioned = _detectOverProvisioned(billData, provider);
      findings.addAll(overProvisioned['findings']);
      totalPotentialSavings += overProvisioned['savings'] as double;

      // 3. UNUSED SERVICES: CDN, unused backups, etc.
      final unusedServices = _detectUnusedServices(billData, provider);
      findings.addAll(unusedServices['findings']);
      totalPotentialSavings += unusedServices['savings'] as double;

      // 4. UNATTACHED STORAGE: EBS volumes, managed disks
      final orphanedStorage = _detectOrphanedStorage(billData, provider);
      findings.addAll(orphanedStorage['findings']);
      totalPotentialSavings += orphanedStorage['savings'] as double;

      // 5. DATA TRANSFER: Expensive egress costs
      final dataTransfer = _detectExpensiveDataTransfer(billData, provider);
      findings.addAll(dataTransfer['findings']);
      totalPotentialSavings += dataTransfer['savings'] as double;

      // 6. OLD SNAPSHOTS: Outdated backups
      final oldSnapshots = _detectOldSnapshots(billData, provider);
      findings.addAll(oldSnapshots['findings']);
      totalPotentialSavings += oldSnapshots['savings'] as double;

      // 7. ORPHANED IPs: Unattached IP addresses
      final orphanedIps = _detectOrphanedIps(billData, provider);
      findings.addAll(orphanedIps['findings']);
      totalPotentialSavings += orphanedIps['savings'] as double;

      // 8. RESERVED INSTANCES: Unused RI purchases
      final unusedRi = _detectUnusedReservedInstances(billData, provider);
      findings.addAll(unusedRi['findings']);
      totalPotentialSavings += unusedRi['savings'] as double;

      // Save findings to database
      if (findings.isNotEmpty) {
        for (final finding in findings) {
          await supabase.from('waste_findings').insert({
            'org_id': orgId,
            'expense_id': expenseId,
            'provider': provider,
            'waste_category': finding['category'],
            'resource_type': finding['resourceType'],
            'resource_id': finding['resourceId'],
            'resource_name': finding['resourceName'],
            'resource_region': finding['region'],
            'current_monthly_cost': finding['currentCost'],
            'potential_monthly_savings': finding['monthlySavings'],
            'potential_annual_savings': finding['annualSavings'],
            'severity': finding['severity'],
            'description': finding['description'],
            'recommendation': finding['recommendation'],
          });
        }
      }

      // Calculate waste percentage
      final totalCost = _extractTotalCost(billData);
      final wastePercentage = totalCost > 0 ? (totalPotentialSavings / totalCost) * 100 : 0;

      _logger.i(
        '✅ Waste analysis complete: '
        '\$${totalPotentialSavings.toStringAsFixed(2)}/month '
        '(${wastePercentage.toStringAsFixed(1)}% of spend)',
      );

      return {
        'success': true,
        'findings_count': findings.length,
        'total_potential_monthly_savings': totalPotentialSavings,
        'total_potential_annual_savings': totalPotentialSavings * 12,
        'waste_percentage': wastePercentage,
        'findings': findings,
      };
    } catch (e) {
      _logger.e('❌ Error analyzing expenses: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Detect idle resources (< 5% CPU for 7+ days)
  Map<String, dynamic> _detectIdleResources(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    // Simulated detection - in production, connect to CloudWatch/Azure Monitor
    final resources = billData['compute'] as List? ?? [];
    
    for (final resource in resources) {
      if ((resource['cpuUtilization'] ?? 0) < 5 &&
          (resource['daysIdle'] ?? 0) >= 7) {
        final monthlyCost = resource['monthlyCost'] as double? ?? 50;
        final savingsAmount = monthlyCost * 0.9; // 90% savings

        findings.add({
          'category': 'idle_resource',
          'resourceType': 'ec2_instance',
          'resourceId': resource['instanceId'] ?? 'unknown',
          'resourceName': resource['name'] ?? 'Unnamed Instance',
          'region': resource['region'] ?? 'us-east-1',
          'currentCost': monthlyCost,
          'monthlySavings': savingsAmount,
          'annualSavings': savingsAmount * 12,
          'severity': 'high',
          'description': 'Instance running with <5% CPU for ${resource['daysIdle']} days',
          'recommendation': 'Stop or terminate this instance to save \$${savingsAmount.toStringAsFixed(0)}/month',
        });

        savings += savingsAmount;
      }
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Detect over-provisioned instances
  Map<String, dynamic> _detectOverProvisioned(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    final resources = billData['compute'] as List? ?? [];

    for (final resource in resources) {
      final tier = resource['instanceType'] as String? ?? '';
      final avgCpu = resource['avgCpuUtilization'] ?? 0;
      
      // Example: m5.4xlarge with 10% CPU could downsize to t3.medium
      if (tier.contains('4xlarge') && avgCpu < 15) {
        final currentCost = resource['monthlyCost'] as double? ?? 500;
        final downsizedCost = currentCost * 0.4; // 60% cost reduction
        final savingsAmount = currentCost - downsizedCost;

        findings.add({
          'category': 'over_provisioned',
          'resourceType': 'ec2_instance',
          'resourceId': resource['instanceId'] ?? 'unknown',
          'resourceName': resource['name'] ?? 'Over-provisioned Instance',
          'region': resource['region'] ?? 'us-east-1',
          'currentCost': currentCost,
          'monthlySavings': savingsAmount,
          'annualSavings': savingsAmount * 12,
          'severity': 'medium',
          'description': 'Instance type $tier is oversized for actual usage (${avgCpu.toStringAsFixed(1)}% CPU)',
          'recommendation': 'Downsize to t3.medium or similar - potential \$${savingsAmount.toStringAsFixed(0)}/month savings',
        });

        savings += savingsAmount;
      }
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Detect unused services
  Map<String, dynamic> _detectUnusedServices(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    final services = billData['services'] as Map? ?? {};

    // Check for unused CloudFront (CDN)
    final cloudfront = services['cloudfront'] as Map<String, dynamic>?;
    if (cloudfront != null && cloudfront['usage'] == 0) {
      final cost = cloudfront['cost'] as double? ?? 50;
      findings.add({
        'category': 'unused_service',
        'resourceType': 'cloudfront_distribution',
        'resourceId': 'cloudfront-dist-1',
        'resourceName': 'CloudFront Distribution',
        'region': 'global',
        'currentCost': cost,
        'monthlySavings': cost,
        'annualSavings': cost * 12,
        'severity': 'high',
        'description': 'CloudFront distribution running with zero traffic',
        'recommendation': 'Disable or delete unused CDN distribution - save \$${cost.toStringAsFixed(0)}/month',
      });
      savings += cost;
    }

    // Check for unused backups
    final backups = services['backups'] as Map<String, dynamic>?;
    final unusedCount = backups?['unusedBackups'] as int? ?? 0;
    if (unusedCount > 0) {
      final backupCost = backups?['cost'] as double? ?? 100;
      findings.add({
        'category': 'unused_service',
        'resourceType': 'backup_storage',
        'resourceId': 'backup-vault-1',
        'resourceName': 'Unused Backup Vault',
        'region': 'us-east-1',
        'currentCost': backupCost,
        'monthlySavings': backupCost,
        'annualSavings': backupCost * 12,
        'severity': 'medium',
        'description': 'Backup vault with $unusedCount old backups',
        'recommendation': 'Delete backups older than 30 days',
      });
      savings += backupCost;
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Detect orphaned storage
  Map<String, dynamic> _detectOrphanedStorage(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    final storage = billData['storage'] as List? ?? [];

    for (final volume in storage) {
      if ((volume['attached'] ?? false) == false) {
        final monthlyCost = volume['monthlyCost'] as double? ?? 30;
        
        findings.add({
          'category': 'unattached_storage',
          'resourceType': 'ebs_volume',
          'resourceId': volume['volumeId'] ?? 'unknown',
          'resourceName': volume['name'] ?? 'Unattached Volume',
          'region': volume['region'] ?? 'us-east-1',
          'currentCost': monthlyCost,
          'monthlySavings': monthlyCost,
          'annualSavings': monthlyCost * 12,
          'severity': 'high',
          'description': 'EBS volume not attached to any instance',
          'recommendation': 'Delete orphaned storage volume - save \$${monthlyCost.toStringAsFixed(0)}/month',
        });

        savings += monthlyCost;
      }
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Detect expensive data transfer
  Map<String, dynamic> _detectExpensiveDataTransfer(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    final dataTransfer = billData['dataTransfer'] as Map? ?? {};
    final egressCost = dataTransfer['egressCost'] as double? ?? 0;

    if (egressCost > 100) {
      findings.add({
        'category': 'data_transfer',
        'resourceType': 'data_egress',
        'resourceId': 'egress-charges',
        'resourceName': 'High Egress Data Transfer',
        'region': 'global',
        'currentCost': egressCost,
        'monthlySavings': egressCost * 0.2, // 20% optimization potential
        'annualSavings': egressCost * 0.2 * 12,
        'severity': 'medium',
        'description': 'High outbound data transfer costs (\$${egressCost.toStringAsFixed(0)}/month)',
        'recommendation': 'Use CloudFront caching, compress data, or optimize CDN - save 20%',
      });

      savings += egressCost * 0.2;
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Detect old snapshots
  Map<String, dynamic> _detectOldSnapshots(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    final snapshots = billData['snapshots'] as List? ?? [];

    for (final snapshot in snapshots) {
      final ageInDays = snapshot['ageInDays'] as int? ?? 0;
      
      if (ageInDays > 90) {
        final monthlyCost = snapshot['monthlyCost'] as double? ?? 20;
        
        findings.add({
          'category': 'old_snapshot',
          'resourceType': 'ebs_snapshot',
          'resourceId': snapshot['snapshotId'] ?? 'unknown',
          'resourceName': snapshot['name'] ?? 'Old Snapshot',
          'region': snapshot['region'] ?? 'us-east-1',
          'currentCost': monthlyCost,
          'monthlySavings': monthlyCost,
          'annualSavings': monthlyCost * 12,
          'severity': 'low',
          'description': 'Snapshot ${ageInDays} days old - likely no longer needed',
          'recommendation': 'Delete old snapshots - implement 30-day retention policy',
        });

        savings += monthlyCost;
      }
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Detect orphaned IP addresses
  Map<String, dynamic> _detectOrphanedIps(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    final ips = billData['elasticIps'] as List? ?? [];

    for (final ip in ips) {
      if ((ip['associated'] ?? false) == false) {
        findings.add({
          'category': 'orphaned_ips',
          'resourceType': 'elastic_ip',
          'resourceId': ip['ipAddress'] ?? 'unknown',
          'resourceName': 'Unassociated IP: ${ip['ipAddress']}',
          'region': ip['region'] ?? 'us-east-1',
          'currentCost': 0.5,
          'monthlySavings': 0.5,
          'annualSavings': 6,
          'severity': 'low',
          'description': 'Elastic IP not associated with any instance',
          'recommendation': 'Release unused Elastic IP addresses - save \$0.50/month per IP',
        });

        savings += 0.5;
      }
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Detect unused reserved instances
  Map<String, dynamic> _detectUnusedReservedInstances(
    Map<String, dynamic> billData,
    String provider,
  ) {
    final findings = <Map<String, dynamic>>[];
    double savings = 0;

    final ris = billData['reservedInstances'] as List? ?? [];

    for (final ri in ris) {
      final utilizationRate = ri['utilizationRate'] as double? ?? 0;
      final monthlyCost = ri['monthlyCost'] as double? ?? 200;

      if (utilizationRate < 10) {
        final savingsAmount = monthlyCost * 0.5; // Could reallocate

        findings.add({
          'category': 'reserved_unused',
          'resourceType': 'reserved_instance',
          'resourceId': ri['reservationId'] ?? 'unknown',
          'resourceName': ri['instanceType'] ?? 'Reserved Instance',
          'region': ri['region'] ?? 'us-east-1',
          'currentCost': monthlyCost,
          'monthlySavings': savingsAmount,
          'annualSavings': savingsAmount * 12,
          'severity': 'high',
          'description': 'Reserved Instance with only ${utilizationRate.toStringAsFixed(1)}% utilization',
          'recommendation': 'Consider selling RI or downgrading to match actual usage',
        });

        savings += savingsAmount;
      }
    }

    return {'findings': findings, 'savings': savings};
  }

  /// Extract total cost from bill data
  double _extractTotalCost(Map<String, dynamic> billData) {
    return (billData['totalCost'] as num? ?? 0).toDouble();
  }

  /// Get waste findings by org
  Future<List<Map<String, dynamic>>> getWasteFindingsByOrg({
    required String orgId,
    String? status, // 'open', 'fixed', etc.
  }) async {
    try {
      _logger.i('📊 Fetching waste findings for org: $orgId');

      var query = supabase
          .from('waste_findings')
          .select()
          .eq('org_id', orgId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final findings = await query.order('potential_annual_savings', ascending: false);

      _logger.i('✅ Found ${findings.length} waste findings');
      return findings.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('❌ Error fetching findings: $e');
      return [];
    }
  }

  /// Dismiss a waste finding
  Future<bool> dismissFinding({
    required String findingId,
    required String reason,
  }) async {
    try {
      await supabase
          .from('waste_findings')
          .update({
            'status': 'dismissed',
            'dismissal_reason': reason,
            'dismissed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', findingId);

      _logger.i('✅ Finding dismissed: $findingId');
      return true;
    } catch (e) {
      _logger.e('❌ Error dismissing finding: $e');
      return false;
    }
  }

  /// Mark a finding as fixed
  Future<bool> markAsFixed(String findingId) async {
    try {
      await supabase
          .from('waste_findings')
          .update({
            'status': 'fixed',
            'fixed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', findingId);

      _logger.i('✅ Finding marked as fixed: $findingId');
      return true;
    } catch (e) {
      _logger.e('❌ Error marking finding as fixed: $e');
      return false;
    }
  }

  /// Get waste summary for dashboard
  Future<Map<String, dynamic>> getWasteSummary(String orgId) async {
    try {
      final findings = await supabase
          .from('waste_findings')
          .select(
            'potential_monthly_savings, potential_annual_savings, severity, status',
          )
          .eq('org_id', orgId)
          .eq('status', 'open');

      double totalMonthlySavings = 0;
      int criticalCount = 0;
      int highCount = 0;

      for (final finding in findings) {
        totalMonthlySavings += (finding['potential_monthly_savings'] as num? ?? 0).toDouble();
        
        if (finding['severity'] == 'critical') criticalCount++;
        if (finding['severity'] == 'high') highCount++;
      }

      return {
        'total_monthly_savings': totalMonthlySavings,
        'total_annual_savings': totalMonthlySavings * 12,
        'critical_findings': criticalCount,
        'high_findings': highCount,
        'total_findings': findings.length,
      };
    } catch (e) {
      _logger.e('❌ Error getting waste summary: $e');
      return {
        'total_monthly_savings': 0,
        'total_annual_savings': 0,
        'critical_findings': 0,
        'high_findings': 0,
        'total_findings': 0,
      };
    }
  }
}
