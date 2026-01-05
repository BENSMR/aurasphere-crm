-- ✅ FIX #7: Database Indexes for Supplier AI Queries
-- Critical indexes to optimize supplier analysis performance
-- Without these, queries scan 100% of rows causing 500ms-2s latency

-- Primary org isolation index
CREATE INDEX IF NOT EXISTS idx_suppliers_org_id 
  ON suppliers(org_id);

-- Purchase order queries (most frequently used)
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_id_org_id 
  ON purchase_orders(supplier_id, org_id);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_created_at_org_id 
  ON purchase_orders(created_at DESC, org_id)
  WHERE status IN ('pending', 'processing');

-- Delivery tracking index
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status_due_date
  ON purchase_orders(status, due_date);

-- Product pricing queries
CREATE INDEX IF NOT EXISTS idx_supplier_product_pricing_product_id 
  ON supplier_product_pricing(product_id);

-- Stock movement tracking
CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id_org_id 
  ON stock_movements(product_id, org_id, movement_type);

-- Compound index for complex analysis queries
CREATE INDEX IF NOT EXISTS idx_purchase_orders_analysis
  ON purchase_orders(org_id, supplier_id, created_at DESC, delivered_at, due_date);

-- Health scoring queries
CREATE INDEX IF NOT EXISTS idx_suppliers_org_id_created_at
  ON suppliers(org_id, created_at DESC);

-- Performance verification queries
CREATE INDEX IF NOT EXISTS idx_supplier_product_pricing_org_id
  ON supplier_product_pricing(org_id, product_id);
