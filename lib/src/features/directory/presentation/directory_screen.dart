import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/app_scaffold.dart';
import '../../../shared/presentation/hoverable.dart';
import '../../../shared/models/venue.dart';
import '../../../shared/models/campaign.dart';
import '../providers/directory_providers.dart';
import 'venue_radar_map.dart';

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Venue & Campaign Directory',
      subtitle: 'Manage venue profiles and view coordinate maps.',
      currentIndex: 2,
      body: _VenuesDirectoryTab(),
    );
  }
}

class _VenuesDirectoryTab extends ConsumerStatefulWidget {
  const _VenuesDirectoryTab();

  @override
  ConsumerState<_VenuesDirectoryTab> createState() => _VenuesDirectoryTabState();
}

class _VenuesDirectoryTabState extends ConsumerState<_VenuesDirectoryTab> {
  bool _showRadarMap = false;
  bool _isActionInProgress = false;
  String _searchQuery = '';
  String _selectedCity = 'All';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _extractCity(String address) {
    final parts = address.split(',');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return 'Other';
  }

  void _showFilterSheet(BuildContext context, List<Venue> venues) {
    final cities = ['All', ...venues.map((v) => _extractCity(v.address)).toSet().toList()..sort()];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by City',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedCity != 'All')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCity = 'All';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear Filter'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: cities.map((city) {
                          final isSelected = city == _selectedCity;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              leading: Icon(
                                city == 'All' ? Icons.map_outlined : Icons.location_on_outlined,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              title: Text(
                                city,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                    )
                                  : Icon(
                                      Icons.circle_outlined,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    ),
                              onTap: () {
                                setState(() {
                                  _selectedCity = city;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesListProvider);
    final theme = Theme.of(context);

    return venuesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading venues: $err')),
      data: (venues) {
        final filteredVenues = venues.where((venue) {
          final matchesName = venue.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCity = _selectedCity == 'All' || _extractCity(venue.address) == _selectedCity;
          return matchesName && matchesCity;
        }).toList();

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
                      _showRadarMap ? 'Radar Coordinate Plot' : 'Venues List (${filteredVenues.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text('Show Radar Map'),
                        Switch(
                          value: _showRadarMap,
                          onChanged: (val) => setState(() => _showRadarMap = val),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ref.invalidate(venuesListProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search venues by name...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
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
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                tooltip: 'Clear search',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showFilterSheet(context, venues),
                    icon: Icon(
                      _selectedCity != 'All'
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                      color: _selectedCity != 'All' ? theme.colorScheme.primary : null,
                    ),
                    label: Text(
                      _selectedCity != 'All' ? _selectedCity : 'City',
                      style: TextStyle(
                        color: _selectedCity != 'All' ? theme.colorScheme.primary : null,
                        fontWeight: _selectedCity != 'All' ? FontWeight.bold : null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: _selectedCity != 'All'
                          ? BorderSide(color: theme.colorScheme.primary, width: 2)
                          : null,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _showRadarMap
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: VenueRadarMap(venues: filteredVenues),
                    )
                  : ListView.builder(
                      itemCount: filteredVenues.length,
                      itemBuilder: (context, index) {
                        final venue = filteredVenues[index];
                        return Hoverable(
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(venue.categoryEmoji ?? '📍'),
                              ),
                              title: Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${venue.category ?? "Venue"} • ${venue.address}'),
                              trailing: OutlinedButton(
                                onPressed: _isActionInProgress
                                    ? null
                                    : () => _showSubscriptionTierDialog(venue),
                                child: Text(venue.subscriptionTier?.toUpperCase() ?? 'TIER'),
                              ),
                              onTap: () => _showVenueDetails(venue),
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



  Future<void> _showSubscriptionTierDialog(Venue venue) async {
    final selectedTier = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Subscription Tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['free', 'basic', 'pro', 'premium']
              .map((tier) => ListTile(
                    title: Text(tier.toUpperCase()),
                    selected: venue.subscriptionTier == tier,
                    onTap: () => Navigator.pop(context, tier),
                  ))
              .toList(),
        ),
      ),
    );

    if (selectedTier == null || selectedTier == venue.subscriptionTier) return;

    setState(() => _isActionInProgress = true);
    try {
      await ref.read(directoryRepositoryProvider).updateVenueSubscriptionTier(venue.id, selectedTier);
      ref.invalidate(venuesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue subscription tier updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update subscription tier: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  void _showVenueDetails(Venue venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _VenueDetailsSheet(initialVenue: venue),
    );
  }
}



class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueDetailsSheet extends ConsumerStatefulWidget {
  const _VenueDetailsSheet({required this.initialVenue});
  final Venue initialVenue;

  @override
  ConsumerState<_VenueDetailsSheet> createState() => _VenueDetailsSheetState();
}

class _VenueDetailsSheetState extends ConsumerState<_VenueDetailsSheet> {
  bool _isActionInProgress = false;

  Future<void> _handleToggleActive(Venue venue, bool val) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(directoryRepositoryProvider).toggleVenueStatus(venue.id, val);
      ref.invalidate(venuesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venue status updated to ${val ? "active" : "inactive"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update venue status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(venuesListProvider);
    final campaignsAsync = ref.watch(campaignsListProvider);
    final theme = Theme.of(context);

    return venuesAsync.when(
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 250,
        child: Center(child: Text('Error loading venue details: $err')),
      ),
      data: (venues) {
        final venue = venues.firstWhere(
          (v) => v.id == widget.initialVenue.id,
          orElse: () => widget.initialVenue,
        );

        final venueCampaigns = campaignsAsync.maybeWhen(
          data: (campaigns) => campaigns.where((c) => c.venueId == venue.id).toList(),
          orElse: () => <Campaign>[],
        );

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              8.0,
              24.0,
              MediaQuery.of(context).padding.bottom + 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        venue.categoryEmoji ?? '📍',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              venue.subscriptionTier?.toUpperCase() ?? 'FREE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (venue.description.isNotEmpty) ...[
                  Text(
                    venue.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                ],
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: venue.address,
                ),
                _DetailRow(
                  icon: Icons.map_outlined,
                  label: 'Coordinates',
                  value: '${venue.latitude}, ${venue.longitude}',
                ),
                _DetailRow(
                  icon: Icons.star_outline_rounded,
                  label: 'Rating',
                  value: venue.rating?.toString() ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.language_outlined,
                  label: 'Website',
                  value: venue.website ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: venue.category ?? 'N/A',
                ),
                _DetailRow(
                  icon: venue.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                  label: 'Status',
                  value: venue.isActive ? 'Active' : 'Inactive',
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Campaigns (${venueCampaigns.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (venueCampaigns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No campaigns registered for this venue.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: venueCampaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = venueCampaigns[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            campaign.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Slots: ${campaign.remainingInventory} / ${campaign.totalInventory} remaining',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: campaign.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              campaign.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 11,
                                color: campaign.isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) => _CampaignModificationsSheet(
                                initialCampaign: campaign,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: _isActionInProgress
                      ? const Center(child: CircularProgressIndicator())
                      : venue.isActive
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(color: theme.colorScheme.error),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _handleToggleActive(venue, false),
                              icon: const Icon(Icons.block),
                              label: const Text('Set Venue to Inactive'),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _handleToggleActive(venue, true),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Set Venue to Active'),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CampaignModificationsSheet extends ConsumerStatefulWidget {
  const _CampaignModificationsSheet({required this.initialCampaign});
  final Campaign initialCampaign;

  @override
  ConsumerState<_CampaignModificationsSheet> createState() => _CampaignModificationsSheetState();
}

class _CampaignModificationsSheetState extends ConsumerState<_CampaignModificationsSheet> {
  bool _isActionInProgress = false;

  Future<void> _handleToggleCampaign(Campaign campaign, bool val) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(directoryRepositoryProvider).toggleCampaignStatus(campaign.id, val);
      ref.invalidate(campaignsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campaign status updated to ${val ? "active" : "inactive"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update campaign status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<void> _showAdjustSlotsDialog(Campaign campaign) async {
    final controller = TextEditingController(text: campaign.remainingInventory.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Remaining Inventory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current inventory: ${campaign.remainingInventory} slots available.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Remaining slots'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result == campaign.remainingInventory) return;

    setState(() => _isActionInProgress = true);
    try {
      await ref.read(directoryRepositoryProvider).adjustCampaignInventory(campaign.id, result);
      ref.invalidate(campaignsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign inventory updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to adjust inventory: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(campaignsListProvider);
    final theme = Theme.of(context);

    return campaignsAsync.when(
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 250,
        child: Center(child: Text('Error loading campaign details: $err')),
      ),
      data: (campaigns) {
        final campaign = campaigns.firstWhere(
          (c) => c.id == widget.initialCampaign.id,
          orElse: () => widget.initialCampaign,
        );

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              8.0,
              24.0,
              MediaQuery.of(context).padding.bottom + 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        campaign.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: campaign.isActive,
                      onChanged: _isActionInProgress
                          ? null
                          : (val) => _handleToggleCampaign(campaign, val),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (campaign.description.isNotEmpty) ...[
                  Text(
                    campaign.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                _DetailRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  value: '${campaign.remainingInventory} / ${campaign.totalInventory} remaining',
                ),
                _DetailRow(
                  icon: Icons.sell_outlined,
                  label: 'Value',
                  value: campaign.valueText ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.rule_outlined,
                  label: 'Requirement',
                  value: campaign.requirementText ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.event_available_outlined,
                  label: 'Expiry',
                  value: campaign.formattedExpiryTime,
                ),
                _DetailRow(
                  icon: Icons.star_border_outlined,
                  label: 'Tier Required',
                  value: campaign.tier?.toUpperCase() ?? 'N/A',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isActionInProgress
                            ? null
                            : () => _showAdjustSlotsDialog(campaign),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Adjust Inventory'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
