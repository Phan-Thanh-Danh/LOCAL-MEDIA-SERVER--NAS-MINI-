import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/files/presentation/screens/home_screen.dart';
import '../../features/media/presentation/screens/media_preview_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isAuthenticated = authState.isAuthenticated;

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/media',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MediaPreviewScreen(
            title: extra['title'] as String? ?? 'Preview',
            type: extra['type'] as String? ?? 'image',
            url: extra['url'] as String? ?? '',
            relativePath: extra['relativePath'] as String? ?? '',
          );
        },
      ),
    ],
  );
});
