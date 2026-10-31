double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Soil loss before and after fixes, from /api/simulate.
class SimResult {
  SimResult.fromJson(Map<String, dynamic> j)
    : baselineT = _d(j['baseline_t']),
      scenarioT = _d(j['scenario_t']),
      savedT = _d(j['saved_t']),
      savedPct = _d(j['saved_pct']),
      zones = {
        for (final z in j['zones'] as List)
          (z as Map<String, dynamic>)['zone_id'] as String: ZoneResult.fromJson(
            z,
          ),
      };

  final double baselineT, scenarioT, savedT, savedPct;
  final Map<String, ZoneResult> zones;
}

class ZoneResult {
  ZoneResult.fromJson(Map<String, dynamic> j)
    : savedT = _d(j['saved_t']),
      savedPct = _d(j['saved_pct']),
      soilLossNew = _d(j['soil_loss_new']);

  final double savedT, savedPct;

  /// t/ha/yr with the fixes applied.
  final double soilLossNew;
}
