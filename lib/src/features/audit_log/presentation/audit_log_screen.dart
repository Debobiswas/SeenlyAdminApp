import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/audit_log_entry.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../providers/audit_log_provider.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditLogProvider);

    return AppScaffold(
      title: 'Audit history',
      subtitle: 'Track approvals and rejections with timestamps, targets, and rejection context.',
      currentIndex: 1,
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AuditMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load audit history',
          message: error.toString(),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _AuditMessage(
              icon: Icons.history_toggle_off_rounded,
              title: 'No moderation actions yet',
              message: 'Approved and rejected profiles will appear here once your team starts reviewing sign-ups.',
            );
          }

          final approvals = entries.where((entry) => entry.action.toLowerCase() == 'approved').length;
          final rejections = entries.where((entry) => entry.action.toLowerCase() == 'rejected').length;

          return Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    label: 'Total actions',
                    value: entries.length.toString(),
                    icon: Icons.rule_folder_outlined,
                  ),
                  _SummaryCard(
                    label: 'Approvals',
                    value: approvals.toString(),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  _SummaryCard(
                    label: 'Rejections',
                    value: rejections.toString(),
                    icon: Icons.block_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _AuditEntryCard(entry: entries[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: colorScheme.primary),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.headlineSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditEntryCard extends StatelessWidget {
  const _AuditEntryCard({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isApproval = entry.action.toLowerCase() == 'approved';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: Icon(
                  isApproval ? Icons.check_circle_outline_rounded : Icons.block_outlined,
                  size: 18,
                ),
                label: Text(isApproval ? 'Approved' : 'Rejected'),
              ),
              Text(
                entry.formattedTimestamp,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            entry.targetName ?? entry.targetEmail ?? entry.targetUserId,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if ((entry.targetEmail ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.targetEmail!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if ((entry.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                entry.reason!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuditMessage extends StatelessWidget {
  const _AuditMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
