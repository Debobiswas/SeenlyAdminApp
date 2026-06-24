import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_report.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/models/moderation_profile.dart';

class DisputesRepository {
  DisputesRepository(this._client);

  final SupabaseClient _client;

  Future<List<UserReport>> fetchUserReports() async {
    final response = await _client
        .from('user_reports')
        .select('''
          id,
          reporter_id,
          reported_user_id,
          reason,
          created_at,
          reservation_id,
          reporter:profiles!reporter_id(full_name, email),
          reported:profiles!reported_user_id(full_name, email)
        ''')
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((data) {
      final map = Map<String, dynamic>.from(data);
      // Map join fields correctly
      if (map['reporter'] != null) {
        map['reporter_name'] = map['reporter']['full_name'];
        map['reporter_email'] = map['reporter']['email'];
      }
      if (map['reported'] != null) {
        map['reported_name'] = map['reported']['full_name'];
        map['reported_email'] = map['reported']['email'];
      }
      return UserReport.fromJson(map);
    }).toList();
  }

  Future<List<Reservation>> fetchReservations() async {
    final response = await _client
        .from('reservations')
        .select('''
          id,
          user_id,
          venue_id,
          campaign_id,
          status,
          proof_url,
          redeemed_at,
          expires_at,
          created_at,
          profiles!user_id(full_name),
          venues!venue_id(name),
          campaigns!campaign_id(title)
        ''')
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((data) {
      final map = Map<String, dynamic>.from(data);
      return Reservation.fromJson(map);
    }).toList();
  }

  Future<void> approveProof(String reservationId) async {
    await _client
        .from('reservations')
        .update({'status': 'completed'})
        .eq('id', reservationId);
  }

  Future<void> rejectProofAndStrike({
    required String reservationId,
    required String userId,
    required String reason,
  }) async {
    // 1. Update reservation status to rejected
    await _client
        .from('reservations')
        .update({'status': 'rejected'})
        .eq('id', reservationId);

    // 2. Fetch profile strikes count
    final profile = await _client
        .from('profiles')
        .select('strikes')
        .eq('id', userId)
        .single();
    final currentStrikes = (profile['strikes'] as num?)?.toInt() ?? 0;

    // 3. Increment strikes and update
    await _client
        .from('profiles')
        .update({'strikes': currentStrikes + 1})
        .eq('id', userId);

    // 4. Log audit event or report action if needed (optional)
  }

  Future<List<ModerationProfile>> fetchFlaggedProfiles() async {
    // Fetch users who have strikes > 0
    final response = await _client
        .from('profiles')
        .select()
        .gt('strikes', 0)
        .order('strikes', ascending: false);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ModerationProfile.fromJson)
        .toList();
  }

  Future<void> suspendUser(String userId) async {
    await _client
        .from('profiles')
        .update({'status': 'rejected'}) // or 'suspended' if implemented
        .eq('id', userId);
  }

  Future<void> unsuspendUser(String userId) async {
    await _client
        .from('profiles')
        .update({'status': 'active', 'strikes': 0})
        .eq('id', userId);
  }
}
