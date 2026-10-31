import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../simulator/application/simulator_providers.dart';
import '../../domain/catchment.dart';

/// Floating card on the map: the lake's yearly soil loss, live with fixes.
class MapStatusCard extends ConsumerWidget {
  const MapStatusCard({super.key, required this.catchment});

  final Catchment catchment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = emphasized(context);
    final sim = ref.watch(simResultProvider(catchment.lakeId)).value;
    final baseline = catchment.summary.totalT;
    final saving = sim != null && sim.savedT > 0;

    return M3ECard(
      variant: M3ECardVariant.elevated,
      color: scheme.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      borderRadius: M3EShapes.radiusLarge,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.soilLostPerYear,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: sim?.scenarioT ?? baseline),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) =>
                      Text(fmtTonnes(l, v), style: type.headlineSmall),
                ),
                Text(
                  saving
                      ? l.wasSaving(
                          fmtTonnes(l, baseline),
                          fmtTonnes(l, sim.savedT),
                        )
                      : l.areaZones(
                          '${catchment.summary.landKm2.round()}',
                          catchment.zones.length,
                        ),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          AnimatedScale(
            scale: saving ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            child: M3EShapeContainer(
              kind: M3EShapeKind.sunny,
              width: 64,
              height: 64,
              color: scheme.tertiaryContainer,
              child: Center(
                child: Text(
                  saving ? '−${sim.savedPct.toStringAsFixed(0)}%' : '',
                  style: type.labelLarge.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
