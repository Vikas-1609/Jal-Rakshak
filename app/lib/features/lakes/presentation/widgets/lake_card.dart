import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/lake.dart';

/// Shapes for the rank badge, so each lake reads at a glance.
const _rankShapes = [
  M3EShapeKind.sunny,
  M3EShapeKind.gem,
  M3EShapeKind.pentagon,
  M3EShapeKind.clamShell,
];

/// One lake on the home tab: rank, story, key numbers, open-on-map action.
class LakeCard extends ConsumerWidget {
  const LakeCard({
    super.key,
    required this.lake,
    required this.rank,
    required this.onOpen,
  });

  final Lake lake;
  final int rank;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final type = emphasized(context);
    final top = rank == 1;
    final story = lake.story(lang);

    return M3ECard(
      variant: M3ECardVariant.filled,
      color: top ? scheme.tertiaryContainer : scheme.surfaceContainerLow,
      padding: const EdgeInsets.all(20),
      borderRadius: M3EShapes.radiusExtraLarge,
      haptic: M3EHapticFeedback.none,
      onPressed: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              M3EShapeContainer(
                kind: _rankShapes[(rank - 1) % _rankShapes.length],
                width: 48,
                height: 48,
                color: top ? scheme.tertiary : scheme.primaryContainer,
                child: Center(
                  child: Text(
                    '$rank',
                    style: type.titleMedium.copyWith(
                      color: top
                          ? scheme.onTertiary
                          : scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lake.name(lang), style: type.titleLarge),
                    Text(
                      l.districtZones(lake.district(lang), lake.zoneCount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: scheme.primary),
            ],
          ),
          if (story.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(story, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              StatTile(
                label: l.statSoilLostYear,
                value: fmtTonnes(l, lake.totalT),
              ),
              StatTile(
                label: l.statPerHectare,
                value: l.tonnes(fmt1(lake.meanSoilLoss)),
              ),
              StatTile(
                label: l.statFixable,
                value: '${lake.allFixesSavedPct.round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
