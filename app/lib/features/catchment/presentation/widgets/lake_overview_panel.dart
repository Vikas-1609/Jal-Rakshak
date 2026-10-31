import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/risk_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/charts.dart';
import '../../../simulator/application/simulator_providers.dart';
import '../../application/catchment_providers.dart';
import '../../domain/catchment.dart';
import '../zone_labels.dart';

/// Sheet content with no zone selected: legend and the biggest sources.
class LakeOverviewPanel extends ConsumerWidget {
  const LakeOverviewPanel({super.key, required this.catchment});

  final Catchment catchment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sim = ref.watch(simResultProvider(catchment.lakeId)).value;
    final top = catchment.byTonnes.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.whereSoilFrom, style: emphasized(context).titleLarge),
        const SizedBox(height: 4),
        Text(l.tapZoneHint, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        RiskLegend(min: catchment.minLoss, max: catchment.maxLoss),
        const SizedBox(height: 20),
        Text(l.biggestSources, style: emphasized(context).titleMedium),
        const SizedBox(height: 8),
        M3EList(
          itemCount: top.length,
          onTap: (i) {
            Haptics.selection();
            ref.read(selectedZoneIdProvider.notifier).select(top[i].id);
          },
          itemBuilder: (context, i) {
            final z = top[i];
            return M3EListItem(
              headline: '${z.id} · ${l.zoneType(z.type)}',
              supportingText:
                  '${l.perYear(fmtTonnes(l, z.tTotal))} · ${l.tPerHaYear(fmt1(z.soilLoss))}',
              trailingText: '${fmt1(catchment.shareOf(z) * 100)}%',
              leading: TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                  end: riskColor(
                    soilLossNow(z, sim),
                    catchment.minLoss,
                    catchment.maxLoss,
                  ),
                ),
                duration: const Duration(milliseconds: 500),
                builder: (_, c, _) =>
                    CircleAvatar(radius: 10, backgroundColor: c),
              ),
            );
          },
        ),
      ],
    );
  }
}
