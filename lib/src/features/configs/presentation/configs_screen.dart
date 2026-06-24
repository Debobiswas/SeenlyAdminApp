import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/app_scaffold.dart';
import '../providers/configs_providers.dart';
import '../../audit_log/providers/audit_log_provider.dart';


class ConfigsScreen extends ConsumerWidget {
  const ConfigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'System Configs',
        subtitle: 'Toggle active feature flags and audit admin operational history.',
        currentIndex: 4,
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
                      Icon(Icons.toggle_on_rounded),
                      SizedBox(width: 8),
                      Text('Feature Flags'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded),
                      SizedBox(width: 8),
                      Text('Audit Logs'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: TabBarView(
                children: [
                  _FeatureFlagsTab(),
                  _AuditLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureFlagsTab extends ConsumerStatefulWidget {
  const _FeatureFlagsTab();

  @override
  ConsumerState<_FeatureFlagsTab> createState() => _FeatureFlagsTabState();
}

class _FeatureFlagsTabState extends ConsumerState<_FeatureFlagsTab> {
  bool _isActionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final theme = Theme.of(context);

    return flagsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading flags: $err')),
      data: (flags) {
        if (flags.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.toggle_off_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No Feature Flags Defined', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text('Feature flags table is empty.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

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
                      'Feature Flags (${flags.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(featureFlagsProvider),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: flags.length,
                itemBuilder: (context, index) {
                  final flag = flags[index];
                  final isModifiable = flag.valueString != null;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isModifiable
                          ? BorderSide(color: Colors.green.shade400, width: 2.0)
                          : BorderSide.none,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: isModifiable && !_isActionInProgress
                            ? () => _handleEditValue(flag.key, flag.valueString)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      flag.key,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (flag.description != null && flag.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        flag.description!,
                                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                                      ),
                                    ],
                                    if (flag.valueString != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Value: ${flag.valueString!.isEmpty ? "<empty>" : flag.valueString}',
                                                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                                                softWrap: true,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Updated: ${flag.formattedUpdatedAt}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: flag.isEnabled,
                                onChanged: _isActionInProgress
                                    ? null
                                    : (val) => _handleToggleFlag(flag.key, val),
                              ),
                            ],
                          ),
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

  Future<void> _handleToggleFlag(String key, bool val) async {
    setState(() => _isActionInProgress = true);
    try {
      await ref.read(configsRepositoryProvider).toggleFeatureFlag(key, val);
      ref.invalidate(featureFlagsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feature flag "$key" toggled successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flag: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<void> _handleEditValue(String key, String? currentValue) async {
    final controller = TextEditingController(text: currentValue ?? '');
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Value for "$key"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update the configuration value for this feature flag (e.g. minimum version number).',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Config Value',
                border: OutlineInputBorder(),
              ),
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newValue == null) return;

    setState(() => _isActionInProgress = true);
    try {
      await ref.read(configsRepositoryProvider).updateFeatureFlagValue(key, newValue);
      ref.invalidate(featureFlagsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feature flag "$key" value updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update value: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }
}

class _AuditLogsTab extends ConsumerWidget {
  const _AuditLogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading audit logs: $err')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No Audit History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text('Logs will appear here once actions are taken.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

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
                      'Audit Timeline (${entries.length} actions)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(auditLogProvider),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isApproval = entry.action.toLowerCase() == 'approved';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isApproval ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isApproval ? Colors.green.shade300 : Colors.red.shade300),
                                ),
                                child: Text(
                                  entry.action.toUpperCase(),
                                  style: TextStyle(
                                    color: isApproval ? Colors.green.shade800 : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                entry.formattedTimestamp,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entry.targetName ?? entry.targetEmail ?? 'Target User: ${entry.targetUserId}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (entry.targetEmail != null) ...[
                            const SizedBox(height: 2),
                            Text(entry.targetEmail!, style: theme.textTheme.bodySmall),
                          ],
                          if (entry.reason != null && entry.reason!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.reason!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
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
