import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../insights/data/insights_repository.dart';
import '../application/settings_providers.dart';

/// Appearance, language, haptics and saved data.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _themes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
  static const _languages = <String?>[null, 'en', 'hi'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final insights = ref.read(insightsRepositoryProvider);
    final saved = insights.savedCount();

    final sections = <Widget>[
      SectionCard(
        title: l.appearance,
        icon: Icons.palette_outlined,
        child: M3EButtonGroup(
          type: M3EButtonGroupType.connected,
          style: M3EButtonStyle.tonal,
          selectionRequired: true,
          selectedIndex: _themes.indexOf(settings.themeMode),
          onSelectedIndexChanged: (i) {
            if (i == null) return;
            Haptics.selection();
            controller.setThemeMode(_themes[i]);
          },
          actions: [
            M3EButtonGroupAction(
              icon: const Icon(Icons.brightness_auto),
              label: Text(l.themeSystem),
            ),
            M3EButtonGroupAction(
              icon: const Icon(Icons.light_mode),
              label: Text(l.themeLight),
            ),
            M3EButtonGroupAction(
              icon: const Icon(Icons.dark_mode),
              label: Text(l.themeDark),
            ),
          ],
        ),
      ),
      SectionCard(
        title: l.language,
        icon: Icons.translate,
        child: M3EButtonGroup(
          type: M3EButtonGroupType.connected,
          style: M3EButtonStyle.tonal,
          selectionRequired: true,
          selectedIndex: _languages.indexOf(settings.languageCode),
          onSelectedIndexChanged: (i) {
            if (i == null) return;
            Haptics.selection();
            controller.setLanguage(_languages[i]);
          },
          actions: [
            M3EButtonGroupAction(label: Text(l.languageSystem)),
            const M3EButtonGroupAction(label: Text('English')),
            const M3EButtonGroupAction(label: Text('हिंदी')),
          ],
        ),
      ),
      SectionCard(
        child: M3EListItem(
          headline: l.hapticsTitle,
          supportingText: l.hapticsSub,
          leading: const Icon(Icons.vibration),
          trailing: M3ESwitch(
            value: settings.haptics,
            selectedIcon: const Icon(Icons.check),
            onChanged: (v) {
              controller.setHaptics(v);
              Haptics.selection();
            },
          ),
        ),
      ),
      SectionCard(
        title: l.savedExplanations,
        icon: Icons.offline_pin_outlined,
        trailing: M3EButton.text(
          onPressed: saved == 0
              ? null
              : () async {
                  Haptics.selection();
                  await insights.clearSaved();
                  if (!context.mounted) return;
                  setState(() {});
                  M3ESnackbar.show(context, message: context.l10n.cleared);
                },
          child: Text(l.clearSaved),
        ),
        child: Text(l.savedExplanationsSub(saved)),
      ),
      SectionCard(
        title: l.about,
        icon: Icons.water_drop_outlined,
        child: Text(l.aboutBody),
      ),
    ];

    return Scaffold(
      appBar: M3EAppBar.top(
        variant: M3EAppBarVariant.mediumFlexible,
        titleText: l.settings,
        leading: M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: const Icon(Icons.arrow_back),
          tooltip: l.back,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => FadeSlideIn(index: i, child: sections[i]),
      ),
    );
  }
}
