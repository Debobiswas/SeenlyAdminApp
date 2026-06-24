import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/models/waitlist_entry.dart';
import '../../../shared/presentation/hoverable.dart';
import '../../../shared/presentation/animated_empty_state.dart';
import '../providers/moderation_providers.dart';

class WaitlistQueuePanel extends ConsumerStatefulWidget {
  const WaitlistQueuePanel({super.key});

  @override
  ConsumerState<WaitlistQueuePanel> createState() => _WaitlistQueuePanelState();
}

class _WaitlistQueuePanelState extends ConsumerState<WaitlistQueuePanel> {
  bool _isActionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final waitlistEntries = ref.watch(waitlistEntriesProvider);
    final theme = Theme.of(context);

    return waitlistEntries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load waitlist entries', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(err.toString(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(waitlistEntriesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'Waitlist queue is empty',
            message: 'All signup requests have been reviewed.',
            action: FilledButton.tonalIcon(
              onPressed: () => ref.invalidate(waitlistEntriesProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh queue'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entries.length} Pending Signups',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(waitlistEntriesProvider),
                    tooltip: 'Refresh queue',
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _WaitlistCard(
                    entry: entry,
                    onInvite: () => _handleAction(entry, true),
                    onArchive: () => _handleAction(entry, false),
                    isDisabled: _isActionInProgress,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAction(WaitlistEntry entry, bool isInvite) async {
    setState(() => _isActionInProgress = true);
    final repo = ref.read(waitlistRepositoryProvider);
    final actionName = isInvite ? 'invited' : 'archived';

    try {
      if (isInvite) {
        await repo.inviteEntry(entry.id);
      } else {
        await repo.archiveEntry(entry.id);
      }
      ref.invalidate(waitlistEntriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully $actionName ${entry.fullName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process entry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }
}

class _WaitlistCard extends StatelessWidget {
  const _WaitlistCard({
    required this.entry,
    required this.onInvite,
    required this.onArchive,
    this.isDisabled = false,
  });

  final WaitlistEntry entry;
  final VoidCallback onInvite;
  final VoidCallback onArchive;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInfluencer = entry.userType.toLowerCase() == 'influencer';

    return Hoverable(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 1,
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
                    backgroundColor: isInfluencer
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    child: Icon(
                      isInfluencer ? Icons.camera_alt : Icons.storefront,
                      color: isInfluencer
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(entry.email, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        if (entry.city != null)
                          Text('City: ${entry.city}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  _UserTypeBadge(isInfluencer: isInfluencer),
                ],
              ),
              const SizedBox(height: 12),
              if (!isInfluencer && entry.businessName != null) ...[
                Text(
                  'Business Name: ${entry.businessName}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
              ],
              // Links/Details
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (entry.instagramLink != null || entry.socialHandle != null)
                    OutlinedButton.icon(
                      onPressed: () => _launchURL(
                        entry.instagramLink ?? 'https://instagram.com/${entry.socialHandle}',
                        context,
                      ),
                      icon: const Icon(Icons.link, size: 16),
                      label: Text(entry.socialHandle ?? 'Instagram'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (entry.googleMapsLink != null)
                    OutlinedButton.icon(
                      onPressed: () => _launchURL(entry.googleMapsLink!, context),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('Google Maps'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isDisabled ? null : onArchive,
                      icon: const Icon(Icons.archive_outlined, color: Colors.grey),
                      label: const Text('Archive', style: TextStyle(color: Colors.grey)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: isDisabled ? null : onInvite,
                      icon: const Icon(Icons.check),
                      label: const Text('Invite / Approve'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString, BuildContext context) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }
}

class _UserTypeBadge extends StatelessWidget {
  const _UserTypeBadge({required this.isInfluencer});

  final bool isInfluencer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isInfluencer ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInfluencer ? Colors.blue.shade300 : Colors.green.shade300,
        ),
      ),
      child: Text(
        isInfluencer ? 'Influencer' : 'Business',
        style: TextStyle(
          color: isInfluencer ? Colors.blue.shade800 : Colors.green.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
