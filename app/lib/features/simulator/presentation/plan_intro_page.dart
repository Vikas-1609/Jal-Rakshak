import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../settings/application/settings_providers.dart';

/// Four-page guide to what a restoration plan is and how to read it.
/// Opens on the first visit to the Plan tab and from its info button.
class PlanIntroPage extends ConsumerStatefulWidget {
  const PlanIntroPage({super.key});

  @override
  ConsumerState<PlanIntroPage> createState() => _PlanIntroPageState();
}

class _PlanIntroPageState extends ConsumerState<PlanIntroPage> {
  final _pages = PageController();
  int _index = 0;

  static const _shapes = [
    M3EShapeKind.sunny,
    M3EShapeKind.clamShell,
    M3EShapeKind.gem,
    M3EShapeKind.pentagon,
  ];
  static const _icons = [
    Icons.water_drop,
    Icons.construction,
    Icons.satellite_alt,
    Icons.groups,
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    Haptics.tap();
    ref.read(settingsProvider.notifier).markPlanIntroSeen();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.plan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = emphasized(context);
    final titles = [l.introTitle1, l.introTitle2, l.introTitle3, l.introTitle4];
    final bodies = [l.introBody1, l.introBody2, l.introBody3, l.introBody4];
    final last = _index == titles.length - 1;
    final colors = [
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.primary, scheme.onPrimary),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: AnimatedOpacity(
                      opacity: last ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: M3EButton.text(
                        onPressed: last ? null : _finish,
                        child: Text(l.introSkip),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: titles.length,
                    onPageChanged: (i) {
                      Haptics.selection();
                      setState(() => _index = i);
                    },
                    itemBuilder: (context, i) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(i),
                              tween: Tween(begin: 0.6, end: 1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              builder: (_, s, child) =>
                                  Transform.scale(scale: s, child: child),
                              child: M3EShapeContainer(
                                kind: _shapes[i],
                                width: 180,
                                height: 180,
                                color: colors[i].$1,
                                child: Icon(
                                  _icons[i],
                                  size: 72,
                                  color: colors[i].$2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(titles[i], style: type.headlineMedium),
                          const SizedBox(height: 16),
                          Text(
                            bodies[i],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    children: [
                      for (var i = 0; i < titles.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _index ? 28 : 10,
                          height: 10,
                          decoration: ShapeDecoration(
                            color: i == _index
                                ? scheme.primary
                                : scheme.outlineVariant,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      const Spacer(),
                      M3EButton.filled(
                        size: M3EButtonSize.md,
                        onPressed: last
                            ? _finish
                            : () {
                                Haptics.selection();
                                _pages.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                        icon: Icon(last ? Icons.check : Icons.arrow_forward),
                        label: Text(last ? l.introStart : l.introNext),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
