import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🤖 Autonomous Supplier AI Agent
/// Proactively manages suppliers, pricing, POs, and delivery tracking
class SupplierAiAgent {
  static final SupplierAiAgent _instance = SupplierAiAgent._internal();
  
  factory SupplierAiAgent() => _instance;
  
  SupplierAiAgent._internal();
  
  final supabase = Supabase.instance.client;

  /// 🤖 PROACTIVE: Analyze supplier performance and recommend actions
  /// Runs automatically to identify optimization opportunities
  Future<Map<String, dynamic>> analyzeSupplierPerformance({
    required String orgId,
    int daysBack = 90,
  }) async {
    try {
      print('🤖 Analyzing supplier performance for org: $orgId');
      
      // ✅ SECURITY: Validate org ownership
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Unauthorized: Not authenticated');
      
      final org = await supabase
          .from('organizations')
          .select('id, owner_id')
          .eq('id', orgId)
          .maybeSingle();
      
      if (org == null) throw Exception('Organization not found');
      if (org['owner_id'] != user.id) {
        throw Exception('Forbidden: Not organization owner');
      }

      // Get all suppliers
      final suppliers = await supabase
          .from('suppliers')
          .select()
          .eq('org_id', orgId);

      if (suppliers.isEmpty) {
        return {'success': false, 'message': 'No suppliers found'};
      }

      final analysis = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'suppliers': <Map<String, dynamic>>[],
        'recommendations': <String>[],
        'opportunities': <Map<String, dynamic>>[],
      };
      // ✅ FIX #5: Analyze suppliers with timeout protection
      for (int i = 0; i < suppliers.length; i += 10) {
        try {
          // Analyze each supplier (max 10 concurrent)
          final suppliersToAnalyze = suppliers
              .skip(i)
              .take(10)
              .toList();

          await Future.wait(
            suppliersToAnalyze.map((supplier) async {
              try {
                final supplierId = supplier['id'] as String;
                final supplierName = supplier['name'] as String;

                // Get recent orders from this supplier
                final orders = await supabase
                    .from('purchase_orders')
                    .select()
                    .eq('supplier_id', supplierId)
                    .eq('org_id', orgId)
                    .gte('created_at',
                        DateTime.now().subtract(Duration(days: daysBack)).toIso8601String())
                    .timeout(const Duration(seconds: 10));

                if ((orders as List).isEmpty) return;

                // Calculate metrics
                final ordersList = orders as List;
                final totalSpend = ordersList.fold<double>(
                    0, (sum, order) => sum + ((order['total_amount'] ?? 0) as num).toDouble());

                final deliveredOnTime = ordersList
                    .where((o) => o['delivered_at'] != null && 
                        DateTime.parse(o['delivered_at']).isBefore(DateTime.parse(o['due_date'])))
                    .length;

                final onTimePercentage =
                    ordersList.isNotEmpty ? (deliveredOnTime / ordersList.length * 100).toStringAsFixed(1) : '0';

                final supplierMetrics = {
                  'id': supplierId,
                  'name': supplierName,
                  'totalOrders': ordersList.length,
                  'totalSpend': totalSpend.toStringAsFixed(2),
                  'onTimeDeliveryRate': '$onTimePercentage%',
                  'lastOrderDate': ordersList.isNotEmpty ? ordersList.first['created_at'] : null,
                  'averageOrderValue': (totalSpend / (ordersList.isEmpty ? 1 : ordersList.length)).toStringAsFixed(2),
                };

                (analysis['suppliers'] as List).add(supplierMetrics);

                // Generate recommendations
                if (double.parse(onTimePercentage) < 80) {
                  (analysis['recommendations'] as List).add(
                    '⚠️ $supplierName: Low on-time delivery rate ($onTimePercentage%). Consider alternatives.',
                  );
                }
              } catch (e) {
                print('⚠️ Error analyzing supplier: $e');
              }
            }).toList(),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏱️ Supplier batch analysis timeout (continuing...)');
              return [];
            },
          );
          
          print('✅ Analyzed ${suppliersToAnalyze.length} suppliers');
        } catch (e) {
          print('❌ Error in supplier analysis batch: $e');
        }
      }

      // Find cost-saving opportunities
      final opportunities = await _identifyCostSavingOpportunities(orgId);
      analysis['opportunities'] = opportunities;

      return {'success': true, 'data': analysis};
    } catch (e) {
      print('❌ Error analyzing supplier performance: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🤖 PROACTIVE: Compare prices and suggest best suppliers
  Future<Map<String, dynamic>> comparePricesForProduct({
    required String orgId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      print('🤖 Comparing prices for product: $productId');

      // Get product details
      final product = await supabase
          .from('inventory')
          .select()
          .eq('id', productId)
          .eq('org_id', orgId)
          .single();

      // Get all supplier prices for this product
      final supplierPrices = await supabase
          .from('supplier_product_pricing')
          .select('*, suppliers(*)')
          .eq('product_id', productId);

      if (supplierPrices.isEmpty) {
        return {
          'success': false,
          'message': 'No supplier prices found for this product'
        };
      }

      // Calculate costs at requested quantity
      final priceComparison = <Map<String, dynamic>>[];

      for (final pricing in supplierPrices) {
        final unitPrice = pricing['unit_price'] as num;
        final quantityBreaks = pricing['quantity_breaks'] as String?;
        
        // ✅ FIX #4: Validate decimal precision
        if (unitPrice < 0 || unitPrice.isInfinite || unitPrice.isNaN) {
          print('⚠️ Skipping invalid price: $unitPrice');
          continue;
        }
        
        // Apply quantity breaks if applicable
        double finalPrice = unitPrice.toDouble();
        if (quantityBreaks != null) {
          // ✅ FIX #6: JSON decode with error handling
          try {
            final breaks = jsonDecode(quantityBreaks);
            if (breaks is! Map<String, dynamic>) {
              print('⚠️ Invalid quantity_breaks format');
              continue;
            }
            breaks.forEach((minQty, price) {
              final minQtyInt = int.tryParse(minQty);
              if (minQtyInt != null && quantity >= minQtyInt) {
                finalPrice = (price as num?)?.toDouble() ?? unitPrice.toDouble();
              }
            });
          } catch (e) {
            print('❌ Failed to parse quantity_breaks: $e');
          }
        }

        final totalCost = finalPrice * quantity;
        final supplier = pricing['suppliers'] as Map<String, dynamic>;

        priceComparison.add({
          'supplier_id': supplier['id'],
          'supplier_name': supplier['name'],
          'unit_price': finalPrice.toStringAsFixed(2),
          'total_cost': totalCost.toStringAsFixed(2),
          'lead_time_days': supplier['lead_time_days'] ?? 'Unknown',
          'reliability_rating': supplier['reliability_rating'] ?? '4.0',
          'quality_score': supplier['quality_score'] ?? '4.0',
        });
      }

      // Sort by price
      priceComparison.sort((a, b) =>
          double.parse(a['total_cost'] as String)
              .compareTo(double.parse(b['total_cost'] as String)));

      // Calculate savings opportunity
      final cheapest = double.parse(priceComparison.first['total_cost'] as String);
      final mostExpensive =
          double.parse(priceComparison.last['total_cost'] as String);
      final savingsOpportunity = mostExpensive - cheapest;
      final savingsPercentage = ((savingsOpportunity / mostExpensive) * 100).toStringAsFixed(1);

      return {
        'success': true,
        'product_name': product['item_name'],
        'quantity_requested': quantity,
        'prices': priceComparison,
        'best_price': priceComparison.first,
        'savings_opportunity': savingsOpportunity.toStringAsFixed(2),
        'savings_percentage': '$savingsPercentage%',
      };
    } catch (e) {
      print('❌ Error comparing prices: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🤖 PROACTIVE: Track deliveries and predict delays
  Future<Map<String, dynamic>> trackDeliveriesAndPredictDelays({
    required String orgId,
  }) async {
    try {
      print('🤖 Tracking deliveries and predicting delays');

      // Get pending purchase orders
      final pendingOrders = await supabase
          .from('purchase_orders')
          .select('*, suppliers(*)')
          .eq('org_id', orgId)
          .eq('status', 'pending')
          .or('status.eq.processing');

      if (pendingOrders.isEmpty) {
        return {'success': true, 'pending_orders': [], 'alerts': []};
      }

      final alerts = <Map<String, dynamic>>[];
      final tracking = <Map<String, dynamic>>[];

      for (final order in pendingOrders) {
        final dueDate = DateTime.parse(order['due_date'] as String);
        final supplier = order['suppliers'] as Map<String, dynamic>;
        final leadTime = supplier['lead_time_days'] as int? ?? 5;

        // Predict if delivery will be late
        final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
        final expectedDeliveryDate =
            DateTime.now().add(Duration(days: leadTime));
        final willBeLate =
            expectedDeliveryDate.isAfter(dueDate);

        if (willBeLate || daysUntilDue < 3) {
          alerts.add({
            'order_id': order['id'],
            'supplier_name': supplier['name'],
            'due_date': order['due_date'],
            'expected_delivery': expectedDeliveryDate.toIso8601String(),
            'days_until_due': daysUntilDue,
            'alert_type': willBeLate ? 'DELAY_PREDICTED' : 'DUE_SOON',
            'recommendation': willBeLate
                ? '⚠️ Order from ${supplier['name']} may arrive late. Consider expedited shipping or alternative supplier.'
                : '✅ Order arrives soon. Prepare for inventory update.',
          });
        }

        tracking.add({
          'order_id': order['id'],
          'supplier_name': supplier['name'],
          'amount': order['total_amount'],
          'due_date': order['due_date'],
          'status': order['status'],
          'on_track': !willBeLate,
        });
      }

      return {
        'success': true,
        'pending_orders': tracking.length,
        'tracking': tracking,
        'alerts': alerts,
        'action_items': alerts.map((a) => a['recommendation']).toList(),
      };
    } catch (e) {
      print('❌ Error tracking deliveries: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🤖 PROACTIVE: Generate reorder suggestions based on consumption rate
  Future<Map<String, dynamic>> generateReorderSuggestions({
    required String orgId,
    int daysOfHistory = 30,
  }) async {
    try {
      print('🤖 Generating reorder suggestions');

      // Get all inventory items
      final inventory = await supabase
          .from('inventory')
          .select()
          .eq('org_id', orgId);

      final suggestions = <Map<String, dynamic>>[];

      for (final item in inventory) {
        final itemId = item['id'] as String;
        final itemName = item['item_name'] as String;
        final currentQuantity = item['quantity'] as num;
        final reorderLevel = item['low_stock_threshold'] as num?;

        // Get usage history
        final usage = await supabase
            .from('stock_movements')
            .select()
            .eq('product_id', itemId)
            .eq('org_id', orgId)
            .eq('movement_type', 'used')
            .gte('created_at',
                DateTime.now().subtract(Duration(days: daysOfHistory)).toIso8601String());

        if (usage.isEmpty) continue;

        // Calculate consumption rate
        final totalUsed = (usage as List)
            .fold<num>(0, (sum, u) => sum + (u['quantity'] as num));
        final consumptionPerDay = totalUsed / daysOfHistory;
        final daysUntilStockout =
            currentQuantity / consumptionPerDay;

        // Generate suggestion if low
        if (reorderLevel != null &&
            currentQuantity < reorderLevel) {
          final quantityToOrder = (consumptionPerDay * 30).ceil(); // 30 days supply

          suggestions.add({
            'product_id': itemId,
            'product_name': itemName,
            'current_quantity': currentQuantity.toStringAsFixed(2),
            'reorder_level': reorderLevel.toStringAsFixed(2),
            'consumption_per_day': consumptionPerDay.toStringAsFixed(2),
            'days_until_stockout': daysUntilStockout.toStringAsFixed(1),
            'recommended_order_quantity': quantityToOrder,
            'urgency': daysUntilStockout < 7 ? 'URGENT' : 'SOON',
            'action': 'Create purchase order for $quantityToOrder units',
          });
        }
      }

      return {
        'success': true,
        'suggestions': suggestions,
        'urgent_count': suggestions.where((s) => s['urgency'] == 'URGENT').length,
        'soon_count': suggestions.where((s) => s['urgency'] == 'SOON').length,
      };
    } catch (e) {
      print('❌ Error generating reorder suggestions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🤖 PROACTIVE: Identify cost-saving opportunities
  Future<List<Map<String, dynamic>>> _identifyCostSavingOpportunities(
      String orgId) async {
    try {
      final opportunities = <Map<String, dynamic>>[];

      // Find items ordered from multiple suppliers
      final products = await supabase
          .from('supplier_product_pricing')
          .select('product_id, suppliers(*)')
          .eq('org_id', orgId);

      final productSuppliers = <String, List<Map<String, dynamic>>>{};
      for (final item in products) {
        final productId = item['product_id'] as String;
        if (!productSuppliers.containsKey(productId)) {
          productSuppliers[productId] = [];
        }
        productSuppliers[productId]!.add(item['suppliers'] as Map<String, dynamic>);
      }

      // Find consolidation opportunities
      for (final entry in productSuppliers.entries) {
        if (entry.value.length > 2) {
          // Get inventory item for product
          final product = await supabase
              .from('inventory')
              .select()
              .eq('id', entry.key)
              .maybeSingle();

          if (product != null) {
            opportunities.add({
              'type': 'consolidation',
              'product': product['item_name'],
              'current_suppliers': entry.value.length,
              'recommendation':
                  'Consider consolidating ${entry.value.length} suppliers to reduce complexity and negotiate better terms',
              'potential_savings': 'Medium',
            });
          }
        }
      }

      return opportunities;
    } catch (e) {
      print('⚠️ Error identifying opportunities: $e');
      return [];
    }
  }

  /// 📊 Get complete supplier dashboard for AI insights
  Future<Map<String, dynamic>> getSupplierDashboard(String orgId) async {
    try {
      final performance = await analyzeSupplierPerformance(orgId: orgId);
      final deliveries = await trackDeliveriesAndPredictDelays(orgId: orgId);
      final reorders = await generateReorderSuggestions(orgId: orgId);

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'org_id': orgId,
        'supplier_performance': performance,
        'delivery_tracking': deliveries,
        'reorder_suggestions': reorders,
        'overall_health': _calculateOverallHealth(performance, deliveries, reorders),
      };
    } catch (e) {
      print('❌ Error getting supplier dashboard: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Calculate overall supplier health score
  Map<String, dynamic> _calculateOverallHealth(
    Map<String, dynamic> performance,
    Map<String, dynamic> deliveries,
    Map<String, dynamic> reorders,
  ) {
    final alerts = (deliveries['alerts'] as List?)?.length ?? 0;
    final urgentReorders = (reorders['urgent_count'] as int?) ?? 0;

    int healthScore = 100;
    if (alerts > 0) healthScore -= (alerts * 5);
    if (urgentReorders > 0) healthScore -= (urgentReorders * 10);

    healthScore = healthScore.clamp(0, 100);

    return {
      'score': healthScore,
      'status': healthScore >= 80
          ? 'HEALTHY'
          : healthScore >= 60
              ? 'CAUTION'
              : 'CRITICAL',
      'alerts': alerts,
      'urgent_reorders': urgentReorders,
    };
  }
}
