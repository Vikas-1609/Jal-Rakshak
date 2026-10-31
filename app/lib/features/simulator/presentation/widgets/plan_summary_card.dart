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
          TweenAnimationBuilder<double>(
            tween: Tween(end: savedFrac),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => M3EProgressIndicator.linearWavy(
              value: v,
              color: scheme.primary,
              trackColor: scheme.surface.withValues(alpha: 0.7),
            ),
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
