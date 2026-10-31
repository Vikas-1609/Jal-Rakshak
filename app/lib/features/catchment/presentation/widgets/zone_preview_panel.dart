import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/common.dart';
import '../../application/catchment_providers.dart';
import '../../domain/catchment.dart';
import '../../domain/zone.dart';
import 'zone_header.dart';

/// Sheet content for a tapped zone: key numbers and the way into details.
class ZonePreviewPanel extends ConsumerWidget {
  const ZonePreviewPanel({
    super.key,
    required this.catchment,
    required this.zone,
    required this.onOpenDetail,
  });

  final Catchment catchment;
  final Zone zone;

  /// Expands the sheet into the full zone view.
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZoneHeader(
          catchment: catchment,
          zone: zone,
          trailing: M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            icon: const Icon(Icons.close),
            tooltip: l.back,
            onPressed: () {
              Haptics.selection();
              ref.read(selectedZoneIdProvider.notifier).select(null);
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            StatTile(
              label: l.statSoilLoss,
              value: l.tPerHa(fmt1(zone.soilLoss)),
              caption: l.captionAvg(fmt1(catchment.summary.meanSoilLoss)),
            ),
            StatTile(
              label: l.statPerYear,
              value: fmtTonnes(l, zone.tTotal),
              caption: l.captionLand('${zone.landKm2.round()}'),
            ),
            StatTile(
              label: l.statOfLake,
              value: '${fmt1(catchment.shareOf(zone) * 100)}%',
              caption: l.captionSlope(fmt1(zone.slopeDeg)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: M3EButton.filled(
            size: M3EButtonSize.md,
            onPressed: () {
              Haptics.tap();
              onOpenDetail();
            },
            icon: const Icon(Icons.auto_awesome),
            label: Text(l.whyButton),
          ),
        ),
      ],
    );
  }
}
