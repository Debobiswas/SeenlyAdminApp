import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/feedback_repository.dart';
import '../../../shared/models/feedback_entry.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeedbackRepository(client);
});

final feedbackListProvider =
    FutureProvider.autoDispose<List<FeedbackEntry>>((ref) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.fetchFeedback();
});
