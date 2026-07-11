import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/server_config/presentation/server_config_screen.dart';
import '../features/explorer/presentation/explorer_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/media/presentation/media_preview_screen.dart';
import '../features/explorer/models/file_item.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/config',
      builder: (context, state) => const ServerConfigScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/explorer',
      builder: (context, state) => const ExplorerScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/media-preview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final items = extra['items'] as List<FileItem>;
        final initialIndex = extra['initialIndex'] as int;
        return MediaPreviewScreen(items: items, initialIndex: initialIndex);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
