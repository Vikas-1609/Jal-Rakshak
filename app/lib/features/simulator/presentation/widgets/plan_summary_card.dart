import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../catchment/domain/catchment.dart';
import '../../application/simulator_providers.dart';

/// Lake soil loss with the current plan: animated number and a wavy
/// progress bar showing the share of soil the plan keeps in place.
class PlanSummaryCard extends ConsumerWidget {
  const PlanSummaryCard({super.key, required this.catchment});

  final Catchment catchment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = emphasized(context);
    final sim = ref.watch(simResultProvider(catchment.lakeId)).value;
    final baseline = catchment.summary.totalT;
    final now = sim?.scenarioT ?? baseline;
    final savedFrac = sim == null ? 0.0 : sim.savedT / baseline;
    final onCard = scheme.onPrimaryContainer;

    return M3ECard(
      variant: M3ECardVariant.filled,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.all(22),
      borderRadius: M3EShapes.radiusExtraLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.soilWithPlan,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: onCard),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(end: now),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              fmtTonnes(l, v),
              style: type.displaySmall.copyWith(color: onCard),
            ),
          ),
          const SizedBox(height: 16),
          _SavedProgress(
            value: savedFrac,
            trackColor: scheme.surface.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              sim == null || sim.savedT <= 0
                  ? l.noFixesYet(fmtTonnes(l, baseline))
                  : l.planSaving(
                      fmtTonnes(l, sim.savedT),
                      sim.savedPct.toStringAsFixed(0),
                      fmtTonnes(l, baseline),
                    ),
              key: ValueKey(sim?.savedT),
              style: type.bodyMedium.copyWith(color: onCard),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact strip pinned under the app bar while the summary card is
/// scrolled out of view: the same progress bar plus soil left and % saved.
class PlanProgressStrip extends ConsumerWidget {
  const PlanProgressStrip({
    super.key,
    required this.catchment,
    required this.padding,
  });

  final Catchment catchment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = emphasized(context);
    final sim = ref.watch(simResultProvider(catchment.lakeId)).value;
    final baseline = catchment.summary.totalT;
    final now = sim?.scenarioT ?? baseline;
    final savedFrac = sim == null ? 0.0 : sim.savedT / baseline;

    return Material(
      color: scheme.surfaceContainer,
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.3),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Text(fmtTonnes(l, now), style: type.titleSmall),
            const SizedBox(width: 14),
            Expanded(
              child: _SavedProgress(
                value: savedFrac,
                trackColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${(sim?.savedPct ?? 0).toStringAsFixed(0)}%',
              style: type.titleSmall.copyWith(color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedProgress extends StatelessWidget {
  const _SavedProgress({required this.value, required this.trackColor});

  final double value;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => M3EProgressIndicator.linearWavy(
        value: v,
        color: Theme.of(context).colorScheme.primary,
        trackColor: trackColor,
      ),
    );
  }
}
