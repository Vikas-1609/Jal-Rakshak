import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/common.dart';
import '../../../catchment/application/catchment_providers.dart';
import '../../application/insights_providers.dart';
import '../../domain/explanation.dart';
import 'tutorial_videos_strip.dart';

/// Gemini's "why, and what to do" for one zone, in the app's language.
class ExplanationCard extends ConsumerWidget {
  const ExplanationCard({
    super.key,
    required this.lakeId,
    required this.zoneId,
  });

  final String lakeId, zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final zone = (lakeId: lakeId, zoneId: zoneId);
    final explanation = ref.watch(explanationProvider(zone));
    final zoneData = ref.watch(catchmentProvider(lakeId)).value?.byId[zoneId];

    return SectionCard(
      title: l.whyTitle,
      icon: Icons.auto_awesome,
      trailing: switch (explanation) {
        AsyncData(:final value) when value.fromCache => Tooltip(
          message: l.savedOffline,
          child: Icon(
            Icons.offline_pin,
            size: 20,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        _ => null,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            child: switch (explanation) {
              AsyncData(:final value) => _ExplanationBody(
                key: ValueKey(value.headline),
                ex: value,
              ),
              AsyncError(:final error) => Row(
                key: const ValueKey('error'),
                children: [
                  Expanded(child: Text(l.explanationError('$error'))),
                  M3EButton.text(
                    onPressed: () {
                      Haptics.selection();
                      ref.invalidate(explanationProvider(zone));
                    },
                    child: Text(l.retry),
                  ),
                ],
              ),
              _ => const _LoadingSkeleton(key: ValueKey('loading')),
            },
          ),
          // Videos once Gemini has answered, so they follow its reasons.
          if (explanation.hasValue && zoneData != null) ...[
            const SizedBox(height: 16),
            FadeSlideIn(child: TutorialVideosStrip(zone: zoneData)),
          ],
          const SizedBox(height: 10),
          Text(l.geminiFootnote, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Shimmering placeholder shaped like the explanation that's coming.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const M3ELoadingIndicator(size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.geminiLoading,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 20, width: 260),
              SizedBox(height: 12),
              SkeletonBox(height: 12),
              SizedBox(height: 8),
              SkeletonBox(height: 12, width: 220),
              SizedBox(height: 8),
              SkeletonBox(height: 12, width: 280),
              SizedBox(height: 16),
              SkeletonBox(height: 64, radius: 16),
              SizedBox(height: 8),
              SkeletonBox(height: 64, radius: 16),
              SizedBox(height: 12),
              SkeletonBox(height: 48, radius: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExplanationBody extends StatelessWidget {
  const _ExplanationBody({super.key, required this.ex});

  final Explanation ex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = emphasized(context);
    var i = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          index: i++,
          child: Text(ex.headline, style: type.titleMedium),
        ),
        const SizedBox(height: 10),
        for (final w in ex.why)
          FadeSlideIn(
            index: i++,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: M3EShapeContainer(
                      kind: M3EShapeKind.gem,
                      width: 8,
                      height: 8,
                      color: scheme.primary,
                    ),
                  ),
                  Expanded(child: Text(w)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Custom tiles rather than list items, so long Gemini text wraps
        // instead of being cut off.
        for (final a in ex.actions)
          FadeSlideIn(
            index: i++,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: M3EShapes.radiusLarge,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.construction, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.where,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(a.title, style: type.titleSmall),
                        const SizedBox(height: 4),
                        Text(a.impact),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FadeSlideIn(
          index: i++,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: M3EShapes.radiusLarge,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.agriculture, color: scheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ex.farmerTip,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
