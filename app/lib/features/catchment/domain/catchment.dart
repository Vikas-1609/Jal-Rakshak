import 'zone.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

/// A lake's catchment totals, from /api/lakes/{lake}/summary.
class CatchmentSummary {
  CatchmentSummary.fromJson(Map<String, dynamic> j)
    : lakeId = j['id'] as String,
      _name = j['name'] as String,
      _nameHi = j['name_hi'] as String?,
      totalT = _d(j['total_t']),
      landKm2 = _d(j['land_km2']),
      meanSoilLoss = _d(j['mean_soil_loss']);

  final String lakeId;
  final String _name;
  final String? _nameHi;
  final double totalT, landKm2, meanSoilLoss;

  String lakeName(String lang) => lang == 'hi' ? _nameHi ?? _name : _name;
}

/// One lake's zones and totals: everything the map and panels need.
class Catchment {
  Catchment({required this.zones, required this.summary})
    : byId = {for (final z in zones) z.id: z},
      byTonnes = [...zones]..sort((a, b) => b.tTotal.compareTo(a.tTotal)),
      minLoss = zones.map((z) => z.soilLoss).reduce((a, b) => a < b ? a : b),
      maxLoss = zones.map((z) => z.soilLoss).reduce((a, b) => a > b ? a : b);

  final List<Zone> zones;
  final CatchmentSummary summary;
  final Map<String, Zone> byId;

  String get lakeId => summary.lakeId;
  String lakeName(String lang) => summary.lakeName(lang);

  /// Zones sorted by tonnes lost per year, largest first.
  final List<Zone> byTonnes;

  /// Baseline soil-loss range (t/ha/yr), used as the fixed colour scale.
  final double minLoss, maxLoss;

  double shareOf(Zone z) => z.tTotal / summary.totalT;
}
