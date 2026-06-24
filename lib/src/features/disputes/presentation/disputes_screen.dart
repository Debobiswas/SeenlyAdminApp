import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/hoverable.dart';
import '../../../shared/presentation/animated_empty_state.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/models/moderation_profile.dart';
import '../providers/disputes_providers.dart';

class DisputesScreen extends ConsumerWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: 'Disputes & Compliance',
        subtitle: 'Inspect proof submissions, review reports, and manage creator strikes.',
        currentIndex: 1,
        body: Column(
          children: [
            TabBar(
              isScrollable: isMobile,
              tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_rounded),
                      SizedBox(width: 8),
                      Text('Proof Moderation'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.report_problem_rounded),
                      SizedBox(width: 8),
                      Text('User Reports'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_rounded),
                      SizedBox(width: 8),
                      Text('Strike Tracker'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _ReservationModerationTab(),
                  _UserReportsTab(),
                  _StrikeTrackerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationModerationTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ReservationModerationTab> createState() => _ReservationModerationTabState();
}

class _ReservationModerationTabState extends ConsumerState<_ReservationModerationTab> {
  bool _isActionInProgress = false;
  bool _showAllReservations = false;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(reservationsProvider);
    final theme = Theme.of(context);

    return reservationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading reservations: $err')),
      data: (reservations) {
        // Filter to reservations with proof submitted that aren't resolved yet
        final pending = reservations
            .where((r) => r.proofUrl != null && r.proofUrl!.isNotEmpty && r.status != 'completed' && r.status != 'rejected')
            .toList();

        final displayList = _showAllReservations ? reservations : pending;

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
                      _showAllReservations ? 'All Reservations' : 'Pending Proof Reviews (${pending.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text('Show all history'),
                        Switch(
                          value: _showAllReservations,
                          onChanged: (val) => setState(() => _showAllReservations = val),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ref.invalidate(reservationsProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: displayList.isEmpty
                  ? AnimatedEmptyState(
                      icon: Icons.verified_rounded,
                      title: 'All caught up!',
                      message: 'No pending influencer proofs require review.',
                      action: FilledButton.tonalIcon(
                        onPressed: () => ref.invalidate(reservationsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh list'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final res = displayList[index];
                        return _ReservationModerationCard(
                          reservation: res,
                          isDisabled: _isActionInProgress,
                          onApprove: () => _handleApprove(res),
                          onReject: () => _handleReject(res),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleApprove(Reservation reservation) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(disputesRepositoryProvider).approveProof(reservation.id);
      ref.invalidate(reservationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation proof approved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve proof: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<void> _handleReject(Reservation reservation) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Proof & Issue Strike'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Specify why the proof is rejected. This will automatically increment a strike on the creator\'s account.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g., Post does not match guidelines, or post was deleted',
              ),
              minLines: 2,
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Reject & Strike'),
          ),
        ],
      ),
    );
    reasonController.dispose();

    if (reason == null || reason.isEmpty) return;

    setState(() => _isActionInProgress = true);
    try {
      await ref.read(disputesRepositoryProvider).rejectProofAndStrike(
            reservationId: reservation.id,
            userId: reservation.userId,
            reason: reason,
          );
      ref.invalidate(reservationsProvider);
      ref.invalidate(flaggedProfilesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof rejected and strike issued.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject proof: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }
}

class _ReservationModerationCard extends StatelessWidget {
  const _ReservationModerationCard({
    required this.reservation,
    required this.onApprove,
    required this.onReject,
    this.isDisabled = false,
  });

  final Reservation reservation;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = reservation.status != 'completed' && reservation.status != 'rejected';

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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.campaignTitle ?? 'Campaign Offer',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Creator: ${reservation.creatorName ?? "Unknown"}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          'Venue: ${reservation.venueName ?? "Unknown"}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: reservation.status),
                ],
              ),
              const Divider(height: 24),
              if (reservation.proofUrl != null && reservation.proofUrl!.isNotEmpty) ...[
                Text('Proof URL:', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _launchURL(reservation.proofUrl!, context),
                  child: Text(
                    reservation.proofUrl!,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (isPending)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isDisabled ? null : onReject,
                        icon: const Icon(Icons.close_rounded, color: Colors.red),
                        label: const Text('Reject & Strike', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: isDisabled ? null : onApprove,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Approve Proof'),
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

  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open proof URL.')),
        );
      }
    }
  }
}

class _UserReportsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(userReportsProvider);
    final theme = Theme.of(context);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading reports: $err')),
      data: (reports) {
        if (reports.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.verified_user_rounded,
            title: 'No Active Reports',
            message: 'All community reports have been cleared.',
            action: FilledButton.tonalIcon(
              onPressed: () => ref.invalidate(userReportsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh reports'),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active User Reports (${reports.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(userReportsProvider),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Hoverable(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        leading: const Icon(Icons.report_rounded, color: Colors.amber),
                        title: Text(
                          'Report by ${report.reporterName ?? "User"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Reported: ${report.reportedName ?? "User"}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reason:', style: theme.textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Text(report.reason, style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 12),
                                Text('Created: ${report.formattedCreatedAt}', style: theme.textTheme.bodySmall),
                                if (report.reservationId != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Reservation Reference ID: ${report.reservationId}', style: theme.textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StrikeTrackerTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StrikeTrackerTab> createState() => _StrikeTrackerTabState();
}

class _StrikeTrackerTabState extends ConsumerState<_StrikeTrackerTab> {
  bool _isActionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(flaggedProfilesProvider);
    final theme = Theme.of(context);

    return profilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading strike tracker: $err')),
      data: (profiles) {
        if (profiles.isEmpty) {
          return AnimatedEmptyState(
            icon: Icons.shield_rounded,
            title: 'No Flagged Creators',
            message: 'No creators currently have active strikes.',
            action: FilledButton.tonalIcon(
              onPressed: () => ref.invalidate(flaggedProfilesProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh list'),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Creator Strike Tracker (${profiles.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(flaggedProfilesProvider),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return Hoverable(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Icon(Icons.warning_rounded, color: Colors.red.shade800),
                        ),
                        title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${profile.email}\nStatus: ${profile.status.name}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${profile.strikes ?? 0} Strikes', 
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              enabled: !_isActionInProgress,
                              onSelected: (val) => _handleMenuAction(val, profile),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'suspend',
                                  child: Text('Suspend / Ban Creator'),
                                ),
                                const PopupMenuItem(
                                  value: 'unsuspend',
                                  child: Text('Clear Strikes & Reactivate'),
                                ),
                              ],
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
    );
  }

  Future<void> _handleMenuAction(String action, ModerationProfile profile) async {
    setState(() => _isActionInProgress = true);
    final repo = ref.read(disputesRepositoryProvider);
    try {
      if (action == 'suspend') {
        await repo.suspendUser(profile.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully suspended ${profile.fullName}')),
          );
        }
      } else if (action == 'unsuspend') {
        await repo.unsuspendUser(profile.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reactivated ${profile.fullName} and cleared strikes.')),
          );
        }
      }
      ref.invalidate(flaggedProfilesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    switch (status.toLowerCase()) {
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case 'active':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
