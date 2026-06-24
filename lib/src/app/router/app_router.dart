import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit_log/presentation/audit_log_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/moderation/presentation/moderation_dashboard_screen.dart';
import '../../features/disputes/presentation/disputes_screen.dart';
import '../../features/directory/presentation/directory_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/configs/presentation/configs_screen.dart';
import '../../shared/presentation/admin_route_guard.dart';
import '../../shared/presentation/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AppShell(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminRouteGuard(
            child: ModerationDashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/disputes',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminRouteGuard(
            child: DisputesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/directory',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminRouteGuard(
            child: DirectoryScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/feedback',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminRouteGuard(
            child: FeedbackScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/configs',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminRouteGuard(
            child: ConfigsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminRouteGuard(
            child: AuditLogScreen(),
          ),
        ),
      ),
    ],
  );
});
