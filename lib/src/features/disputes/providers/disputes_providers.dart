import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/disputes_repository.dart';
import '../../../shared/models/user_report.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/models/moderation_profile.dart';

final disputesRepositoryProvider = Provider<DisputesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DisputesRepository(client);
});

final userReportsProvider =
    FutureProvider.autoDispose<List<UserReport>>((ref) async {
  final repo = ref.watch(disputesRepositoryProvider);
  return repo.fetchUserReports();
});

final reservationsProvider =
    FutureProvider.autoDispose<List<Reservation>>((ref) async {
  final repo = ref.watch(disputesRepositoryProvider);
  return repo.fetchReservations();
});

final flaggedProfilesProvider =
    FutureProvider.autoDispose<List<ModerationProfile>>((ref) async {
  final repo = ref.watch(disputesRepositoryProvider);
  return repo.fetchFlaggedProfiles();
});
