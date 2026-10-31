import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../utils/haptics.dart';

/// Expressive bottom navigation around the three tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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

  Widget _navBar(AppLocalizations l, Color barColor) {
    return M3ENavigationBar(
      safeArea: false,
      backgroundColor: barColor,
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (i) {
        Haptics.selection();
        // Tapping the current tab again returns to its first page.
        shell.goBranch(i, initialLocation: i == shell.currentIndex);
      },
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
