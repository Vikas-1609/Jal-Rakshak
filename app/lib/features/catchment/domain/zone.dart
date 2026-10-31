import 'package:latlong2/latlong.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

/// One catchment zone, from the backend's GeoJSON (03_scenarios export).
class Zone {
  const Zone({
    required this.id,
    required this.type,
    required this.riskClass,
    required this.soilLoss,
    required this.slopeDeg,
    required this.landKm2,
    required this.cropFrac,
    required this.hillFrac,
    required this.treeFrac,
    required this.builtFrac,
    required this.tTotal,
    required this.tCrop,
    required this.tHill,
    required this.tOther,
    required this.rings,
  });

  final String id;
  final ZoneType type;
  final String riskClass;
  final double soilLoss; // t/ha/yr
  final double slopeDeg;
  final double landKm2;
  final double cropFrac, hillFrac, treeFrac, builtFrac; // share of land
  final double tTotal, tCrop, tHill, tOther; // t/yr
  final List<List<LatLng>> rings;

  List<LatLng> get allPoints => [for (final r in rings) ...r];

  factory Zone.fromFeature(Map<String, dynamic> f) {
    final p = f['properties'] as Map<String, dynamic>;
    final g = f['geometry'] as Map<String, dynamic>;
    List<LatLng> ring(List r) => [
      for (final c in r) LatLng(_d((c as List)[1]), _d(c[0])),
    ];
    final coords = g['coordinates'] as List;
    final rings = g['type'] == 'MultiPolygon'
        ? [for (final poly in coords) ring((poly as List).first as List)]
        : [ring(coords.first as List)];

    return Zone(
      id: p['zone_id'] as String,
      type: ZoneType.fromKey(p['zone_type'] as String),
      riskClass: p['risk_class'] as String,
      soilLoss: _d(p['soil_loss']),
      slopeDeg: _d(p['slope_deg']),
      landKm2: _d(p['land_km2']),
      cropFrac: _d(p['crop_frac']),
      hillFrac: _d(p['hill_frac']),
      treeFrac: _d(p['tree_frac']),
      builtFrac: _d(p['built_frac']),
      tTotal: _d(p['t_total']),
      tCrop: _d(p['t_crop']),
      tHill: _d(p['t_hill']),
      tOther: _d(p['t_other']),
      rings: rings,
    );
  }
}

/// Display names live in the l10n files (see zone_labels.dart).
enum ZoneType {
  hill,
  ravine,
  valleyFarm,
  mixed;

  static ZoneType fromKey(String key) => switch (key) {
    'hill' => hill,
    'ravine' => ravine,
    'valley_farm' => valleyFarm,
    _ => mixed,
  };
}
