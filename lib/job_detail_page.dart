// lib/job_detail_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class JobDetailPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobDetailPage({super.key, required this.jobId, required this.jobTitle});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> inventoryItems = [];
  List<Map<String, dynamic>> stockMovements = [];
  List<Map<String, dynamic>> jobPhotos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      // Get user's org
      final org = await supabase.from('organizations').select('id').single();
      
      // Load inventory
      final inv = await supabase
          .from('inventory')
          .select()
          .eq('org_id', org['id']);
      
      // Load stock movements for this job
      final moves = await supabase
          .from('stock_movements')
          .select('*, inventory(name)')
          .eq('job_id', widget.jobId);
      
      if (mounted) {
        setState(() {
          inventoryItems = inv;
          stockMovements = moves;
          loading = false;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _logMaterialUsage() async {
    final org = await supabase.from('organizations').select('id').single();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Materials Used'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product picker
            DropdownButtonFormField<String>(
              hint: const Text('Select item'),
              items: inventoryItems.map((item) => DropdownMenuItem<String>(
                value: item['id'] as String,
                child: Text('${item['name']} (${item['quantity']} ${item['unit']})'),
              )).toList(),
              onChanged: (val) {
                // Handle selection
              },
            ),
            // Quantity
            const TextField(
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // TODO: Get selected product and quantity
              // Log stock movement
              await supabase.from('stock_movements').insert({
                'org_id': org['id'],
                'product_id': 'SELECTED_PRODUCT_ID',
                'job_id': widget.jobId,
                'quantity': -5, // Negative for usage
                'movement_type': 'usage',
                'notes': 'Used on job',
              });
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Log Usage'),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;
      
      // Upload to Supabase Storage
      final org = await supabase.from('organizations').select('id').single();
      final fileName = 'job_${widget.jobId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await image.readAsBytes();
      
      await supabase.storage
          .from('job-photos')
          .uploadBinary(fileName, bytes);
      
      // Save photo reference to job_photos table
      await supabase.from('job_photos').insert({
        'job_id': widget.jobId,
        'storage_path': fileName,
        'photo_type': 'progress',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      }
      
      _loadData(); // Refresh to show new photo
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jobTitle)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Job info (address, client, status)
                // ... existing job details ...

                // Materials used section
                if (stockMovements.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Materials Used', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: stockMovements.length,
                      itemBuilder: (context, index) {
                        final move = stockMovements[index];
                        final product = move['inventory'] as Map<String, dynamic>?;
                        return ListTile(
                          title: Text(product?['name'] ?? 'Unknown'),
                          subtitle: Text('${move['quantity'].abs()} ${product?['unit'] ?? 'units'} used'),
                          trailing: Text(move['quantity'] < 0 ? '-' : '+'),
                        );
                      },
                    ),
                  ),
                ],

                // Add material button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _logMaterialUsage,
                        icon: const Icon(Icons.add),
                        label: const Text('Log Materials'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
