import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/lakes_providers.dart';
import 'lake_picker_sheet.dart';

/// Tonal pill showing the selected lake; tap to switch lakes.
class LakeSwitcher extends ConsumerWidget {
  const LakeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lake = ref.watch(selectedLakeProvider);
    final lang = ref.watch(appLanguageProvider);
    return M3EButton.tonal(
      onPressed: () => showLakePicker(context),
      icon: const Icon(Icons.water),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cross-fade when the lake changes.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              lake?.name(lang) ?? context.l10n.chooseLake,
              key: ValueKey(lake?.id),
            ),
          ),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    );
  }
}
