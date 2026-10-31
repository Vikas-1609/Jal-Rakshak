import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Renders an [AsyncValue]: expressive loading shape while loading,
/// message + retry on error.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => ErrorState(
        message: error.toString(),
        onRetry: onRetry,
      ),
      _ => const Center(
        child: M3ELoadingIndicator(
          variant: M3ELoadingIndicatorVariant.contained,
          size: 72,
        ),
      ),
    };
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            M3EShapeContainer(
              kind: M3EShapeKind.sunny,
              width: 88,
              height: 88,
              color: scheme.errorContainer,
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              M3EButton.tonal(
                onPressed: () {
                  Haptics.selection();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A filled expressive card with an optional title row, for page sections.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    this.color,
    required this.child,
  });

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return M3ECard(
      variant: M3ECardVariant.filled,
      color: color ?? scheme.surfaceContainerLow,
      padding: const EdgeInsets.all(20),
      borderRadius: M3EShapes.radiusExtraLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: scheme.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title!, style: emphasized(context).titleMedium),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Label, big emphasized value and a small caption, for rows of stats.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.color,
  });

  final String label, value;
  final String? caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // One line, shrinking if needed, so values in a row stay aligned
            // even with longer Hindi labels.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: t.labelMedium?.copyWith(color: muted),
              ),
            ),
            const SizedBox(height: 2),
            // Big values like "11.3 lakh t" shrink rather than overlap.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: emphasized(context).titleLarge.copyWith(color: color),
              ),
            ),
            if (caption != null)
              Text(caption!, style: t.labelSmall?.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }
}

/// Small pill, e.g. "Hill zone" or "High risk".
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.secondaryContainer;
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(color: bg, shape: M3EShapes.stadium),
      child: Text(
        label,
        style: emphasized(context).labelMedium.copyWith(color: fg),
      ),
    );
  }
}
