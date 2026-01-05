-- 🏢 SUPPLIER MANAGEMENT TABLES
-- Enable for ALL subscriber plans

-- Suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    contact_person TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    postal_code TEXT,
    payment_terms TEXT DEFAULT '30 days',
    tax_id TEXT,
    reliability_rating DECIMAL(3,2) DEFAULT 4.0,
    quality_score DECIMAL(3,2) DEFAULT 4.0,
    lead_time_days INTEGER DEFAULT 5,
    is_preferred BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT valid_rating CHECK (reliability_rating >= 0 AND reliability_rating <= 5),
    CONSTRAINT valid_quality CHECK (quality_score >= 0 AND quality_score <= 5)
);

CREATE INDEX idx_suppliers_org_id ON suppliers(org_id);
CREATE INDEX idx_suppliers_is_preferred ON suppliers(org_id, is_preferred);
CREATE INDEX idx_suppliers_is_active ON suppliers(org_id, is_active);

-- Supplier product pricing table
CREATE TABLE IF NOT EXISTS supplier_product_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES inventory(id) ON DELETE CASCADE,
    unit_price DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    quantity_breaks JSONB, -- {"10": 9.50, "50": 9.00, "100": 8.50}
    minimum_order_quantity INTEGER DEFAULT 1,
    last_price_updated TIMESTAMP DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(supplier_id, product_id),
    CONSTRAINT positive_price CHECK (unit_price > 0)
);

CREATE INDEX idx_supplier_product_pricing_org ON supplier_product_pricing(org_id);
CREATE INDEX idx_supplier_product_pricing_supplier ON supplier_product_pricing(supplier_id);
CREATE INDEX idx_supplier_product_pricing_product ON supplier_product_pricing(product_id);
CREATE INDEX idx_supplier_product_pricing_price ON supplier_product_pricing(unit_price);

-- Purchase Orders
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    po_number TEXT NOT NULL UNIQUE,
    description TEXT,
    total_amount DECIMAL(12,2) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    due_date TIMESTAMP NOT NULL,
    delivered_at TIMESTAMP,
    delivery_notes TEXT,
    quality_issues_reported BOOLEAN DEFAULT FALSE,
    quality_issue_details TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT positive_amount CHECK (total_amount > 0)
);

CREATE INDEX idx_purchase_orders_org_id ON purchase_orders(org_id);
CREATE INDEX idx_purchase_orders_supplier_id ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(org_id, status);
CREATE INDEX idx_purchase_orders_due_date ON purchase_orders(due_date);
CREATE INDEX idx_purchase_orders_created_at ON purchase_orders(created_at);

-- Purchase Order Line Items
CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES inventory(id) ON DELETE RESTRICT,
    quantity_ordered INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT positive_quantity CHECK (quantity_ordered > 0),
    CONSTRAINT positive_unit_price CHECK (unit_price > 0)
);

CREATE INDEX idx_po_items_org_id ON purchase_order_items(org_id);
CREATE INDEX idx_po_items_po_id ON purchase_order_items(po_id);
CREATE INDEX idx_po_items_product_id ON purchase_order_items(product_id);

-- Supplier Performance History
CREATE TABLE IF NOT EXISTS supplier_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    review_period TEXT, -- 'monthly', 'quarterly'
    on_time_delivery_rate DECIMAL(5,2),
    quality_score DECIMAL(3,2),
    communication_rating DECIMAL(3,2),
    price_competitiveness DECIMAL(3,2),
    notes TEXT,
    month_year TEXT, -- 'January 2026' for aggregation
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(supplier_id, month_year)
);

CREATE INDEX idx_supplier_performance_org ON supplier_performance(org_id);
CREATE INDEX idx_supplier_performance_supplier ON supplier_performance(supplier_id);
CREATE INDEX idx_supplier_performance_month ON supplier_performance(month_year);

-- Delivery Tracking
CREATE TABLE IF NOT EXISTS delivery_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    tracking_number TEXT,
    carrier TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_transit', 'out_for_delivery', 'delivered', 'delayed')),
    estimated_delivery TIMESTAMP,
    actual_delivery TIMESTAMP,
    last_update TIMESTAMP,
    location TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_delivery_tracking_org ON delivery_tracking(org_id);
CREATE INDEX idx_delivery_tracking_po ON delivery_tracking(po_id);
CREATE INDEX idx_delivery_tracking_status ON delivery_tracking(status);

-- Price History (track price changes over time)
CREATE TABLE IF NOT EXISTS supplier_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES inventory(id) ON DELETE CASCADE,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2) NOT NULL,
    change_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT positive_new_price CHECK (new_price > 0)
);

CREATE INDEX idx_price_history_org ON supplier_price_history(org_id);
CREATE INDEX idx_price_history_supplier_product ON supplier_price_history(supplier_id, product_id);
CREATE INDEX idx_price_history_created_at ON supplier_price_history(created_at);

-- AI Agent Insights & Recommendations
CREATE TABLE IF NOT EXISTS ai_supplier_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    insight_type TEXT NOT NULL, -- 'cost_saving', 'delay_prediction', 'quality_issue', 'reorder_suggestion'
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    action_recommended TEXT,
    urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('low', 'normal', 'high', 'critical')),
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved')),
    relevant_supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    relevant_product_id UUID REFERENCES inventory(id) ON DELETE SET NULL,
    potential_savings DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT NOW(),
    acknowledged_at TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX idx_ai_insights_org ON ai_supplier_insights(org_id);
CREATE INDEX idx_ai_insights_status ON ai_supplier_insights(org_id, status);
CREATE INDEX idx_ai_insights_urgency ON ai_supplier_insights(org_id, urgency);
CREATE INDEX idx_ai_insights_created_at ON ai_supplier_insights(created_at);

-- RLS POLICIES --

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplier_product_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplier_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplier_price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_supplier_insights ENABLE ROW LEVEL SECURITY;

-- ORG-based RLS policies
CREATE POLICY "suppliers_org_access" ON suppliers
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);

CREATE POLICY "supplier_pricing_org_access" ON supplier_product_pricing
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);

CREATE POLICY "purchase_orders_org_access" ON purchase_orders
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);

CREATE POLICY "purchase_order_items_org_access" ON purchase_order_items
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);

CREATE POLICY "supplier_performance_org_access" ON supplier_performance
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);

CREATE POLICY "delivery_tracking_org_access" ON delivery_tracking
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);

CREATE POLICY "price_history_org_access" ON supplier_price_history
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);

CREATE POLICY "ai_insights_org_access" ON ai_supplier_insights
    USING (org_id = auth.jwt() ->> 'org_id'::text)
    WITH CHECK (org_id = auth.jwt() ->> 'org_id'::text);
