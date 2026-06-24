import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_profile.dart';
import '../services/auth_repository.dart';
import 'supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, AdminSessionState>(
  SessionController.new,
);

class AdminSessionState {
  const AdminSessionState({
    this.session,
    this.profile,
    this.unauthorizedMessage,
  });

  final Session? session;
  final AdminProfile? profile;
  final String? unauthorizedMessage;

  bool get isAuthenticated => session != null;
  bool get isAuthorized => profile?.hasAdminAccess ?? false;
}

class SessionController extends AsyncNotifier<AdminSessionState> {
  late final AuthRepository _repository = ref.read(authRepositoryProvider);

  @override
  Future<AdminSessionState> build() async {
    final session = _repository.currentSession;
    if (session == null) {
      return const AdminSessionState();
    }

    final profile = await _repository.fetchAdminProfile(session.user.id);
    if (profile == null || !profile.hasAdminAccess) {
      await _repository.signOut();
      return const AdminSessionState(
        unauthorizedMessage: 'Unauthorized access. Admin account required.',
      );
    }

    return AdminSessionState(session: session, profile: profile);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await _repository.signIn(email: email, password: password);
      final profile = await _repository.fetchAdminProfile(session.user.id);

      if (profile == null || !profile.hasAdminAccess) {
        await _repository.signOut();
        return const AdminSessionState(
          unauthorizedMessage: 'Unauthorized access. Admin account required.',
        );
      }

      return AdminSessionState(session: session, profile: profile);
    });
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(AdminSessionState());
  }
}

