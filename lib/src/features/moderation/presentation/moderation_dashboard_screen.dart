import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/models/moderation_profile.dart';
import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/hoverable.dart';
import '../../../shared/presentation/activity_sparkline.dart';
import '../../../shared/presentation/animated_empty_state.dart';
import '../providers/moderation_providers.dart';
class ModerationDashboardScreen extends ConsumerStatefulWidget {
  const ModerationDashboardScreen({super.key});

  @override
  ConsumerState<ModerationDashboardScreen> createState() => _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends ConsumerState<ModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      title: 'Moderation & Onboarding',
      subtitle: 'Review pending profiles for influencers and businesses.',
      currentIndex: 0,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: isMobile,
            tabAlignment: TabAlignment.center,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                icon: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_rounded),
                    SizedBox(width: 8),
                    Text('Businesses'),
                  ],
                ),
              ),
              Tab(
                icon: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded),
                    SizedBox(width: 8),
                    Text('Influencers'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PendingProfilesTab(accountType: AccountType.business),
                _PendingProfilesTab(accountType: AccountType.influencer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingProfilesTab extends ConsumerWidget {
  const _PendingProfilesTab({required this.accountType});

  final AccountType accountType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingProfiles = ref.watch(pendingProfilesProvider(accountType));
    final selectedProfile = ref.watch(selectedProfileProvider(accountType));

    ref.listen<AsyncValue<List<ModerationProfile>>>(pendingProfilesProvider(accountType), (_, next) {
      next.whenData((profiles) {
        final current = ref.read(selectedProfileProvider(accountType));
        if (profiles.isEmpty) {
          ref.read(selectedProfileProvider(accountType).notifier).state = null;
          return;
        }

        if (current == null || !profiles.any((profile) => profile.id == current.id)) {
          ref.read(selectedProfileProvider(accountType).notifier).state = profiles.first;
        }
      });
    });

    return pendingProfiles.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _AsyncMessage(
        icon: Icons.error_outline_rounded,
        title: 'Could not load pending profiles',
        message: error.toString(),
      ),
      data: (profiles) => _DashboardContent(
        profiles: profiles,
        selectedProfile: selectedProfile,
        accountType: accountType,
      ),
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  const _DashboardContent({
    required this.profiles,
    required this.selectedProfile,
    required this.accountType,
  });

  final List<ModerationProfile> profiles;
  final ModerationProfile? selectedProfile;
  final AccountType accountType;

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(moderationSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Queue Metrics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _MetricsRow(profiles: widget.profiles),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _FilterBottomSheet(accountType: widget.accountType);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(moderationSearchProvider);
    final theme = Theme.of(context);

    // Listen to changes in search query from outside to synchronize the controller
    ref.listen<String>(moderationSearchProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1120;

        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (searchQuery.isNotEmpty)
                    _FilterSummaryChip(
                      label: 'Search: "$searchQuery"',
                      icon: Icons.search_rounded,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showStatsDialog(context),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('View Stats'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(Icons.filter_list_rounded),
                      label: const Text('Filters'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final showAll = ref.watch(showAllProfilesProvider);
                        return OutlinedButton.icon(
                          onPressed: () {
                            ref.read(showAllProfilesProvider.notifier).state = !showAll;
                          },
                          icon: Icon(
                            showAll ? Icons.people_rounded : Icons.pending_actions_rounded,
                          ),
                          label: Text(showAll ? 'Show: All' : 'Show: Pending'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: showAll
                                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search pending profiles by name, email, or handle...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        ref.read(moderationSearchProvider.notifier).state = value.trim();
                      },
                      onSubmitted: (value) {
                        ref.read(moderationSearchProvider.notifier).state = value.trim();
                      },
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(moderationSearchProvider.notifier).state = '';
                        },
                        tooltip: 'Clear search',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.profiles.isEmpty
                  ? AnimatedEmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No pending profiles',
                      message: 'Try a different filter or check back after new sign-ups arrive.',
                      action: FilledButton.tonalIcon(
                        onPressed: () => ref.invalidate(pendingProfilesProvider(widget.accountType)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh queue'),
                      ),
                    )
                  : isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _ProfileListPanel(
                                profiles: widget.profiles,
                                selectedProfile: widget.selectedProfile,
                                onSelect: (profile) {
                                  ref.read(selectedProfileProvider(widget.accountType).notifier).state = profile;
                                },
                                accountType: widget.accountType,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: _ProfileDetailsPanel(
                                profile: widget.selectedProfile ?? widget.profiles.first,
                                accountType: widget.accountType,
                              ),
                            ),
                          ],
                        )
                      : _ProfileListPanel(
                          profiles: widget.profiles,
                          selectedProfile: widget.selectedProfile,
                          onSelect: (profile) {
                            ref.read(selectedProfileProvider(widget.accountType).notifier).state = profile;
                            _showProfileBottomSheet(context, profile);
                          },
                          accountType: widget.accountType,
                        ),
            ),
          ],
        );
      },
    );
  }

  void _showProfileBottomSheet(BuildContext context, ModerationProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: _ProfileDetailsPanel(
            profile: profile,
            accountType: widget.accountType,
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.profiles});

  final List<ModerationProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final influencers = profiles.where((profile) => profile.isInfluencer).length;
    final businesses = profiles.where((profile) => profile.isBusiness).length;
    final newestDate = profiles.isEmpty
        ? null
        : profiles
            .map((profile) => profile.createdAt)
            .reduce((latest, value) => value.isAfter(latest) ? value : latest);

    final cards = [
      _MetricCard(
        label: 'Pending reviews',
        value: profiles.length.toString(),
        icon: Icons.pending_actions_rounded,
        dataPoints: [12.0, 16.0, 8.0, 14.0, 10.0, profiles.length.toDouble()],
      ),
      _MetricCard(
        label: 'Influencers',
        value: influencers.toString(),
        icon: Icons.camera_alt_outlined,
        dataPoints: [6.0, 10.0, 4.0, 8.0, 7.0, influencers.toDouble()],
      ),
      _MetricCard(
        label: 'Businesses',
        value: businesses.toString(),
        icon: Icons.storefront_outlined,
        dataPoints: [3.0, 4.0, 2.0, 5.0, 3.0, businesses.toDouble()],
      ),
      _MetricCard(
        label: 'Newest signup',
        value: newestDate == null ? '-' : DateFormat.MMMd().format(newestDate),
        icon: Icons.schedule_rounded,
        dataPoints: const [2.0, 4.0, 3.0, 5.0, 4.0, 6.0],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          );
        }

        if (constraints.maxWidth >= 560) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(width: double.infinity, child: cards[0]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: cards[1]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: cards[2]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: cards[3]),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.dataPoints,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<double>? dataPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Hoverable(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (dataPoints != null && dataPoints!.length >= 2) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 64,
                  height: 36,
                  child: ActivitySparkline(
                    dataPoints: dataPoints!,
                    lineColor: colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  const _FilterBottomSheet({required this.accountType});

  final AccountType accountType;

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(moderationSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingProfiles = ref.watch(pendingProfilesProvider(widget.accountType));

    // Listen to changes in search query from outside to synchronize the controller
    ref.listen<String>(moderationSearchProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Search Profiles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onSubmitted: (value) {
                ref.read(moderationSearchProvider.notifier).state = value.trim();
              },
              decoration: InputDecoration(
                hintText: 'Name, email, or handle',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(moderationSearchProvider.notifier).state = '';
                      },
                      tooltip: 'Clear search',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: pendingProfiles.when(
                    data: (profiles) => Text(
                      '${profiles.length} result${profiles.length == 1 ? '' : 's'} found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    loading: () => const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Error loading count',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    ref.read(moderationSearchProvider.notifier).state = _searchController.text.trim();
                  },
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => ref.invalidate(pendingProfilesProvider(widget.accountType)),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh queue',
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(moderationSearchProvider.notifier).state = _searchController.text.trim();
                Navigator.of(context).pop();
              },
              child: const Text('Apply & Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileListPanel extends StatelessWidget {
  const _ProfileListPanel({
    required this.profiles,
    required this.selectedProfile,
    required this.onSelect,
    required this.accountType,
  });

  final List<ModerationProfile> profiles;
  final ModerationProfile? selectedProfile;
  final ValueChanged<ModerationProfile> onSelect;
  final AccountType accountType;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return _ProfileCard(
            profile: profile,
            isSelected: selectedProfile?.id == profile.id,
            onTap: () => onSelect(profile),
            accountType: accountType,
          );
        },
      ),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  const _ProfileCard({
    required this.profile,
    required this.isSelected,
    required this.onTap,
    required this.accountType,
  });

  final ModerationProfile profile;
  final bool isSelected;
  final VoidCallback onTap;
  final AccountType accountType;

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  bool _isSubmitting = false;

  Future<void> _approve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve profile'),
          content: Text('Are you sure you want to approve ${widget.profile.fullName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(moderationRepositoryProvider).approveProfile(widget.profile.id);
      ref.invalidate(pendingProfilesProvider(widget.accountType));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile approved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a reason so the rejection is clear in the audit history.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason',
                  hintText: 'Explain why this profile is being rejected',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
              child: const Text('Confirm rejection'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(moderationRepositoryProvider).rejectProfile(
            userId: widget.profile.id,
            reason: reason,
          );
      ref.invalidate(pendingProfilesProvider(widget.accountType));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile rejected.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch social link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Hoverable(
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label: 'Open moderation details for ${widget.profile.fullName}',
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: colorScheme.surface.withValues(alpha: 0.68),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.profile.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _accountTypeIcon(widget.profile),
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((widget.profile.instagramHandle ?? '').isNotEmpty)
                            IconButton(
                              icon: const InstagramLogo(size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _openExternal('https://instagram.com/${widget.profile.instagramHandle}'),
                              tooltip: 'Instagram: @${widget.profile.instagramHandle}',
                            ),
                          if ((widget.profile.instagramHandle ?? '').isNotEmpty && (widget.profile.tiktokHandle ?? '').isNotEmpty)
                            const SizedBox(width: 12),
                          if ((widget.profile.tiktokHandle ?? '').isNotEmpty)
                            IconButton(
                              icon: const TikTokLogo(size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _openExternal('https://www.tiktok.com/@${widget.profile.tiktokHandle}'),
                              tooltip: 'TikTok: @${widget.profile.tiktokHandle}',
                            ),
                        ],
                      ),
                      _isSubmitting
                          ? const SizedBox(
                              width: 64,
                              height: 26,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : widget.profile.status == ProfileStatus.pending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                                      iconSize: 26,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _approve,
                                      tooltip: 'Approve Profile',
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                                      iconSize: 26,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _reject,
                                      tooltip: 'Reject Profile',
                                    ),
                                  ],
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: switch (widget.profile.status) {
                                      ProfileStatus.active => Colors.green.withValues(alpha: 0.1),
                                      ProfileStatus.rejected => Colors.red.withValues(alpha: 0.1),
                                      _ => Colors.grey.withValues(alpha: 0.1),
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: switch (widget.profile.status) {
                                        ProfileStatus.active => Colors.green.shade300,
                                        ProfileStatus.rejected => Colors.red.shade300,
                                        _ => Colors.grey.shade300,
                                      },
                                    ),
                                  ),
                                  child: Text(
                                    _formatStatus(widget.profile.status),
                                    style: TextStyle(
                                      color: switch (widget.profile.status) {
                                        ProfileStatus.active => Colors.green.shade800,
                                        ProfileStatus.rejected => Colors.red.shade800,
                                        _ => Colors.grey.shade800,
                                      },
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailsPanel extends ConsumerStatefulWidget {
  const _ProfileDetailsPanel({
    required this.profile,
    required this.accountType,
  });

  final ModerationProfile profile;
  final AccountType accountType;

  @override
  ConsumerState<_ProfileDetailsPanel> createState() => _ProfileDetailsPanelState();
}

class _ProfileDetailsPanelState extends ConsumerState<_ProfileDetailsPanel> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final detailsAsync = ref.watch(profileDetailsProvider(widget.profile.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: detailsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Could not load profile details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(err.toString(), style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(profileDetailsProvider(widget.profile.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (profile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ProfileAvatar(profile: profile, radius: 34),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text(
                            profile.email,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusChip(
                                label: _formatAccountType(profile.accountType),
                                icon: _accountTypeIcon(profile),
                              ),
                              _StatusChip(
                                label: _formatStatus(profile.status),
                                icon: switch (profile.status) {
                                  ProfileStatus.active => Icons.check_circle_rounded,
                                  ProfileStatus.rejected => Icons.cancel_rounded,
                                  ProfileStatus.pending => Icons.hourglass_top_rounded,
                                  ProfileStatus.unknown => Icons.help_outline_rounded,
                                },
                                iconColor: switch (profile.status) {
                                  ProfileStatus.active => Colors.green,
                                  ProfileStatus.rejected => Colors.red,
                                  ProfileStatus.pending => Colors.orange,
                                  ProfileStatus.unknown => Colors.grey,
                                },
                                backgroundColor: switch (profile.status) {
                                  ProfileStatus.active => Colors.green.withValues(alpha: 0.1),
                                  ProfileStatus.rejected => Colors.red.withValues(alpha: 0.1),
                                  ProfileStatus.pending => Colors.orange.withValues(alpha: 0.1),
                                  ProfileStatus.unknown => Colors.grey.withValues(alpha: 0.1),
                                },
                                foregroundColor: switch (profile.status) {
                                  ProfileStatus.active => Colors.green.shade800,
                                  ProfileStatus.rejected => Colors.red.shade800,
                                  ProfileStatus.pending => Colors.orange.shade900,
                                  ProfileStatus.unknown => Colors.grey.shade800,
                                },
                              ),
                              _StatusChip(
                                label: 'Created ${profile.formattedCreatedAt}',
                                icon: Icons.schedule_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _InfoSection(
                        title: 'Profile overview',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoTile(
                              label: 'Followers',
                              value: profile.followerCount == null
                                  ? '-'
                                  : NumberFormat.decimalPattern().format(profile.followerCount),
                              icon: Icons.groups_2_outlined,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                if ((profile.tiktokHandle ?? '').isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: () => _openExternal('https://www.tiktok.com/@${profile.tiktokHandle}'),
                                    icon: const TikTokLogo(size: 18),
                                    label: Text('TikTok: @${profile.tiktokHandle}'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                if ((profile.instagramHandle ?? '').isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: () => _openExternal('https://instagram.com/${profile.instagramHandle}'),
                                    icon: const InstagramLogo(size: 18),
                                    label: Text('Instagram: @${profile.instagramHandle}'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                if ((profile.website ?? '').isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: () => _openExternal(profile.website!),
                                    icon: const Icon(Icons.language_rounded, size: 18),
                                    label: const Text('Website'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if ((profile.bio ?? '').isNotEmpty) ...[
                              Text(
                                'Bio',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText(
                                  profile.bio!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InfoSection(
                        title: 'Administrative Controls',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                const SizedBox(width: 12),
                                Text(
                                  'Strikes: ',
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${profile.strikes ?? 0}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: (profile.strikes ?? 0) > 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                                const Spacer(),
                                IconButton.outlined(
                                  onPressed: (profile.strikes ?? 0) <= 0 || _isSubmitting
                                      ? null
                                      : () => _updateStrikes(profile.id, (profile.strikes ?? 0) - 1),
                                  icon: const Icon(Icons.remove_rounded),
                                  tooltip: 'Remove Strike',
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _updateStrikes(profile.id, (profile.strikes ?? 0) + 1),
                                  icon: const Icon(Icons.add_rounded),
                                  tooltip: 'Add Strike',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSubmitting ? null : () => _sendPasswordReset(profile.email),
                                icon: const Icon(Icons.lock_reset_rounded),
                                label: const Text('Send Password Reset Email'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (profile.status == ProfileStatus.active)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isSubmitting ? null : () => _updateStatus(profile.id, ProfileStatus.rejected),
                                  icon: const Icon(Icons.block_rounded),
                                  label: const Text('Suspend User Account'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              )
                            else if (profile.status == ProfileStatus.rejected)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isSubmitting ? null : () => _updateStatus(profile.id, ProfileStatus.active),
                                  icon: const Icon(Icons.check_circle_outline_rounded),
                                  label: const Text('Reactivate User Account'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade700,
                                    side: BorderSide(color: Colors.green.shade400),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      onPressed: (_isSubmitting || profile.status == ProfileStatus.rejected) ? null : () => _reject(profile),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        minimumSize: const Size(64, 64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onError),
                              ),
                            )
                          : const Icon(Icons.close_rounded, size: 28),
                      tooltip: 'Reject profile',
                    ),
                    const SizedBox(width: 24),
                    IconButton.filled(
                      onPressed: (_isSubmitting || profile.status == ProfileStatus.active) ? null : () => _approve(profile),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(64, 64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 28),
                      tooltip: 'Approve profile',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _approve(ModerationProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve profile'),
          content: Text('Are you sure you want to approve ${profile.fullName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(moderationRepositoryProvider).approveProfile(profile.id);
      ref.invalidate(pendingProfilesProvider(widget.accountType));
      ref.invalidate(profileDetailsProvider(profile.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile approved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _reject(ModerationProfile profile) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a reason so the rejection is clear in the audit history.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason',
                  hintText: 'Explain why this profile is being rejected',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
              child: const Text('Confirm rejection'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(moderationRepositoryProvider).rejectProfile(
            userId: profile.id,
            reason: reason,
          );
      ref.invalidate(pendingProfilesProvider(widget.accountType));
      ref.invalidate(profileDetailsProvider(profile.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile rejected.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateStrikes(String userId, int strikes) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(moderationRepositoryProvider).updateStrikes(userId, strikes);
      ref.invalidate(profileDetailsProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Strikes updated to $strikes.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating strikes: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(moderationRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending password reset: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateStatus(String userId, ProfileStatus status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final actionText = status == ProfileStatus.rejected ? 'Suspend' : 'Reactivate';
        return AlertDialog(
          title: Text('$actionText account'),
          content: Text('Are you sure you want to ${actionText.toLowerCase()} this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(actionText),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(moderationRepositoryProvider).updateProfileStatus(userId, status);
      ref.invalidate(pendingProfilesProvider(widget.accountType));
      ref.invalidate(profileDetailsProvider(userId));
      if (mounted) {
        final successMsg = status == ProfileStatus.rejected ? 'Account suspended.' : 'Account reactivated.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating account status: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.radius,
  });

  final ModerationProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = profile.fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((part) => part.substring(0, 1).toUpperCase()).join();

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: iconColor),
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: foregroundColor != null ? TextStyle(color: foregroundColor) : null,
      side: backgroundColor != null ? BorderSide.none : null,
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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

    Widget cardContent = Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
          child: Icon(
            icon,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: cardContent,
        ),
      ),
    );
  }
}


class _AsyncMessage extends StatelessWidget {
  const _AsyncMessage({
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

String _formatAccountType(AccountType type) {
  return switch (type) {
    AccountType.influencer => 'Influencer',
    AccountType.business => 'Business',
    AccountType.unknown => 'Unknown',
  };
}

String _formatStatus(ProfileStatus status) {
  return switch (status) {
    ProfileStatus.pending => 'Pending',
    ProfileStatus.active => 'Active',
    ProfileStatus.rejected => 'Rejected',
    ProfileStatus.unknown => 'Unknown',
  };
}

IconData _accountTypeIcon(ModerationProfile profile) {
  if (profile.isBusiness) {
    return Icons.storefront_outlined;
  }
  if (profile.isInfluencer) {
    return Icons.camera_alt_outlined;
  }
  return Icons.person_outline_rounded;
}

class _FilterSummaryChip extends StatelessWidget {
  const _FilterSummaryChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class InstagramLogo extends StatelessWidget {
  const InstagramLogo({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget logoBody = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: size * 0.09),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
        ),
        Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: size * 0.09),
          ),
        ),
        Positioned(
          top: size * 0.18,
          right: size * 0.18,
          child: Container(
            width: size * 0.1,
            height: size * 0.1,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );

    if (color != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: color!, width: size * 0.09),
                borderRadius: BorderRadius.circular(size * 0.28),
              ),
            ),
            Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color!, width: size * 0.09),
              ),
            ),
            Positioned(
              top: size * 0.18,
              right: size * 0.18,
              child: Container(
                width: size * 0.1,
                height: size * 0.1,
                decoration: BoxDecoration(
                  color: color!,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const RadialGradient(
          center: Alignment.bottomLeft,
          radius: 1.2,
          colors: [
            Color(0xFFFEE140),
            Color(0xFFFA709A),
            Color(0xFFE1306C),
            Color(0xFFC13584),
            Color(0xFF833AB4),
            Color(0xFF405DE6),
          ],
        ).createShader(bounds),
        child: logoBody,
      ),
    );
  }
}

class TikTokLogo extends StatelessWidget {
  const TikTokLogo({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? (isDark ? Colors.white : Colors.black);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: -1.2,
            top: -0.6,
            child: Icon(
              Icons.music_note_rounded,
              size: size,
              color: const Color(0xFF00F2FE),
            ),
          ),
          Positioned(
            left: 1.2,
            top: 0.6,
            child: Icon(
              Icons.music_note_rounded,
              size: size,
              color: const Color(0xFFFE0979),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.music_note_rounded,
              size: size,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}

