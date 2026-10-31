import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../catchment/domain/zone.dart';
import '../../application/simulator_providers.dart';
import '../../domain/fixes.dart';

/// The three fixes for one zone as an expressive segmented list of
/// switches, plus the resulting saving.
class FixToggles extends ConsumerWidget {
  const FixToggles({super.key, required this.lakeId, required this.zone});

  final String lakeId;
  final Zone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fixes = ref.watch(fixesProvider(lakeId))[zone.id] ?? const Fixes();
    final result = ref.watch(simResultProvider(lakeId)).value?.zones[zone.id];
    void update(Fixes f) {
      Haptics.selection();
      ref.read(fixesProvider(lakeId).notifier).set(zone.id, f);
    }

    final rows = [
      (
        icon: Icons.agriculture_outlined,
        title: l.fixBunds,
        subtitle: l.fixBundsSub(fmtPct(zone.cropFrac)),
        value: fixes.bunds,
        enabled: zone.tCrop > 0,
        apply: (bool v) => update(fixes.copyWith(bunds: v)),
      ),
      (
        icon: Icons.terrain_outlined,
        title: l.fixTrenches,
        subtitle: l.fixTrenchesSub(fmtPct(zone.hillFrac)),
        value: fixes.trenches,
        enabled: zone.tHill > 0,
        apply: (bool v) => update(fixes.copyWith(trenches: v)),
      ),
      (
        icon: Icons.grass_outlined,
        title: l.fixReveg,
        subtitle: l.fixRevegSub,
        value: fixes.reveg,
        enabled: zone.tHill > 0,
        apply: (bool v) => update(fixes.copyWith(reveg: v)),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        M3EList(
          itemCount: rows.length,
          onTap: (i) {
            if (rows[i].enabled) rows[i].apply(!rows[i].value);
          },
          itemBuilder: (context, i) {
            final r = rows[i];
            return M3EListItem(
              headline: r.title,
              supportingText: r.subtitle,
              enabled: r.enabled,
              leading: Icon(r.icon),
              trailing: M3ESwitch(
                value: r.value,
                selectedIcon: const Icon(Icons.check),
                onChanged: r.enabled ? r.apply : null,
              ),
            );
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: fixes.any && result != null && result.savedT > 0
              ? SavingBanner(
                  text: l.savingBanner(
                    fmtTonnes(l, result.savedT),
                    result.savedPct.toStringAsFixed(0),
                    fmt1(result.soilLossNew),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Tertiary-container confirmation for a soil saving, with a morph shape
/// that pops in.
class SavingBanner extends StatelessWidget {
  const SavingBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: M3EShapes.radiusLarge,
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: M3EShapeContainer(
              kind: M3EShapeKind.sunny,
              width: 40,
              height: 40,
              color: scheme.tertiary,
              child: Icon(Icons.eco, color: scheme.onTertiary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: emphasized(context).bodyMedium
                  .copyWith(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
