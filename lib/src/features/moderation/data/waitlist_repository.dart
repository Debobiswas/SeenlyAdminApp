import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/waitlist_entry.dart';

class WaitlistRepository {
  WaitlistRepository(this._client);

  final SupabaseClient _client;

  Future<List<WaitlistEntry>> fetchWaitlistEntries() async {
    final response = await _client
        .from('waitlist')
        .select()
        .order('created_at', ascending: false);

    return response
        .cast<Map<String, dynamic>>()
        .map(WaitlistEntry.fromJson)
        .toList();
  }

  Future<void> inviteEntry(String id) async {
    // Perform delete/archive action on the waitlist table
    await _client.from('waitlist').delete().eq('id', id);
  }

  Future<void> archiveEntry(String id) async {
    // Perform delete/archive action on the waitlist table
    await _client.from('waitlist').delete().eq('id', id);
  }
}
