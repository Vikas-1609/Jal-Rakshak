import 'package:material_ui/material_ui.dart';

/// User preferences, saved on the phone.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.languageCode,
    this.haptics = true,
    this.zoneOpacity = 0.5,
    this.planIntroSeen = false,
  });

  final ThemeMode themeMode;

  /// 'en' or 'hi'; null follows the phone's language.
  final String? languageCode;
  final bool haptics;

  /// Fill opacity of the zone polygons on the map (0.1–0.9).
  final double zoneOpacity;
  final bool planIntroSeen;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? Function()? languageCode,
    bool? haptics,
    double? zoneOpacity,
    bool? planIntroSeen,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    languageCode: languageCode != null ? languageCode() : this.languageCode,
    haptics: haptics ?? this.haptics,
    zoneOpacity: zoneOpacity ?? this.zoneOpacity,
    planIntroSeen: planIntroSeen ?? this.planIntroSeen,
  );

  Map<String, dynamic> toJson() => {
    'theme': themeMode.name,
    'lang': languageCode,
    'haptics': haptics,
    'opacity': zoneOpacity,
    'planIntroSeen': planIntroSeen,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == j['theme'],
      orElse: () => ThemeMode.system,
    ),
    languageCode: j['lang'] as String?,
    haptics: j['haptics'] as bool? ?? true,
    zoneOpacity: (j['opacity'] as num?)?.toDouble() ?? 0.5,
    planIntroSeen: j['planIntroSeen'] as bool? ?? false,
  );
}
