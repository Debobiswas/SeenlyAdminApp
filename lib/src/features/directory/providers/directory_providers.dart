import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/directory_repository.dart';
import '../../../shared/models/venue.dart';
import '../../../shared/models/campaign.dart';

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DirectoryRepository(client);
});

final venuesListProvider =
    FutureProvider.autoDispose<List<Venue>>((ref) async {
  final repo = ref.watch(directoryRepositoryProvider);
  return repo.fetchVenues();
});

final campaignsListProvider =
    FutureProvider.autoDispose<List<Campaign>>((ref) async {
  final repo = ref.watch(directoryRepositoryProvider);
  return repo.fetchCampaigns();
});
