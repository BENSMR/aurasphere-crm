import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:math';

final _logger = Logger();

/// Team Member Control Service
/// Manages team members with unique codes, permissions, and approval workflow
/// Controlled entirely by the CEO/Owner
class TeamMemberControlService {
  static final TeamMemberControlService _instance =
      TeamMemberControlService._internal();

  final supabase = Supabase.instance.client;

  TeamMemberControlService._internal();

  factory TeamMemberControlService() {
    return _instance;
  }

  /// Generate unique team member code
  String _generateMemberCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'TM-${List.generate(8, (index) => chars[random.nextInt(chars.length)])
            .join()}';
  }

  /// Add team member with full control
  Future<Map<String, dynamic>> addTeamMember({
    required String orgId,
    required String email,
    required String fullName,
    required String role, // 'member', 'technician', 'manager'
    required String permissions,
    required String description,
  }) async {
    try {
      _logger.i('➕ Adding team member: $fullName');

      // Check if member already exists
      final existing = await supabase
          .from('org_members')
          .select('id')
          .eq('org_id', orgId)
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        return {'success': false, 'error': 'Member already exists'};
      }

      // Generate unique code
      final memberCode = _generateMemberCode();

      // Create member record
      final result = await supabase
          .from('org_members')
          .insert({
            'org_id': orgId,
            'email': email,
            'member_code': memberCode,
            'full_name': fullName,
            'role': role,
            'permissions': permissions,
            'description': description,
            'is_active': true,
            'approval_status': 'pending', // Needs CEO approval
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('✅ Team member added with code: $memberCode');
      return {
        'success': true,
        'member_code': memberCode,
        'member': result,
      };
    } catch (e) {
      _logger.e('❌ Error adding team member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Approve team member (CEO only)
  Future<Map<String, dynamic>> approveMember({
    required String memberId,
    required String approvedBy,
  }) async {
    try {
      _logger.i('✅ Approving team member: $memberId');

      final result = await supabase
          .from('org_members')
          .update({
            'approval_status': 'approved',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', memberId)
          .select()
          .single();

      _logger.i('✅ Team member approved');
      return {'success': true, 'member': result};
    } catch (e) {
      _logger.e('❌ Error approving member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reject team member (CEO only)
  Future<Map<String, dynamic>> rejectMember({
    required String memberId,
    required String rejectionReason,
  }) async {
    try {
      _logger.i('❌ Rejecting team member: $memberId');

      final result = await supabase
          .from('org_members')
          .update({
            'approval_status': 'rejected',
            'rejection_reason': rejectionReason,
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', memberId)
          .select()
          .single();

      _logger.i('✅ Team member rejected');
      return {'success': true, 'member': result};
    } catch (e) {
      _logger.e('❌ Error rejecting member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all team members with codes
  Future<List<Map<String, dynamic>>> getTeamMembers(String orgId) async {
    try {
      _logger.i('👥 Fetching team members for org: $orgId');

      final members = await supabase
          .from('org_members')
          .select('*')
          .eq('org_id', orgId)
          .order('created_at', ascending: false);

      _logger.i('✅ Loaded ${members.length} team members');
      return List<Map<String, dynamic>>.from(members);
    } catch (e) {
      _logger.e('❌ Error fetching team members: $e');
      return [];
    }
  }

  /// Update member permissions (CEO only)
  Future<Map<String, dynamic>> updateMemberPermissions({
    required String memberId,
    required String permissions,
  }) async {
    try {
      _logger.i('🔒 Updating permissions for member: $memberId');

      final result = await supabase
          .from('org_members')
          .update({
            'permissions': permissions,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', memberId)
          .select()
          .single();

      _logger.i('✅ Permissions updated');
      return {'success': true, 'member': result};
    } catch (e) {
      _logger.e('❌ Error updating permissions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Deactivate team member (CEO only)
  Future<Map<String, dynamic>> deactivateMember(String memberId) async {
    try {
      _logger.i('🚫 Deactivating team member: $memberId');

      final result = await supabase
          .from('org_members')
          .update({
            'is_active': false,
            'deactivated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', memberId)
          .select()
          .single();

      _logger.i('✅ Team member deactivated');
      return {'success': true, 'member': result};
    } catch (e) {
      _logger.e('❌ Error deactivating member: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get member by code (for device association)
  Future<Map<String, dynamic>?> getMemberByCode(String memberCode) async {
    try {
      _logger.i('🔍 Looking up member by code: $memberCode');

      final result = await supabase
          .from('org_members')
          .select('*')
          .eq('member_code', memberCode)
          .maybeSingle();

      if (result != null) {
        _logger.i('✅ Member found: ${result['full_name']}');
      }
      return result;
    } catch (e) {
      _logger.e('❌ Error looking up member: $e');
      return null;
    }
  }

  /// Get pending approvals
  Future<List<Map<String, dynamic>>> getPendingApprovals(String orgId) async {
    try {
      _logger.i('⏳ Fetching pending approvals');

      final pending = await supabase
          .from('org_members')
          .select('*')
          .eq('org_id', orgId)
          .eq('approval_status', 'pending')
          .order('created_at', ascending: true);

      _logger.i('✅ Found ${pending.length} pending approvals');
      return List<Map<String, dynamic>>.from(pending);
    } catch (e) {
      _logger.e('❌ Error fetching pending approvals: $e');
      return [];
    }
  }

  /// Get member activity log
  Future<List<Map<String, dynamic>>> getMemberActivityLog(String memberId) async {
    try {
      _logger.i('📋 Fetching activity log for member: $memberId');

      final logs = await supabase
          .from('member_activity_logs')
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(logs);
    } catch (e) {
      _logger.e('❌ Error fetching activity log: $e');
      return [];
    }
  }

  /// Log member activity
  Future<void> logActivity({
    required String memberId,
    required String orgId,
    required String action,
    required String description,
  }) async {
    try {
      await supabase.from('member_activity_logs').insert({
        'member_id': memberId,
        'org_id': orgId,
        'action': action,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('❌ Error logging activity: $e');
    }
  }

  /// Get member statistics
  Future<Map<String, dynamic>> getMemberStats(String orgId) async {
    try {
      final members = await supabase
          .from('org_members')
          .select('approval_status, is_active')
          .eq('org_id', orgId);

      int approved = 0;
      int pending = 0;
      int rejected = 0;
      int active = 0;

      for (var member in members) {
        if (member['approval_status'] == 'approved') approved++;
        if (member['approval_status'] == 'pending') pending++;
        if (member['approval_status'] == 'rejected') rejected++;
        if (member['is_active'] == true) active++;
      }

      return {
        'total': members.length,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
        'active': active,
      };
    } catch (e) {
      _logger.e('❌ Error getting stats: $e');
      return {};
    }
  }
}
