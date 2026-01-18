import 'package:supabase_flutter/supabase_flutter.dart';

class JobService {
  static final JobService _instance = JobService._internal();
  
  JobService._internal();
  
  factory JobService() => _instance;
  
  final supabase = Supabase.instance.client;
  
  Future<List<Map<String, dynamic>>> getJobs(String orgId) async {
    return [];
  }
}
