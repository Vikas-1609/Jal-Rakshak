import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/risk_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/charts.dart';
import '../../../../core/widgets/common.dart';
import '../../../insights/presentation/widgets/explanation_card.dart';
import '../../../insights/presentation/widgets/zone_chat_card.dart';
import '../../../simulator/presentation/widgets/fix_toggles.dart';
import '../../domain/catchment.dart';
import '../../domain/zone.dart';

/// Everything about one zone: numbers, land, fixes and Gemini's explanation.
/// A plain column, so it can sit in the map sheet or in a page's scroll view.
class ZoneDetailContent extends StatelessWidget {
  const ZoneDetailContent({
    super.key,
    required this.catchment,
    required this.zone,
  });

  final Catchment catchment;
  final Zone zone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final summary = catchment.summary;
    final onStats = scheme.onPrimaryContainer;

    final sections = <Widget>[
      SectionCard(
        color: scheme.primaryContainer,
        child: Row(
          children: [
            StatTile(
              label: l.statSoilLoss,
              value: l.tPerHa(fmt1(zone.soilLoss)),
              caption: l.captionLakeAvg(fmt1(summary.meanSoilLoss)),
              color: onStats,
            ),
            StatTile(
              label: l.statPerYear,
              value: fmtTonnes(l, zone.tTotal),
              caption: l.captionLand('${zone.landKm2.round()}'),
              color: onStats,
            ),
            StatTile(
              label: l.statOfLake,
              value: '${fmt1(catchment.shareOf(zone) * 100)}%',
              caption: l.captionSlope(fmt1(zone.slopeDeg)),
              color: onStats,
            ),
          ],
        ),
      ),
      SectionCard(
        title: l.landAndSoil,
        icon: Icons.layers_outlined,
        child: Column(
          children: [
            StackedBar(
              title: l.landCover,
              parts: [
                (
                  label: l.cropland,
                  frac: zone.cropFrac,
                  color: landColors.crop,
                ),
                (
                  label: l.scrubBare,
                  frac: zone.hillFrac,
                  color: landColors.hill,
                ),
                (
                  label: l.forest,
                  frac: zone.treeFrac,
                  color: landColors.forest,
                ),
                (
                  label: l.builtUp,
                  frac: zone.builtFrac,
                  color: landColors.built,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StackedBar(
              title: l.soilSources,
              parts: [
                (
                  label: l.cropland,
                  frac: zone.tCrop / zone.tTotal,
                  color: landColors.crop,
                ),
                (
                  label: l.hillLand,
                  frac: zone.tHill / zone.tTotal,
                  color: landColors.hill,
                ),
                (
                  label: l.otherLand,
                  frac: zone.tOther / zone.tTotal,
                  color: landColors.forest,
                ),
              ],
            ),
          ],
        ),
      ),
      SectionCard(
        title: l.whatIf,
        icon: Icons.eco_outlined,
        child: FixToggles(lakeId: catchment.lakeId, zone: zone),
      ),
      ExplanationCard(lakeId: catchment.lakeId, zoneId: zone.id),
      ZoneChatCard(
        // A fresh input per zone, so a half-typed question doesn't carry over.
        key: ValueKey('chat-${catchment.lakeId}-${zone.id}'),
        lakeId: catchment.lakeId,
        zoneId: zone.id,
      ),
    ];

    return Column(
      children: [
        for (final (i, s) in sections.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeSlideIn(index: i, child: s),
          ),
      ],
    );
  }
}
