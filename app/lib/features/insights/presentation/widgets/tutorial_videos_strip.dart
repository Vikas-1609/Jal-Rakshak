import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../catchment/domain/zone.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/tutorial_videos.dart';

/// "Learn how" video tiles for the fixes that apply to [zone], in the app's
/// language. Tapping one opens YouTube (the app on phones, a tab on web).
class TutorialVideosStrip extends ConsumerWidget {
  const TutorialVideosStrip({super.key, required this.zone});

  final Zone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final type = emphasized(context);
    final videos =
        tutorialVideos[ref.watch(appLanguageProvider)] ?? tutorialVideos['en']!;
    // Same fixes the plan offers for this zone, the bigger soil source first.
    final hillFirst = zone.tHill >= zone.tCrop;
    final topics = [
      if (hillFirst && zone.tHill > 0) ...[
        TutorialTopic.trenches,
        TutorialTopic.reveg,
      ],
      if (zone.tCrop > 0) TutorialTopic.bunds,
      if (!hillFirst && zone.tHill > 0) ...[
        TutorialTopic.trenches,
        TutorialTopic.reveg,
      ],
    ];
    final tiles = [
      for (final t in topics)
        for (final v in videos[t] ?? const <TutorialVideo>[]) (t, v),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.smart_display_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(l.videosTitle, style: type.titleSmall),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _VideoTile(topic: tiles[i].$1, video: tiles[i].$2),
          ),
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.topic, required this.video});

  final TutorialTopic topic;
  final TutorialVideo video;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topicName = switch (topic) {
      TutorialTopic.bunds => l.fixBunds,
      TutorialTopic.trenches => l.fixTrenches,
      TutorialTopic.reveg => l.fixReveg,
    };

    return SizedBox(
      width: 220,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: M3EShapes.radiusLarge,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Haptics.selection();
            launchUrl(video.watchUrl, mode: LaunchMode.externalApplication);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      // YouTube thumbnails have no CORS headers, so on web
                      // they're shown as plain <img> elements.
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.smart_display,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Center(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xCC000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          child: Text(
                            video.duration,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      video.channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
