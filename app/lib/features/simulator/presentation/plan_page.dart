import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catchment/application/catchment_providers.dart';
import '../../catchment/domain/catchment.dart';
import '../../lakes/presentation/widgets/lake_switcher.dart';
import '../../report/application/report_export.dart';
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

  bool _exporting = false;

  Future<void> _export(Catchment catchment) async {
    final l = context.l10n;
    Haptics.selection();
    setState(() => _exporting = true);
    M3ESnackbar.show(context, message: l.exportingReport);
    try {
      await exportPlanReport(ref, l, catchment);
    } catch (e) {
      if (mounted) M3ESnackbar.show(context, message: l.exportFailed('$e'));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final catchment = ref.watch(currentCatchmentProvider).value;
    return Scaffold(
      appBar: M3EAppBar.top(
        variant: M3EAppBarVariant.mediumFlexible,
        titleText: l.planTitle,
        subtitleText: l.planSubtitle,
        actions: [
          M3EIconButton(
            variant: M3EIconButtonVariant.tonal,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l.exportReport,
            onPressed: catchment == null || _exporting
                ? null
                : () => _export(catchment),
          ),
          const SizedBox(width: 4),
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

class _PlanBody extends ConsumerStatefulWidget {
  const _PlanBody({required this.catchment});

  final Catchment catchment;

  @override
  ConsumerState<_PlanBody> createState() => _PlanBodyState();
}

class _PlanBodyState extends ConsumerState<_PlanBody> {
  final _cardKey = GlobalKey();
  final _showStrip = ValueNotifier(false);

  @override
  void dispose() {
    _showStrip.dispose();
    super.dispose();
  }

  /// Shows the pinned strip once the summary card's progress bar has
  /// scrolled up behind the app bar.
  bool _onScroll(ScrollNotification n) {
    final card = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final body = context.findRenderObject() as RenderBox?;
    if (card != null && body != null && card.attached) {
      final bottom =
          card.localToGlobal(Offset.zero, ancestor: body).dy + card.size.height;
      _showStrip.value = bottom < 56;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final catchment = widget.catchment;
    final l = context.l10n;
    final type = emphasized(context);
    final fixes = ref.read(fixesProvider(catchment.lakeId).notifier);
    final hasFixes = ref.watch(fixesProvider(catchment.lakeId)).isNotEmpty;
    void apply(VoidCallback plan) {
      Haptics.success();
      plan();
    }

    return LayoutBuilder(
      builder: (context, c) {
        final side = gutter(c.maxWidth, maxWidth: 1100);
        final columns = c.maxWidth >= Breakpoints.twoColumns ? 2 : 1;
        final list = ListView(
          padding: EdgeInsets.fromLTRB(side, 4, side, 24),
          children: [
            const Align(alignment: Alignment.centerLeft, child: LakeSwitcher()),
            const SizedBox(height: 12),
            FadeSlideIn(
              child: PlanSummaryCard(key: _cardKey, catchment: catchment),
            ),
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
                  onPressed: () => apply(
                    () => fixes.applyEverywhere(const Fixes(bunds: true)),
                  ),
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
            ResponsiveColumns(
              columns: columns,
              spacing: 10,
              children: [
                for (final (i, z) in catchment.byTonnes.indexed)
                  FadeSlideIn(
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
              ],
            ),
          ],
        );
        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: list,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder(
                valueListenable: _showStrip,
                builder: (context, show, child) => IgnorePointer(
                  ignoring: !show,
                  child: AnimatedSlide(
                    offset: show ? Offset.zero : const Offset(0, -1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: show ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: child,
                    ),
                  ),
                ),
                child: PlanProgressStrip(
                  catchment: catchment,
                  padding: EdgeInsets.fromLTRB(side, 10, side, 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
