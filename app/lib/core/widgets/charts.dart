import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../theme/risk_colors.dart';
import '../utils/formatters.dart';

/// Gradient legend for the map's soil-loss colours.
class RiskLegend extends StatelessWidget {
  const RiskLegend({super.key, required this.min, required this.max});

  final double min, max;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.legendTitle, style: style),
        const SizedBox(height: 4),
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              colors: [
                for (var i = 0; i <= 10; i++)
                  riskColor(min + (max - min) * i / 10, min, max),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(min.toStringAsFixed(1), style: style),
            Text(max.toStringAsFixed(1), style: style),
          ],
        ),
      ],
    );
  }
}

/// A single horizontal bar split into labelled shares.
class StackedBar extends StatelessWidget {
  const StackedBar({super.key, required this.title, required this.parts});

  final String title;
  final List<({String label, double frac, Color color})> parts;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final shown = parts.where((p) => p.frac > 0.005).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.labelMedium),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in shown)
                  Expanded(
                    flex: (p.frac * 1000).round(),
                    child: ColoredBox(
                      color: p.color,
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          children: [
            for (final p in shown)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: p.color),
                  const SizedBox(width: 4),
                  Text('${p.label} ${fmtPct(p.frac)}', style: t.labelSmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
