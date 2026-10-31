import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catchment/application/catchment_providers.dart';
import '../../catchment/domain/catchment.dart';
import '../../lakes/presentation/widgets/lake_switcher.dart';
import '../../settings/application/settings_providers.dart';
import '../application/simulator_providers.dart';
import '../domain/fixes.dart';
import 'widgets/plan_summary_card.dart';
import 'widgets/zone_plan_tile.dart';

/// Plan tab: build a restoration plan for the selected lake, zone by zone.
/// Shows the guide on the first visit.
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(settingsProvider).planIntroSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(Routes.planIntro);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: M3EAppBar.top(
        variant: M3EAppBarVariant.mediumFlexible,
        titleText: l.planTitle,
        subtitleText: l.planSubtitle,
        actions: [
          M3EIconButton(
            variant: M3EIconButtonVariant.tonal,
            icon: const Icon(Icons.help_outline),
            tooltip: l.howPlanWorks,
            onPressed: () {
              Haptics.selection();
              context.push(Routes.planIntro);
            },
          ),
        ],
      ),
      body: AsyncView(
        value: ref.watch(currentCatchmentProvider),
        onRetry: () => retryCurrentCatchment(ref),
        data: (catchment) => _PlanBody(catchment: catchment),
      ),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.catchment});

  final Catchment catchment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final type = emphasized(context);
    final fixes = ref.read(fixesProvider(catchment.lakeId).notifier);
    final hasFixes = ref.watch(fixesProvider(catchment.lakeId)).isNotEmpty;
    void apply(VoidCallback plan) {
      Haptics.success();
      plan();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const Align(alignment: Alignment.centerLeft, child: LakeSwitcher()),
        const SizedBox(height: 12),
        FadeSlideIn(child: PlanSummaryCard(catchment: catchment)),
        const SizedBox(height: 20),
        Text(l.quickPlans, style: type.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            M3EButton.filled(
              onPressed: () => apply(() => fixes.applyToWorst(4)),
              icon: const Icon(Icons.local_fire_department),
              label: Text(l.worstZones),
            ),
            M3EButton.tonal(
              onPressed: () => apply(
                () => fixes.applyEverywhere(
                  const Fixes(trenches: true, reveg: true),
                ),
              ),
              icon: const Icon(Icons.terrain),
              label: Text(l.allHillLand),
            ),
            M3EButton.tonal(
              onPressed: () =>
                  apply(() => fixes.applyEverywhere(const Fixes(bunds: true))),
              icon: const Icon(Icons.agriculture),
              label: Text(l.allFarmBunds),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: hasFixes
                  ? M3EButton.outlined(
                      onPressed: () {
                        Haptics.selection();
                        fixes.reset();
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: Text(l.clearPlan),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l.zonesBySoil, style: type.titleMedium),
        const SizedBox(height: 10),
        for (final (i, z) in catchment.byTonnes.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FadeSlideIn(
              index: i,
              child: ZonePlanTile(
                catchment: catchment,
                zone: z,
                onOpen: () {
                  Haptics.selection();
                  context.push(Routes.zone(z.id));
                },
              ),
            ),
          ),
      ],
    );
  }
}
