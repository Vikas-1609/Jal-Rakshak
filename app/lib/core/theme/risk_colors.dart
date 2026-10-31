import 'package:material_ui/material_ui.dart';

/// Low → high erosion colours (green, yellow, orange, red).
const _riskStops = [
  Color(0xFF1A9850),
  Color(0xFFFEE08B),
  Color(0xFFF46D43),
  Color(0xFFA50026),
];

/// Colour for a soil-loss value on a fixed scale [min, max], so zones
/// visibly turn greener as fixes are applied.
Color riskColor(double value, double min, double max) {
  final t =
      ((value - min) / (max - min)).clamp(0.0, 1.0) * (_riskStops.length - 1);
  final i = t.floor().clamp(0, _riskStops.length - 2);
  return Color.lerp(_riskStops[i], _riskStops[i + 1], t - i)!;
}

const landColors = (
  crop: Color(0xFFF1C40F),
  hill: Color(0xFFA0522D),
  forest: Color(0xFF2E7D32),
  built: Colors.grey,
);
