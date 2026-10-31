import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/risk_colors.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/catchment.dart';
import '../../domain/zone.dart';
import '../zone_labels.dart';

/// Zone ID with its type and risk tags; optional trailing action.
class ZoneHeader extends StatelessWidget {
  const ZoneHeader({
    super.key,
    required this.catchment,
    required this.zone,
    this.trailing,
  });

  final Catchment catchment;
  final Zone zone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        M3EShapeContainer(
          kind: M3EShapeKind.gem,
          width: 52,
          height: 52,
          color: scheme.primary,
          child: Center(
            child: Text(
              zone.id,
              style: emphasized(context).titleSmall
                  .copyWith(color: scheme.onPrimary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Tag(l.zoneType(zone.type)),
              Tag(
                l.riskLabel(l.riskClass(zone.riskClass)),
                color: riskColor(
                  zone.soilLoss,
                  catchment.minLoss,
                  catchment.maxLoss,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
