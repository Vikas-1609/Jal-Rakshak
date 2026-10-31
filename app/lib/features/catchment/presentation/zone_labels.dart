import '../../../core/l10n/l10n.dart';
import '../domain/zone.dart';

/// Localized names for zone types and the model's risk classes.
extension ZoneLabels on AppLocalizations {
  String zoneType(ZoneType t) => switch (t) {
    ZoneType.hill => zoneHill,
    ZoneType.ravine => zoneRavine,
    ZoneType.valleyFarm => zoneValleyFarm,
    ZoneType.mixed => zoneMixed,
  };

  /// risk_class from the export: Slight, Moderate, High, Very high, Severe.
  String riskClass(String cls) => switch (cls) {
    'Slight' => riskSlight,
    'Moderate' => riskModerate,
    'High' => riskHigh,
    'Very high' => riskVeryHigh,
    'Severe' => riskSevere,
    _ => cls,
  };
}
