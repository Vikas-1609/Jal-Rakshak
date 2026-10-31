import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/lakes_providers.dart';

/// Expressive bottom sheet for switching the lake on the Map and Plan tabs.
Future<void> showLakePicker(BuildContext context) {
  Haptics.selection();
  return M3EBottomSheet.show<void>(
    context,
    // Opens over the Google map, which would otherwise take its clicks (web).
    builder: (_) => PointerInterceptor(child: const _LakePicker()),
  );
}

class _LakePicker extends ConsumerWidget {
  const _LakePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = ref.watch(appLanguageProvider);
    final lakes = ref.watch(lakesProvider).value ?? const [];
    final current = ref.watch(selectedLakeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(l.chooseLake, style: emphasized(context).titleLarge),
          ),
          M3EList(
            itemCount: lakes.length,
            onTap: (i) {
              Haptics.selection();
              ref.read(selectedLakeIdProvider.notifier).select(lakes[i].id);
              Navigator.pop(context);
            },
            itemBuilder: (context, i) {
              final lake = lakes[i];
              final selected = lake.id == current?.id;
              return M3EListItem(
                headline: lake.name(lang),
                supportingText: l.lakePickerSubtitle(
                  lake.district(lang),
                  fmtTonnes(l, lake.totalT),
                ),
                selected: selected,
                leading: Icon(
                  Icons.water,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                trailing: selected
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
