import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/configs_repository.dart';
import '../../../shared/models/feature_flag.dart';

final configsRepositoryProvider = Provider<ConfigsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ConfigsRepository(client);
});

final featureFlagsProvider =
    FutureProvider.autoDispose<List<FeatureFlag>>((ref) async {
  final repo = ref.watch(configsRepositoryProvider);
  return repo.fetchFeatureFlags();
});
