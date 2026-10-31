import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/settings_providers.dart';

/// Same wiring as M3EMaterialApp (Material themes from the expressive tokens,
/// M3ETheme around every route, transparent system bars), but on
/// MaterialApp.router so go_router drives navigation.
class JalRakshakApp extends ConsumerWidget {
  const JalRakshakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final lang = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: lightThemeData.toThemeData(),
      darkTheme: darkThemeData.toThemeData(),
      themeMode: themeMode,
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // material_ui's own Material + Cupertino + Widgets localizations.
        ...GlobalMaterialLocalizations.delegates,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final icons = dark ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            statusBarIconBrightness: icons,
            systemNavigationBarIconBrightness: icons,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          ),
          child: M3ETheme(
            data: dark ? darkThemeData : lightThemeData,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
