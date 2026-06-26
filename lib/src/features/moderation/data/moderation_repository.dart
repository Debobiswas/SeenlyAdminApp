import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/audit_log_entry.dart';
import '../../../shared/models/moderation_profile.dart';

class ModerationRepository {
  ModerationRepository(this._client);

  static const _approveProfileFunction = 'admin_approve_profile';
  static const _rejectProfileFunction = 'admin_reject_profile';
  static const _auditLogsFunction = 'admin_audit_logs';

  final SupabaseClient _client;

  Future<List<ModerationProfile>> fetchPendingProfiles({
    AccountType? accountType,
    String search = '',
    Set<ProfileStatus>? statuses,
  }) async {
    if (statuses != null && statuses.isEmpty) {
      return [];
    }

    const fields = 'id, email, full_name, name, role, tier, status, created_at, instagram_handle, tiktok_handle';
    var query = _client.from('profiles').select(fields);
    
    if (statuses != null) {
      final hasPending = statuses.contains(ProfileStatus.pending);
      final hasActive = statuses.contains(ProfileStatus.active);
      if (hasPending && hasActive) {
        // No status filter -> show all users
      } else if (hasPending) {
        query = query.eq('status', 'pending');
      } else if (hasActive) {
        query = query.eq('status', 'active');
      } else {
        query = query.inFilter('status', statuses.map((s) => s.name).toList());
      }
    } else {
      query = query.eq('status', 'pending');
    }

    final response = await query.order('created_at', ascending: false);
    final list = (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ModerationProfile.fromJson)
        .toList();

    return list.where((profile) {
      final matchesType =
          accountType == null || profile.accountType == accountType;
      final normalized = search.trim().toLowerCase();
      final matchesSearch = normalized.isEmpty ||
          profile.fullName.toLowerCase().contains(normalized) ||
          profile.email.toLowerCase().contains(normalized) ||
          (profile.username ?? '').toLowerCase().contains(normalized);
      return matchesType && matchesSearch;
    }).toList();
  }

  Future<ModerationProfile> fetchProfileDetails(String profileId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', profileId)
        .single();
    return ModerationProfile.fromJson(response);
  }

  Future<void> updateStrikes(String userId, int strikes) async {
    await _client
        .from('profiles')
        .update({'strikes': strikes})
        .eq('id', userId);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> updateProfileStatus(String userId, ProfileStatus status) async {
    await _client
        .from('profiles')
        .update({'status': status.name})
        .eq('id', userId);
  }

  Future<void> approveProfile(String userId) async {
    await _client.functions.invoke(_approveProfileFunction, body: {
      'target_user_id': userId,
    });
  }

  Future<void> rejectProfile({
    required String userId,
    required String reason,
  }) async {
    await _client.functions.invoke(_rejectProfileFunction, body: {
      'target_user_id': userId,
      'rejection_reason': reason,
    });
  }

  Future<List<AuditLogEntry>> fetchAuditLogs() async {
    final response = await _client.functions.invoke(_auditLogsFunction);

    return _asList(response.data, functionName: _auditLogsFunction)
        .map(AuditLogEntry.fromJson)
        .toList();
  }

  List<Map<String, dynamic>> _asList(
    dynamic data, {
    required String functionName,
  }) {
    var payload = data;
    if (data is Map) {
      payload = data['data'] ?? data['logs'] ?? data;
    }

    if (payload is! List) {
      throw StateError(
        'Edge Function "$functionName" must return a list, '
        'or an object with a data/logs list.',
      );
    }

    return payload.map((entry) {
      if (entry is Map<String, dynamic>) {
        return entry;
      }
      if (entry is Map) {
        return Map<String, dynamic>.from(entry);
      }
      throw StateError(
        'Edge Function "$functionName" returned a non-object list item.',
      );
    }).toList();
  }
}
