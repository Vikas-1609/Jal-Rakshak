import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../layout/breakpoints.dart';
import '../utils/haptics.dart';

/// The three tabs: expressive bottom navigation on phones, a navigation rail
/// on wider windows (tablets, web).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int i) {
    Haptics.selection();
    // Tapping the current tab again returns to its first page.
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.medium) {
      return Scaffold(
        body: Row(
          children: [
            _rail(l, expanded: width >= Breakpoints.expanded),
            Expanded(child: shell),
          ],
        ),
      );
    }

    final barColor = Theme.of(context).colorScheme.surfaceContainer;
    return Scaffold(
      body: shell,
      // The system nav-bar inset goes below the bar, not inside it: inside,
      // it squeezes the bar's fixed-height band and the labels spill under
      // the 3-button navigation on edge-to-edge Android (15+).
      bottomNavigationBar: ColoredBox(
        color: barColor,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: _navBar(l, barColor),
        ),
      ),
    );
  }

  Widget _rail(AppLocalizations l, {required bool expanded}) {
    final type = expanded
        ? M3ENavigationRailType.alwaysExpand
        : M3ENavigationRailType.alwaysCollapse;
    return SafeArea(
      right: false,
      child: M3ENavigationRail(
        // The rail reads its type only when created.
        key: ValueKey(type),
        type: type,
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        alignment: M3ENavigationRailAlignment.center,
        sections: [
          M3ENavigationRailSection(
            destinations: [
              M3ENavigationRailDestination(
                icon: const Icon(Icons.water_outlined),
                selectedIcon: const Icon(Icons.water),
                label: l.navLakes,
              ),
              M3ENavigationRailDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map),
                label: l.navMap,
              ),
              M3ENavigationRailDestination(
                icon: const Icon(Icons.eco_outlined),
                selectedIcon: const Icon(Icons.eco),
                label: l.navPlan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBar(AppLocalizations l, Color barColor) {
    return M3ENavigationBar(
      safeArea: false,
      backgroundColor: barColor,
      selectedIndex: shell.currentIndex,
      onDestinationSelected: _select,
      destinations: [
        M3ENavigationBarDestination(
          icon: const Icon(Icons.water_outlined),
          selectedIcon: const Icon(Icons.water),
          label: l.navLakes,
        ),
        M3ENavigationBarDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map),
          label: l.navMap,
        ),
        M3ENavigationBarDestination(
          icon: const Icon(Icons.eco_outlined),
          selectedIcon: const Icon(Icons.eco),
          label: l.navPlan,
        ),
      ],
    );
  }
}
