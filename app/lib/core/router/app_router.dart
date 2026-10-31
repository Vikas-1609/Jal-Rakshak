import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catchment/presentation/map_page.dart';
import '../../features/catchment/presentation/zone_detail_page.dart';
import '../../features/lakes/presentation/lakes_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/simulator/presentation/plan_intro_page.dart';
import '../../features/simulator/presentation/plan_page.dart';
import '../widgets/app_shell.dart';

abstract final class Routes {
  static const lakes = '/lakes';
  static const map = '/map';
  static const plan = '/plan';
  static const planIntro = '/plan/intro';
  static const settings = '/settings';
  static String zone(String zoneId) => '/plan/zone/$zoneId';
}

/// Three tabs (Lakes, Map, Plan), each keeping its own navigation stack.
/// Settings and the Plan guide open full screen above the tabs.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.lakes,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.lakes,
                builder: (context, state) => const LakesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.map,
                builder: (context, state) => const MapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.plan,
                builder: (context, state) => const PlanPage(),
                routes: [
                  // The Map tab shows zone details in its own sheet;
                  // the Plan tab opens them as a page.
                  GoRoute(
                    path: 'zone/:zoneId',
                    builder: (context, state) =>
                        ZoneDetailPage(zoneId: state.pathParameters['zoneId']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.planIntro,
        builder: (context, state) => const PlanIntroPage(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
