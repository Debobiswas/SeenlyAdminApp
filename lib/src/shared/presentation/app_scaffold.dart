import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/session_provider.dart';
import '../../features/moderation/providers/moderation_providers.dart';
import '../../features/disputes/providers/disputes_providers.dart';
import '../../features/feedback/providers/feedback_providers.dart';
import '../../app/theme/theme_provider.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    required this.title,
    required this.currentIndex,
    required this.body,
    this.subtitle,
    super.key,
  });

  final String title;
  final int currentIndex;
  final Widget body;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colorScheme.brightness == Brightness.light
                    ? [
                        Colors.white,
                        colorScheme.surface,
                        colorScheme.primaryContainer.withValues(alpha: 0.22),
                      ]
                    : [
                        colorScheme.surface,
                        colorScheme.primaryContainer.withValues(alpha: 0.08),
                      ],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (isWide)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                      child: _SidebarNav(
                        currentIndex: currentIndex,
                        onSelect: (index) => _navigate(context, index),
                        onSignOut: () => _signOut(context, ref),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 20 : 16,
                        16,
                        isWide ? 20 : 16,
                        isWide ? 20 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopBar(
                            title: title,
                            subtitle: subtitle,
                            currentIndex: currentIndex,
                            isWide: isWide,
                            onSelect: (index) => _navigate(context, index),
                            onSignOut: () => _signOut(context, ref),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: DecoratedBox(
                              decoration: isWide
                                  ? BoxDecoration(
                                      color: colorScheme.brightness == Brightness.light
                                          ? Colors.white.withValues(alpha: 0.92)
                                          : colorScheme.surface.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(color: colorScheme.outlineVariant),
                                    )
                                  : const BoxDecoration(),
                              child: Padding(
                                padding: EdgeInsets.all(isWide ? 16 : 0),
                                child: body,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: NavigationBar(
                      selectedIndex: currentIndex,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.fact_check_outlined),
                          selectedIcon: Icon(Icons.fact_check),
                          label: 'Moderation',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.gavel_outlined),
                          selectedIcon: Icon(Icons.gavel),
                          label: 'Disputes',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.storefront_outlined),
                          selectedIcon: Icon(Icons.storefront),
                          label: 'Directory',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.forum_outlined),
                          selectedIcon: Icon(Icons.forum),
                          label: 'Feedback',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: 'Configs',
                        ),
                      ],
                      onDestinationSelected: (index) => _navigate(context, index),
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        return;
      case 1:
        context.go('/disputes');
        return;
      case 2:
        context.go('/directory');
        return;
      case 3:
        context.go('/feedback');
        return;
      case 4:
        context.go('/configs');
        return;
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionControllerProvider.notifier).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.currentIndex,
    required this.isWide,
    required this.onSelect,
    required this.onSignOut,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int currentIndex;
  final bool isWide;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isWide) {
      return Text(title, style: theme.textTheme.headlineMedium);
    }

    // Mobile layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onSignOut,
          icon: Icon(Icons.logout_rounded, color: colorScheme.error),
          tooltip: 'Sign out',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.2),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}

class _SidebarNav extends ConsumerWidget {
  const _SidebarNav({
    required this.currentIndex,
    required this.onSelect,
    required this.onSignOut,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pendingCount = ref.watch(pendingProfilesProvider(null)).value?.length ?? 0;
    final modsBadge = pendingCount;

    final disputesBadge = ref.watch(userReportsProvider).value?.length ?? 0;
    
    final feedbackList = ref.watch(feedbackListProvider).value ?? [];
    final feedbackBadge = feedbackList.where((e) => e.status == 'open').length;

    return SizedBox(
      width: 240,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.brightness == Brightness.light
              ? Colors.white.withValues(alpha: 0.98)
              : colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.verified_user_rounded, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seenly Admin', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          'Workspace',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _SidebarNavItem(
                      icon: Icons.fact_check_outlined,
                      selectedIcon: Icons.fact_check,
                      label: 'Moderation',
                      isSelected: currentIndex == 0,
                      badgeCount: modsBadge,
                      onTap: () => onSelect(0),
                    ),
                    _SidebarNavItem(
                      icon: Icons.gavel_outlined,
                      selectedIcon: Icons.gavel,
                      label: 'Disputes',
                      isSelected: currentIndex == 1,
                      badgeCount: disputesBadge,
                      onTap: () => onSelect(1),
                    ),
                    _SidebarNavItem(
                      icon: Icons.storefront_outlined,
                      selectedIcon: Icons.storefront,
                      label: 'Directory',
                      isSelected: currentIndex == 2,
                      onTap: () => onSelect(2),
                    ),
                    _SidebarNavItem(
                      icon: Icons.forum_outlined,
                      selectedIcon: Icons.forum,
                      label: 'Feedback',
                      isSelected: currentIndex == 3,
                      badgeCount: feedbackBadge,
                      onTap: () => onSelect(3),
                    ),
                    _SidebarNavItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Configs',
                      isSelected: currentIndex == 4,
                      onTap: () => onSelect(4),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final currentMode = ref.watch(themeModeProvider);
                      final isDark = currentMode == ThemeMode.dark;
                      
                      return IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => RotationTransition(
                            turns: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            key: ValueKey(isDark),
                            color: colorScheme.primary,
                          ),
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).state =
                              isDark ? ThemeMode.light : ThemeMode.dark;
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = widget.isSelected
        ? colorScheme.primaryContainer.withValues(alpha: 0.85)
        : _isHovered
            ? colorScheme.primaryContainer.withValues(alpha: 0.22)
            : Colors.transparent;

    final fg = widget.isSelected
        ? colorScheme.onPrimaryContainer
        : _isHovered
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: widget.isSelected
                ? Border(
                    left: BorderSide(
                      color: colorScheme.primary,
                      width: 4,
                    ),
                  )
                : const Border(
                    left: BorderSide(
                      color: Colors.transparent,
                      width: 4,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected ? widget.selectedIcon : widget.icon,
                color: fg,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: fg,
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                  child: Text(widget.label),
                ),
              ),
              if (widget.badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badgeCount.toString(),
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
