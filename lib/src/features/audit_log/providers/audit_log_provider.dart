import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/audit_log_entry.dart';
import '../../moderation/providers/moderation_providers.dart';

final auditLogProvider = FutureProvider.autoDispose<List<AuditLogEntry>>((ref) {
  final repository = ref.watch(moderationRepositoryProvider);
  return repository.fetchAuditLogs();
});

