import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Material window size classes, by available width.
abstract final class Breakpoints {
  /// From here up: navigation rail instead of the bottom bar.
  static const medium = 600.0;

  /// From here up: the rail shows labels beside its icons.
  static const expanded = 1200.0;

  /// Map tab: side panel instead of the bottom sheet.
  static const mapPanel = 840.0;

  /// Lists switch to two columns.
  static const twoColumns = 900.0;
}

/// Side padding that keeps content at most [maxWidth] wide and centred,
/// with at least [min] on each side. Padding (rather than a centred box)
/// keeps the scroll area, and so the mouse wheel and scrollbar, full width.
double gutter(double available, {double maxWidth = 760, double min = 16}) =>
    math.max(min, (available - maxWidth) / 2);

/// Lays [children] out in rows of [columns], each row as tall as its
/// tallest child.
class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 12,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) SizedBox(height: spacing),
            c,
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var r = 0; r < children.length; r += columns) ...[
          if (r > 0) SizedBox(height: spacing),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: spacing),
                  Expanded(
                    child: r + c < children.length
                        ? children[r + c]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
