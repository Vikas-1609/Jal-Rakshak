import 'dart:ui' show lerpDouble;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/measure_size.dart';
import '../../lakes/presentation/widgets/lake_switcher.dart';
import '../../settings/application/settings_providers.dart';
import '../application/catchment_providers.dart';
import '../domain/catchment.dart';
import '../domain/zone.dart';
import 'widgets/catchment_map.dart';
import 'widgets/lake_overview_panel.dart';
import 'widgets/map_status_card.dart';
import 'widgets/zone_detail_content.dart';
import 'widgets/zone_header.dart';
import 'widgets/zone_preview_panel.dart';

/// Map tab: full-screen catchment map with a bottom sheet that sizes to its
/// content, and expands into a full-screen zone view.
class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView(
        value: ref.watch(currentCatchmentProvider),
        onRetry: () => retryCurrentCatchment(ref),
        data: (catchment) => _MapBody(catchment: catchment),
      ),
    );
  }
}

class _MapBody extends ConsumerStatefulWidget {
  const _MapBody({required this.catchment});

  final Catchment catchment;

  @override
  ConsumerState<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends ConsumerState<_MapBody> {
  static const _minSize = 0.12, _peekSize = 0.34, _maxPeek = 0.9;

  /// Space above the content in the sheet: drag handle and top padding.
  static const _chrome = 40.0;

  final _sheet = DraggableScrollableController();
  double? _contentHeight;
  bool _detail = false;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSheetMoved);
  }

  @override
  void dispose() {
    _sheet.removeListener(_onSheetMoved);
    _sheet.dispose();
    super.dispose();
  }

  /// True while animating open, so the drag-down check below doesn't
  /// mistake the sheet's starting height for the user closing it.
  bool _expanding = false;

  // Dragging the full-screen view well down returns to the preview.
  void _onSheetMoved() {
    if (_detail && !_expanding && _sheet.isAttached && _sheet.size < 0.6) {
      setState(() => _detail = false);
    }
  }

  void _openDetail() {
    setState(() {
      _detail = true;
      _expanding = true;
    });
    // Wait a frame so the sheet's max size is 1.0 before animating to it.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_sheet.isAttached) {
        await _sheet.animateTo(
          1,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubicEmphasized,
        );
      }
      _expanding = false;
    });
  }

  Future<void> _closeDetail() async {
    Haptics.selection();
    if (_sheet.isAttached) {
      await _sheet.animateTo(
        _peekSize,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(() => _detail = false);
  }

  @override
  Widget build(BuildContext context) {
    final zone = ref.watch(selectedZoneProvider);
    // Leaving a zone also leaves its full-screen view.
    if (zone == null && _detail) _detail = false;

    return PopScope(
      canPop: !_detail,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeDetail();
      },
      child: LayoutBuilder(
        builder: (context, c) {
          final height = c.maxHeight;
          // The sheet can't be pulled beyond its content.
          final fit = _contentHeight == null
              ? _maxPeek
              : ((_contentHeight! + _chrome) / height).clamp(
                  _minSize + 0.02,
                  _maxPeek,
                );
          final maxSize = _detail ? 1.0 : fit;
          final initial = _peekSize.clamp(_minSize, maxSize);

          return Stack(
            children: [
              CatchmentMap(
                // A new map per lake, so it refits the camera to that catchment.
                key: ValueKey(widget.catchment.lakeId),
                catchment: widget.catchment,
                padding: EdgeInsets.only(top: 170, bottom: height * _peekSize),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LakeSwitcher(),
                      const SizedBox(height: 8),
                      MapStatusCard(catchment: widget.catchment),
                    ],
                  ),
                ),
              ),
              DraggableScrollableSheet(
                controller: _sheet,
                minChildSize: _minSize,
                initialChildSize: initial,
                maxChildSize: maxSize,
                // No snapping: the sheet rebuilds as its content is measured,
                // and each rebuild would re-trigger a snap that fights the
                // open animation.
                builder: (context, scroll) => ListenableBuilder(
                  listenable: _sheet,
                  builder: (context, _) {
                    // 0 while a normal sheet, 1 when it fills the screen.
                    final t = _sheet.isAttached
                        ? ((_sheet.size - 0.85) / 0.15).clamp(0.0, 1.0)
                        : 0.0;
                    return _SheetSurface(
                      t: t,
                      child: ListView(
                        controller: scroll,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          10 + MediaQuery.paddingOf(context).top * t,
                          16,
                          24,
                        ),
                        children: [
                          Opacity(opacity: 1 - t, child: const _DragHandle()),
                          MeasureSize(
                            onChange: (s) {
                              // Full screen ignores content height, and
                              // rebuilding the sheet would cancel the open
                              // animation (it replaces the sheet's extent).
                              if (_detail) return;
                              if (s.height != _contentHeight) {
                                setState(() => _contentHeight = s.height);
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero,
                                  ).animate(a),
                                  child: child,
                                ),
                              ),
                              child: _content(zone),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(Zone? zone) {
    if (zone == null) {
      return LakeOverviewPanel(
        key: const ValueKey('overview'),
        catchment: widget.catchment,
      );
    }
    if (_detail) {
      return _DetailView(
        key: ValueKey('detail-${zone.id}'),
        catchment: widget.catchment,
        zone: zone,
        onClose: _closeDetail,
      );
    }
    return ZonePreviewPanel(
      key: ValueKey('preview-${zone.id}'),
      catchment: widget.catchment,
      zone: zone,
      onOpenDetail: _openDetail,
    );
  }
}

/// Sheet background whose top corners flatten as it fills the screen.
class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = lerpDouble(M3EShapes.extraLargeIncreased, 0, t)!;
    final surface = Color.lerp(scheme.surfaceContainerLow, scheme.surface, t)!;
    return Material(
      elevation: lerpDouble(6, 0, t)!,
      color: surface,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          child,
          // Once full screen, keep scrolled content out from under the
          // status bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top * t,
            child: ColoredBox(color: surface),
          ),
        ],
      ),
    );
  }
}

/// Full-screen zone view inside the sheet: title bar, then all details.
class _DetailView extends ConsumerWidget {
  const _DetailView({
    super.key,
    required this.catchment,
    required this.zone,
    required this.onClose,
  });

  final Catchment catchment;
  final Zone zone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = ref.watch(appLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            M3EIconButton(
              variant: M3EIconButtonVariant.tonal,
              icon: const Icon(Icons.expand_more),
              tooltip: l.back,
              onPressed: onClose,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.zoneTitle(zone.id),
                    style: emphasized(context).headlineSmall,
                  ),
                  Text(
                    catchment.lakeName(lang),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ZoneHeader(catchment: catchment, zone: zone),
        const SizedBox(height: 16),
        ZoneDetailContent(catchment: catchment, zone: zone),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
