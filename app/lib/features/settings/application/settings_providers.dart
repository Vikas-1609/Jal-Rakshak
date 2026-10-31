import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/utils/haptics.dart';
import '../domain/app_settings.dart';

const _key = 'settings:v1';

/// Languages the app ships in.
const supportedLanguages = ['en', 'hi'];

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final saved = ref.read(localStoreProvider).readJson(_key);
    final s = saved == null ? const AppSettings() : AppSettings.fromJson(saved);
    Haptics.enabled = s.haptics;
    return s;
  }

  void _save(AppSettings s) {
    state = s;
    Haptics.enabled = s.haptics;
    ref.read(localStoreProvider).writeJson(_key, s.toJson());
  }

  void setThemeMode(ThemeMode m) => _save(state.copyWith(themeMode: m));

  void setLanguage(String? code) =>
      _save(state.copyWith(languageCode: () => code));

  void setHaptics(bool on) => _save(state.copyWith(haptics: on));

  void setZoneOpacity(double v) => _save(state.copyWith(zoneOpacity: v));

  void markPlanIntroSeen() => _save(state.copyWith(planIntroSeen: true));
}

/// The language actually in use: the chosen one, else the phone's if
/// supported, else English. Gemini explanations follow this too.
final appLanguageProvider = Provider<String>((ref) {
  final chosen = ref.watch(settingsProvider.select((s) => s.languageCode));
  if (chosen != null) return chosen;
  final device = PlatformDispatcher.instance.locale.languageCode;
  return supportedLanguages.contains(device) ? device : 'en';
});
