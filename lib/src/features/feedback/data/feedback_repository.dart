import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/feedback_entry.dart';

class FeedbackRepository {
  FeedbackRepository(this._client);

  final SupabaseClient _client;

  Future<List<FeedbackEntry>> fetchFeedback() async {
    final feedbackResponse = await _client
        .from('feedback')
        .select('*')
        .order('created_at', ascending: false);

    final feedbackList = (feedbackResponse as List<dynamic>)
        .cast<Map<String, dynamic>>();

    if (feedbackList.isEmpty) {
      return [];
    }

    final userIds = feedbackList
        .map((e) => e['user_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    final Map<String, String> userNames = {};

    if (userIds.isNotEmpty) {
      final profilesResponse = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);

      final profilesList = (profilesResponse as List<dynamic>)
          .cast<Map<String, dynamic>>();

      for (var profile in profilesList) {
        final id = profile['id'] as String?;
        final fullName = profile['full_name'] as String?;
        if (id != null && fullName != null) {
          userNames[id] = fullName;
        }
      }
    }

    return feedbackList.map((data) {
      final map = Map<String, dynamic>.from(data);
      final uId = map['user_id'] as String?;
      if (uId != null && userNames.containsKey(uId)) {
        map['user_name'] = userNames[uId];
      }
      return FeedbackEntry.fromJson(map);
    }).toList();
  }

  Future<void> resolveFeedback(String feedbackId) async {
    await _client
        .from('feedback')
        .update({'status': 'resolved'})
        .eq('id', feedbackId);
  }
}
