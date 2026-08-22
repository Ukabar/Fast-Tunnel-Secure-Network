import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_screen.dart';
import '../features/legal/presentation/about_screen.dart';
import '../features/legal/presentation/legal_screen.dart';
import '../features/legal/presentation/methodology_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tunnel/presentation/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(
        path: '/methodology',
        builder: (context, state) => const MethodologyScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (context, state) => SessionHistoryDetailsScreen(
          entryId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) =>
            const LegalScreen(kind: LegalPageKind.privacy),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) =>
            const LegalScreen(kind: LegalPageKind.terms),
      ),
    ],
  );
});
