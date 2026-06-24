import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = response.session;
    if (session == null) {
      throw AuthException('Sign-in failed. Please try again.');
    }

    return session;
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<AdminProfile?> fetchAdminProfile(String userId) async {
    final response = await _client
        .from('admins')
        .select('id, email, full_name, is_admin, role')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AdminProfile.fromJson(response);
  }
}
