// features/clients/client_list_page.dart
// 🔴 DEPRECATED - This module is disabled
// 
// The legacy modularized client list has been consolidated into:
// → See lib/client_list_page.dart (the active, working version)
//
// Why disabled:
// - This version depends on utility files that don't exist
// - The root lib/client_list_page.dart provides the same functionality

import 'package:flutter/material.dart';

/// This class exists only to prevent import errors.
/// The actual implementation is in lib/client_list_page.dart
class ClientListPageLegacy extends StatelessWidget {
  const ClientListPageLegacy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Client Module (Disabled)'),
      ),
      body: const Center(
        child: Text('This module is deprecated.\nPlease use lib/client_list_page.dart'),
      ),
    );
  }
}
