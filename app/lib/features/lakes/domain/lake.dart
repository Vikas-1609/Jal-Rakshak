double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

/// One lake and its catchment totals, from /api/lakes.
class Lake {
  Lake.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      _name = j['name'] as String,
      _district = j['district'] as String? ?? '',
      _story = j['story'] as String? ?? '',
      _nameHi = j['name_hi'] as String?,
      _districtHi = j['district_hi'] as String?,
      _storyHi = j['story_hi'] as String?,
      zoneCount = (j['zones'] as num).toInt(),
      landKm2 = _d(j['land_km2']),
      totalT = _d(j['total_t']),
      meanSoilLoss = _d(j['mean_soil_loss']),
      allFixesSavedPct = _d(j['all_fixes_saved_pct']),
      topZone = j['top_zone'] as String? ?? '';

  final String id;
  final String _name, _district, _story;
  final String? _nameHi, _districtHi, _storyHi;
  final int zoneCount;
  final double landKm2;

  /// Soil lost per year (t) and average rate (t/ha/yr) across the catchment.
  final double totalT, meanSoilLoss;

  /// How much of the soil loss every fix together would prevent (%).
  final double allFixesSavedPct;
  final String topZone;

  // Hindi text when the app is in Hindi and the server provides it.
  String name(String lang) => lang == 'hi' ? _nameHi ?? _name : _name;
  String district(String lang) =>
      lang == 'hi' ? _districtHi ?? _district : _district;
  String story(String lang) => lang == 'hi' ? _storyHi ?? _story : _story;
}
