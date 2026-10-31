import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/risk_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../simulator/application/simulator_providers.dart';
import '../../application/catchment_providers.dart';
import '../../domain/catchment.dart';
import '../../domain/zone.dart';

/// Esri satellite imagery plus a place-names overlay: free, no API key.
const _imageryUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
const _labelsUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';
const _userAgent = 'dev.jalrakshak.jalrakshak_app';

/// Satellite map with zones coloured by current soil loss (fixes included),
/// a floating expressive toolbar, and a zone-opacity control.
class CatchmentMap extends ConsumerStatefulWidget {
  const CatchmentMap({
    super.key,
    required this.catchment,
    this.padding = EdgeInsets.zero,
  });

  final Catchment catchment;

  /// Space hidden by overlays, so the camera fits zones in the visible area.
  final EdgeInsets padding;

  @override
  ConsumerState<CatchmentMap> createState() => _CatchmentMapState();
}

class _CatchmentMapState extends ConsumerState<CatchmentMap> {
  final _controller = MapController();
  final _hits = LayerHitNotifier<String>(null);
  bool _showOpacity = false;

  EdgeInsets get _fitPadding => widget.padding + const EdgeInsets.all(16);

  CameraFit get _lakeFit => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints([
      for (final z in widget.catchment.zones) ...z.allPoints,
    ]),
    padding: _fitPadding,
  );

  @override
  void dispose() {
    _controller.dispose();
    _hits.dispose();
    super.dispose();
  }

  void _selectTapped() {
    final hit = _hits.value?.hitValues;
    if (hit != null && hit.isNotEmpty) {
      Haptics.selection();
      ref.read(selectedZoneIdProvider.notifier).select(hit.first);
    }
  }

  void _zoomBy(double delta) {
    Haptics.selection();
    final camera = _controller.camera;
    _controller.move(camera.center, camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Zone?>(selectedZoneProvider, (_, zone) {
      if (zone != null) {
        _controller.fitCamera(
          CameraFit.coordinates(
            coordinates: zone.allPoints,
            padding: _fitPadding,
            maxZoom: 12,
          ),
        );
      }
    });

    final l = context.l10n;
    final c = widget.catchment;
    final selectedId = ref.watch(selectedZoneIdProvider);
    final sim = ref.watch(simResultProvider(c.lakeId)).value;
    final opacity = ref.watch(settingsProvider.select((s) => s.zoneOpacity));

    // Selected zone last, so its outline draws on top.
    final ordered = [...c.zones]
      ..sort(
        (a, b) => (a.id == selectedId ? 1 : 0) - (b.id == selectedId ? 1 : 0),
      );

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCameraFit: _lakeFit,
        minZoom: 7,
        maxZoom: 17,
        // Taps on a zone are caught by the polygon layer; this is empty map.
        onTap: (_, _) {
          setState(() => _showOpacity = false);
          ref.read(selectedZoneIdProvider.notifier).select(null);
        },
      ),
      children: [
        TileLayer(urlTemplate: _imageryUrl, userAgentPackageName: _userAgent),
        GestureDetector(
          onTap: _selectTapped,
          child: PolygonLayer<String>(
            hitNotifier: _hits,
            polygons: [
              for (final z in ordered)
                for (final ring in z.rings)
                  Polygon<String>(
                    points: ring,
                    hitValue: z.id,
                    color: riskColor(soilLossNow(z, sim), c.minLoss, c.maxLoss)
                        .withValues(
                          alpha: z.id == selectedId
                              ? (opacity + 0.2).clamp(0.0, 1.0)
                              : opacity,
                        ),
                    borderColor: z.id == selectedId
                        ? Colors.white
                        : Colors.black54,
                    borderStrokeWidth: z.id == selectedId ? 3 : 1,
                  ),
            ],
          ),
        ),
        // Labels above the zones for readability; taps pass through to them.
        IgnorePointer(
          child: TileLayer(
            urlTemplate: _labelsUrl,
            userAgentPackageName: _userAgent,
          ),
        ),
        M3EToolbar(
          axis: Axis.vertical,
          alignment: const Alignment(1, -0.15),
          colorStyle: M3EToolbarColorStyle.vibrant,
          actions: <M3EToolbarItem>[
            M3EToolbarAction(
              icon: Icons.center_focus_strong,
              tooltip: l.showWholeCatchment,
              onPressed: () {
                Haptics.selection();
                _controller.fitCamera(_lakeFit);
              },
            ),
            M3EToolbarAction(
              icon: Icons.add,
              tooltip: l.zoomIn,
              onPressed: () => _zoomBy(1),
            ),
            M3EToolbarAction(
              icon: Icons.remove,
              tooltip: l.zoomOut,
              onPressed: () => _zoomBy(-1),
            ),
            M3EToolbarAction(
              icon: Icons.layers,
              tooltip: l.layerOpacity,
              active: _showOpacity,
              onPressed: () {
                Haptics.selection();
                setState(() => _showOpacity = !_showOpacity);
              },
            ),
          ],
        ),
        // Opacity card slides in next to the toolbar.
        Align(
          alignment: const Alignment(1, -0.15),
          child: Padding(
            padding: const EdgeInsets.only(right: 96),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                  ),
                  alignment: Alignment.centerRight,
                  child: child,
                ),
              ),
              child: _showOpacity
                  ? _OpacityCard(value: opacity)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpacityCard extends ConsumerWidget {
  const _OpacityCard({required this.value});

  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pct = '${(value * 100).round()}%';
    return SizedBox(
      width: 220,
      child: M3ECard(
        variant: M3ECardVariant.elevated,
        color: scheme.surfaceContainerHigh,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        borderRadius: M3EShapes.radiusLarge,
        // The slider's value bubble floats above the thumb, outside the
        // slider's box; clipping the card would cut it off.
        clipBehavior: Clip.none,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.layerOpacity,
                    style: emphasized(context).labelLarge,
                  ),
                ),
                Text(
                  pct,
                  style: emphasized(context).labelLarge
                      .copyWith(color: scheme.primary),
                ),
              ],
            ),
            M3ESlider(
              value: value,
              min: 0.1,
              max: 0.9,
              divisions: 8,
              size: M3ESliderSize.s,
              label: pct,
              // The slider's own haptic is a light impact per step; a soft
              // selection tick suits a fine-grained control better.
              haptic: M3EHapticFeedback.none,
              onChanged: (v) {
                if (v == value) return;
                Haptics.selection();
                ref.read(settingsProvider.notifier).setZoneOpacity(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
