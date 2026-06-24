import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/moderation_profile.dart';
import '../../../shared/models/waitlist_entry.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/moderation_repository.dart';
import '../data/waitlist_repository.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ModerationRepository(client);
});

final moderationSearchProvider = StateProvider<String>((ref) => '');

final showAllProfilesProvider = StateProvider<bool>((ref) => false);

final pendingProfilesProvider =
    FutureProvider.autoDispose.family<List<ModerationProfile>, AccountType?>((ref, accountType) async {
  final repository = ref.watch(moderationRepositoryProvider);
  final search = ref.watch(moderationSearchProvider);
  final showAll = ref.watch(showAllProfilesProvider);

  return repository.fetchPendingProfiles(
    accountType: accountType,
    search: search,
    pendingOnly: !showAll,
  );
});

final selectedProfileProvider =
    StateProvider.autoDispose.family<ModerationProfile?, AccountType?>((ref, accountType) => null);

final profileDetailsProvider =
    FutureProvider.autoDispose.family<ModerationProfile, String>((ref, profileId) async {
  final repository = ref.watch(moderationRepositoryProvider);
  return repository.fetchProfileDetails(profileId);
});

// Waitlist Providers
final waitlistRepositoryProvider = Provider<WaitlistRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WaitlistRepository(client);
});

final waitlistEntriesProvider =
    FutureProvider.autoDispose<List<WaitlistEntry>>((ref) async {
  final repository = ref.watch(waitlistRepositoryProvider);
  return repository.fetchWaitlistEntries();
});

