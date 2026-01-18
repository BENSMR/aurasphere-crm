import 'package:supabase_flutter/supabase_flutter.dart';

class ClientService {
  static final ClientService _instance = ClientService._internal();
  
  ClientService._internal();
  
  factory ClientService() => _instance;
  
  final supabase = Supabase.instance.client;
  
  Future<List<Map<String, dynamic>>> getClients(String orgId) async {
    return [];
  }
}
