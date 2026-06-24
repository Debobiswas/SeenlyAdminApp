import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/hoverable.dart';
import '../../../shared/presentation/animated_empty_state.dart';
import '../providers/feedback_providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  bool _showResolved = false;
  bool _isActionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackListProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Support & Feedback',
      subtitle: 'Review user-submitted support inquiries, bug reports, and suggestions.',
      currentIndex: 3,
      body: feedbackAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading feedback: $err')),
        data: (feedbackList) {
          final filteredList = feedbackList
              .where((entry) => _showResolved ? entry.status == 'resolved' : entry.status == 'open')
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        _showResolved ? 'Resolved Tickets' : 'Open Tickets (${filteredList.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text('Show resolved'),
                          Switch(
                            value: _showResolved,
                            onChanged: (val) => setState(() => _showResolved = val),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => ref.invalidate(feedbackListProvider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: filteredList.isEmpty
                    ? AnimatedEmptyState(
                        icon: _showResolved ? Icons.folder_off_rounded : Icons.check_circle_outline_rounded,
                        title: _showResolved ? 'No resolved tickets' : 'No open support issues!',
                        message: _showResolved
                            ? 'Cleared items will appear here.'
                            : 'Everything has been handled.',
                        action: FilledButton.tonalIcon(
                          onPressed: () => ref.invalidate(feedbackListProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh list'),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final entry = filteredList[index];
                          return Hoverable(
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _getCategoryColor(entry.type, theme),
                                          child: Icon(_getCategoryIcon(entry.type), color: Colors.white),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.userName ?? 'Anonymous User',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Type: ${(entry.type ?? "General").toUpperCase()}',
                                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (entry.status == 'open')
                                          FilledButton.tonal(
                                            onPressed: _isActionInProgress
                                                ? null
                                                : () => _handleResolve(entry.id),
                                            child: const Text('Resolve'),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      entry.message,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const Divider(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            entry.formattedCreatedAt,
                                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                          ),
                                          if (entry.contactEmail != null && entry.contactEmail!.isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () => _copyToClipboard(entry.contactEmail!, context),
                                              icon: const Icon(Icons.copy_rounded, size: 16),
                                              label: Text(entry.contactEmail!),
                                              style: OutlinedButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleResolve(String feedbackId) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(feedbackRepositoryProvider).resolveFeedback(feedbackId);
      ref.invalidate(feedbackListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket resolved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve ticket: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied email to clipboard: $text')),
    );
  }

  IconData _getCategoryIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'bug':
        return Icons.bug_report_rounded;
      case 'question':
        return Icons.help_outline_rounded;
      case 'feedback':
        return Icons.rate_review_rounded;
      default:
        return Icons.support_agent_rounded;
    }
  }

  Color _getCategoryColor(String? type, ThemeData theme) {
    switch (type?.toLowerCase()) {
      case 'bug':
        return Colors.red.shade400;
      case 'question':
        return Colors.blue.shade400;
      case 'feedback':
        return Colors.green.shade400;
      default:
        return theme.colorScheme.primary;
    }
  }
}
