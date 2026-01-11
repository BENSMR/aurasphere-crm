import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

interface SupplierAlert {
  org_id: string;
  insight_type: string;
  title: string;
  description: string;
  action_recommended: string;
  urgency: "low" | "normal" | "high" | "critical";
  relevant_supplier_id?: string;
  relevant_product_id?: string;
  potential_savings?: number;
}

interface ReorderSuggestion {
  org_id: string;
  product_name: string;
  current_quantity: number;
  reorder_level: number;
  recommended_order_quantity: number;
  urgency: "URGENT" | "SOON" | "NORMAL";
}

interface DeliveryAlert {
  org_id: string;
  po_id: string;
  supplier_name: string;
  due_date: string;
  expected_delivery: string;
  days_until_due: number;
  alert_type: "DELAY_PREDICTED" | "DUE_SOON";
}

/**
 * 🤖 PROACTIVE AI SUPPLIER AGENT - Edge Function
 * 
 * Runs autonomously to:
 * - Analyze supplier performance
 * - Predict delivery delays
 * - Generate reorder suggestions
 * - Identify cost-saving opportunities
 * - Create AI-powered insights
 * 
 * Call via: POST /functions/v1/supplier-ai-agent
 * Body: { "org_id": "string", "action": "analyze|predict|suggest|insights" }
 */

const client = createClient(supabaseUrl, supabaseServiceKey);

Deno.serve(async (req: Request) => {
  try {
    // CORS
    if (req.method === "OPTIONS") {
      return new Response("OK", {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    const { org_id, action } = await req.json();

    if (!org_id || !action) {
      return new Response(JSON.stringify({ error: "Missing org_id or action" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`🤖 AI Agent: Running ${action} for org ${org_id}`);

    let result = {};

    switch (action) {
      case "analyze":
        result = await analyzeSuppliers(org_id);
        break;
      case "predict":
        result = await predictDelays(org_id);
        break;
      case "suggest":
        result = await generateReorders(org_id);
        break;
      case "insights":
        result = await generateInsights(org_id);
        break;
      case "full":
        // Run all analyses
        result = await runFullAnalysis(org_id);
        break;
      default:
        return new Response(JSON.stringify({ error: "Unknown action" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
    }

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("❌ AI Agent Error:", error);
    return new Response(JSON.stringify({ error: (error as any).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

/**
 * 📊 ANALYZE SUPPLIERS - Performance metrics
 */
async function analyzeSuppliers(orgId: string) {
  console.log(`📊 Analyzing suppliers for ${orgId}`);

  const { data: suppliers } = await client
    .from("suppliers")
    .select("*")
    .eq("org_id", orgId);

  if (!suppliers || suppliers.length === 0) {
    return { success: false, message: "No suppliers found" };
  }

  const analysis = [];

  for (const supplier of suppliers) {
    // Get orders from this supplier (last 90 days)
    const { data: orders } = await client
      .from("purchase_orders")
      .select("*")
      .eq("supplier_id", supplier.id)
      .eq("org_id", orgId)
      .gte("created_at", new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString());

    if (!orders || orders.length === 0) continue;

    const totalSpend = orders.reduce((sum: number, o: any) => sum + o.total_amount, 0);
    const deliveredOnTime = orders.filter(
      (o: any) => o.delivered_at && new Date(o.delivered_at) < new Date(o.due_date)
    ).length;

    const onTimeRate = (deliveredOnTime / orders.length * 100).toFixed(1);

    analysis.push({
      supplier_id: supplier.id,
      name: supplier.name,
      totalOrders: orders.length,
      totalSpend: totalSpend.toFixed(2),
      onTimeRate: `${onTimeRate}%`,
      avgOrderValue: (totalSpend / orders.length).toFixed(2),
      recommendation:
        Number(onTimeRate) < 80
          ? `⚠️ ${supplier.name}: Low on-time rate. Consider alternatives.`
          : `✅ ${supplier.name}: Reliable supplier`,
    });
  }

  return { success: true, suppliers_analyzed: analysis.length, analysis };
}

/**
 * 📦 PREDICT DELAYS - Delivery predictions
 */
async function predictDelays(orgId: string) {
  console.log(`📦 Predicting delays for ${orgId}`);

  const { data: pendingOrders } = await client
    .from("purchase_orders")
    .select("*, suppliers(*)")
    .eq("org_id", orgId)
    .in("status", ["pending", "processing"]);

  if (!pendingOrders || pendingOrders.length === 0) {
    return { success: true, alerts: [], pending_count: 0 };
  }

  const alerts: DeliveryAlert[] = [];

  for (const order of pendingOrders) {
    const dueDate = new Date(order.due_date);
    const supplier = order.suppliers;
    const leadTime = supplier.lead_time_days || 5;
    const expectedDelivery = new Date(Date.now() + leadTime * 24 * 60 * 60 * 1000);
    const daysUntilDue = Math.floor((dueDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));

    if (expectedDelivery > dueDate || daysUntilDue < 3) {
      alerts.push({
        org_id: orgId,
        po_id: order.id,
        supplier_name: supplier.name,
        due_date: order.due_date,
        expected_delivery: expectedDelivery.toISOString(),
        days_until_due: daysUntilDue,
        alert_type: expectedDelivery > dueDate ? "DELAY_PREDICTED" : "DUE_SOON",
      });
    }
  }

  // Store alerts in database
  if (alerts.length > 0) {
    for (const alert of alerts) {
      await client.from("ai_supplier_insights").insert({
        org_id: alert.org_id,
        insight_type: "delivery_alert",
        title: `${alert.alert_type}: ${alert.supplier_name}`,
        description: `Order due ${alert.days_until_due} days from now`,
        action_recommended:
          alert.alert_type === "DELAY_PREDICTED"
            ? "Consider expedited shipping or alternative supplier"
            : "Prepare for inventory update",
        urgency: alert.days_until_due < 2 ? "critical" : "high",
        relevant_supplier_id: (
          await client
            .from("suppliers")
            .select("id")
            .eq("name", alert.supplier_name)
            .single()
        ).data?.id,
      });
    }
  }

  return { success: true, alerts_detected: alerts.length, alerts };
}

/**
 * 🔔 GENERATE REORDERS - Consumption-based suggestions
 */
async function generateReorders(orgId: string) {
  console.log(`🔔 Generating reorder suggestions for ${orgId}`);

  const { data: inventory } = await client
    .from("inventory")
    .select("*")
    .eq("org_id", orgId);

  if (!inventory || inventory.length === 0) {
    return { success: true, suggestions: [] };
  }

  const suggestions: ReorderSuggestion[] = [];

  for (const item of inventory) {
    // Get usage history (last 30 days)
    const { data: usage } = await client
      .from("stock_movements")
      .select("*")
      .eq("product_id", item.id)
      .eq("org_id", orgId)
      .eq("movement_type", "used")
      .gte("created_at", new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString());

    if (!usage || usage.length === 0) continue;

    const totalUsed = usage.reduce((sum: number, u: any) => sum + u.quantity, 0);
    const consumptionPerDay = totalUsed / 30;
    const daysUntilStockout = item.quantity / consumptionPerDay;

    if (
      item.low_stock_threshold &&
      item.quantity < item.low_stock_threshold
    ) {
      const quantityToOrder = Math.ceil(consumptionPerDay * 30); // 30-day supply

      const suggestion: ReorderSuggestion = {
        org_id: orgId,
        product_name: item.item_name,
        current_quantity: item.quantity,
        reorder_level: item.low_stock_threshold,
        recommended_order_quantity: quantityToOrder,
        urgency: daysUntilStockout < 7 ? "URGENT" : "SOON",
      };

      suggestions.push(suggestion);

      // Create insight
      await client.from("ai_supplier_insights").insert({
        org_id: orgId,
        insight_type: "reorder_suggestion",
        title: `Reorder Needed: ${item.item_name}`,
        description: `${item.quantity} units remaining, ${daysUntilStockout.toFixed(1)} days until stockout`,
        action_recommended: `Create PO for ${quantityToOrder} units`,
        urgency: daysUntilStockout < 7 ? "critical" : "high",
        relevant_product_id: item.id,
      });
    }
  }

  return { success: true, suggestions_generated: suggestions.length, suggestions };
}

/**
 * 💡 GENERATE INSIGHTS - Multi-factor analysis
 */
async function generateInsights(orgId: string) {
  console.log(`💡 Generating AI insights for ${orgId}`);

  const insights: SupplierAlert[] = [];

  // 1. Consolidation opportunities
  const { data: productSuppliers } = await client
    .from("supplier_product_pricing")
    .select("product_id")
    .eq("org_id", orgId);

  const productCounts: Record<string, number> = {};
  productSuppliers?.forEach((ps: any) => {
    productCounts[ps.product_id] =
      (productCounts[ps.product_id] || 0) + 1;
  });

  for (const [productId, count] of Object.entries(productCounts)) {
    if (count > 3) {
      const { data: product } = await client
        .from("inventory")
        .select("item_name")
        .eq("id", productId)
        .single();

      if (product) {
        insights.push({
          org_id: orgId,
          insight_type: "cost_saving",
          title: `Supplier Consolidation: ${product.item_name}`,
          description: `${count} suppliers provide this product`,
          action_recommended: "Consider consolidating to 2-3 preferred suppliers for better pricing",
          urgency: "normal",
          relevant_product_id: productId,
          potential_savings: 500, // Estimate
        });
      }
    }
  }

  // Store all insights
  for (const insight of insights) {
    await client.from("ai_supplier_insights").insert(insight);
  }

  return { success: true, insights_generated: insights.length, insights };
}

/**
 * 🚀 RUN FULL ANALYSIS - All checks at once
 */
async function runFullAnalysis(orgId: string) {
  console.log(`🚀 Running full analysis for ${orgId}`);

  const results = {
    analysis: await analyzeSuppliers(orgId),
    delays: await predictDelays(orgId),
    reorders: await generateReorders(orgId),
    insights: await generateInsights(orgId),
    timestamp: new Date().toISOString(),
  };

  return { success: true, data: results };
}
