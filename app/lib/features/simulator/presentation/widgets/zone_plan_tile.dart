import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/risk_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../catchment/domain/catchment.dart';
import '../../../catchment/domain/zone.dart';
import '../../../catchment/presentation/zone_labels.dart';
import '../../application/simulator_providers.dart';
import '../../domain/fixes.dart';

/// One zone in the plan: its numbers and the three fixes as filter chips.
class ZonePlanTile extends ConsumerWidget {
  const ZonePlanTile({
    super.key,
    required this.catchment,
    required this.zone,
    this.onOpen,
  });

  final Catchment catchment;
  final Zone zone;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = emphasized(context);
    final lakeId = catchment.lakeId;
    final fixes = ref.watch(fixesProvider(lakeId))[zone.id] ?? const Fixes();
    final sim = ref.watch(simResultProvider(lakeId)).value;
    final result = sim?.zones[zone.id];
    void update(Fixes f) {
      Haptics.selection();
      ref.read(fixesProvider(lakeId).notifier).set(zone.id, f);
    }

    return M3ECard(
      variant: M3ECardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      borderRadius: M3EShapes.radiusLarge,
      onPressed: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 14,
                height: 14,
                decoration: ShapeDecoration(
                  color: riskColor(
                    soilLossNow(zone, sim),
                    catchment.minLoss,
                    catchment.maxLoss,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${zone.id} · ${l.zoneType(zone.type)}',
                  style: type.titleSmall,
                ),
              ),
              Text(
                l.perYear(fmtTonnes(l, zone.tTotal)),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (zone.tCrop > 0)
                M3EChip(
                  label: l.chipBunds,
                  type: M3EChipType.filter,
                  selected: fixes.bunds,
                  onPressed: () => update(fixes.copyWith(bunds: !fixes.bunds)),
                ),
              if (zone.tHill > 0) ...[
                M3EChip(
                  label: l.chipTrenches,
                  type: M3EChipType.filter,
                  selected: fixes.trenches,
                  onPressed: () =>
                      update(fixes.copyWith(trenches: !fixes.trenches)),
                ),
                M3EChip(
                  label: l.chipReveg,
                  type: M3EChipType.filter,
                  selected: fixes.reveg,
                  onPressed: () => update(fixes.copyWith(reveg: !fixes.reveg)),
                ),
              ],
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: fixes.any && result != null && result.savedT > 0
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      l.zoneSaves(
                        fmtTonnes(l, result.savedT),
                        result.savedPct.toStringAsFixed(0),
                      ),
                      style: type.labelLarge.copyWith(color: scheme.tertiary),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
