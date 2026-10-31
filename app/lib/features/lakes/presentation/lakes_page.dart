import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../application/lakes_providers.dart';
import '../domain/lake.dart';
import 'widgets/lake_card.dart';

/// Home tab: the region at a glance, then one card per lake.
class LakesPage extends ConsumerWidget {
  const LakesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView(
        value: ref.watch(lakesProvider),
        onRetry: () => ref.invalidate(lakesProvider),
        data: (lakes) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _RegionHeader(lakes: lakes)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  context.l10n.lakesByRate,
                  style: emphasized(context).titleMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: lakes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => FadeSlideIn(
                  index: i,
                  child: LakeCard(
                    lake: lakes[i],
                    rank: i + 1,
                    onOpen: () {
                      Haptics.tap();
                      ref
                          .read(selectedLakeIdProvider.notifier)
                          .select(lakes[i].id);
                      context.go(Routes.map);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({required this.lakes});

  final List<Lake> lakes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = emphasized(context);
    final total = lakes.fold<double>(0, (s, l) => s + l.totalT);
    final land = lakes.fold<double>(0, (s, l) => s + l.landKm2);
    final onHeader = scheme.onPrimaryContainer;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        12,
        28,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(M3EShapes.extraExtraLarge),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative expressive shape behind the headline number,
          // slowly turning.
          Positioned(right: -16, top: 44, child: _SpinningShape(scheme)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  M3EShapeContainer(
                    kind: M3EShapeKind.gem,
                    width: 36,
                    height: 36,
                    color: scheme.primary,
                    child: Icon(
                      Icons.water_drop,
                      size: 18,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.appTitle,
                      style: type.titleLarge.copyWith(color: onHeader),
                    ),
                  ),
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    icon: Icon(Icons.settings_outlined, color: onHeader),
                    tooltip: l.settings,
                    onPressed: () {
                      Haptics.selection();
                      context.push(Routes.settings);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l.regionHeadline,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: onHeader),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: total),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(
                  fmtTonnes(l, v),
                  style: type.displayMedium.copyWith(color: onHeader),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderChip(l.lakeCount(lakes.length)),
                  _HeaderChip(l.catchmentArea(groupIndian(land.round()))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpinningShape extends StatefulWidget {
  const _SpinningShape(this.scheme);

  final ColorScheme scheme;

  @override
  State<_SpinningShape> createState() => _SpinningShapeState();
}

class _SpinningShapeState extends State<_SpinningShape>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: M3EShapeContainer(
        kind: M3EShapeKind.sunny,
        width: 150,
        height: 150,
        color: widget.scheme.primary.withValues(alpha: 0.12),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        shape: M3EShapes.stadium,
      ),
      child: Text(
        label,
        style: emphasized(context).labelLarge
            .copyWith(color: scheme.onPrimaryContainer),
      ),
    );
  }
}
