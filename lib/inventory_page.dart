// lib/inventory_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> inventory = [];
  bool loading = true;

  Future<void> _loadInventory() async {
    setState(() => loading = true);
    try {
      final org = await supabase.from('organizations').select('id').single();
      final data = await supabase
          .from('inventory')
          .select()
          .eq('org_id', org['id'])
          .order('name');
      if (mounted) setState(() => inventory = data);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addInventoryItem() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'piece');
    final minStockCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Initial Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (piece, meter, kg)')),
              TextField(
                controller: minStockCtrl,
                decoration: const InputDecoration(labelText: 'Min Stock Alert'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              final minStock = int.tryParse(minStockCtrl.text) ?? 0;
              
              final org = await supabase.from('organizations').select('id').single();
              await supabase.from('inventory').insert({
                'org_id': org['id'],
                'name': nameCtrl.text.trim(),
                'quantity': qty,
                'unit': unitCtrl.text.trim(),
                'min_stock': minStock,
              });
              Navigator.pop(context);
              _loadInventory();
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : inventory.isEmpty
              ? const Center(child: Text('No inventory items'))
              : ListView.builder(
                  itemCount: inventory.length,
                  itemBuilder: (context, index) {
                    final item = inventory[index];
                    final isLowStock = item['quantity'] < item['min_stock'];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(item['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['quantity']} ${item['unit']}'),
                            if (isLowStock) 
                              const Text('⚠️ Low stock!', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editItem(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addStock(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addInventoryItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    // TODO: Edit min_stock or unit
  }

  void _addStock(Map<String, dynamic> item) async {
    final qtyCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock: ${item['name']}'),
        content: TextField(
          controller: qtyCtrl,
          decoration: const InputDecoration(labelText: 'Quantity to Add'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              if (qty <= 0) return;
              
              // Update inventory quantity
              await supabase
                  .from('inventory')
                  .update({'quantity': item['quantity'] + qty})
                  .eq('id', item['id']);
              
              // Log stock movement
              final org = await supabase.from('organizations').select('id').single();
              await supabase.from('stock_movements').insert({
                'org_id': org['id'],
                'product_id': item['id'],
                'quantity': qty,
                'movement_type': 'purchase',
                'notes': 'Manual stock addition',
              });
              
              Navigator.pop(context);
              _loadInventory();
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }
}
