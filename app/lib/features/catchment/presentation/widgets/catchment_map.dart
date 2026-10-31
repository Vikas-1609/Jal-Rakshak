import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/maps/maps_loader.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/risk_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/common.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../simulator/application/simulator_providers.dart';
import '../../../simulator/domain/sim_result.dart';
import '../../application/catchment_providers.dart';
import '../../domain/catchment.dart';
import '../../domain/zone.dart';

/// Google satellite map (with place names) with zones coloured by current
/// soil loss (fixes included), a floating expressive toolbar, and a
/// zone-opacity control.
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
  gm.GoogleMapController? _controller;
  Size _size = Size.zero;
  bool _fitted = false;
  bool _showOpacity = false;

  Iterable<LatLng> get _lakePoints => [
    for (final z in widget.catchment.zones) ...z.allPoints,
  ];

  @override
  void didUpdateWidget(CatchmentMap old) {
    super.didUpdateWidget(old);
    // One map for every lake (each new map is a billed map load): move the
    // camera instead of rebuilding.
    if (old.catchment.lakeId != widget.catchment.lakeId) _fit(_lakePoints);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Bounds that, fitted to the whole map, put [points] in the part not
  /// covered by overlays ([CatchmentMap.padding]). GoogleMap.padding would
  /// do this on Android, but the web plugin ignores it.
  gm.LatLngBounds _boundsFor(Iterable<LatLng> points) {
    var west = 180.0, east = -180.0, south = 90.0, north = -90.0;
    for (final p in points) {
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
    }
    final pad = widget.padding + const EdgeInsets.all(16);
    final visibleW = _size.width - pad.horizontal;
    final visibleH = _size.height - pad.vertical;
    if (visibleW <= 0 || visibleH <= 0) {
      return gm.LatLngBounds(
        southwest: gm.LatLng(south, west),
        northeast: gm.LatLng(north, east),
      );
    }
    // Stretch the bounds by the hidden share of each side, in Web Mercator
    // so the vertical stretch matches what the map draws.
    double toY(double lat) =>
        math.log(math.tan(math.pi / 4 + lat * math.pi / 360));
    double toLat(double y) =>
        (2 * math.atan(math.exp(y)) - math.pi / 2) * 180 / math.pi;
    final dx = east - west;
    final ys = toY(south), yn = toY(north), dy = yn - ys;
    return gm.LatLngBounds(
      southwest: gm.LatLng(
        toLat(ys - dy * pad.bottom / visibleH),
        west - dx * pad.left / visibleW,
      ),
      northeast: gm.LatLng(
        toLat(yn + dy * pad.top / visibleH),
        east + dx * pad.right / visibleW,
      ),
    );
  }

  void _fit(Iterable<LatLng> points, {bool animate = true}) {
    final c = _controller;
    if (c == null || points.isEmpty) return;
    final update = gm.CameraUpdate.newLatLngBounds(_boundsFor(points), 0);
    animate ? c.animateCamera(update) : c.moveCamera(update);
  }

  void _firstFit() {
    if (_fitted || !mounted) return;
    _fitted = true;
    _fit(_lakePoints, animate: false);
  }

  void _zoomBy(double delta) {
    Haptics.selection();
    _controller?.animateCamera(gm.CameraUpdate.zoomBy(delta));
  }

  Set<gm.Polygon> _polygons(String? selectedId, double opacity) {
    final c = widget.catchment;
    final sim = ref.watch(simResultProvider(c.lakeId)).value;
    return {
      for (final z in c.zones)
        for (final (i, ring) in z.rings.indexed)
          _zonePolygon(z, i, ring, z.id == selectedId, opacity, sim),
    };
  }

  gm.Polygon _zonePolygon(
    Zone z,
    int ring,
    List<LatLng> points,
    bool selected,
    double opacity,
    SimResult? sim,
  ) {
    final c = widget.catchment;
    final fill = riskColor(soilLossNow(z, sim), c.minLoss, c.maxLoss);
    return gm.Polygon(
      polygonId: gm.PolygonId('${z.id}#$ring'),
      points: [for (final p in points) gm.LatLng(p.latitude, p.longitude)],
      fillColor: fill.withValues(
        alpha: selected ? (opacity + 0.2).clamp(0.0, 1.0) : opacity,
      ),
      strokeColor: selected ? Colors.white : Colors.black54,
      strokeWidth: selected ? 3 : 1,
      // Selected zone on top, so its outline isn't hidden by neighbours.
      zIndex: selected ? 1 : 0,
      consumeTapEvents: true,
      onTap: () {
        Haptics.selection();
        ref.read(selectedZoneIdProvider.notifier).select(z.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Zone?>(selectedZoneProvider, (_, zone) {
      if (zone != null) _fit(zone.allPoints);
    });

    final l = context.l10n;
    final selectedId = ref.watch(selectedZoneIdProvider);
    final opacity = ref.watch(settingsProvider.select((s) => s.zoneOpacity));
    final ready = ref.watch(googleMapsReadyProvider);

    final map = switch (ready) {
      AsyncData(value: true) => gm.GoogleMap(
        initialCameraPosition: gm.CameraPosition(
          target: _center(widget.catchment),
          zoom: 9,
        ),
        onMapCreated: (c) {
          _controller = c;
          // Fallback in case the first idle event comes before the map
          // is laid out (or never comes).
          Future.delayed(const Duration(milliseconds: 800), _firstFit);
        },
        // First fit once the map has settled: on the web, a fit right after
        // creation is ignored because the map isn't laid out yet.
        onCameraIdle: _firstFit,
        mapType: gm.MapType.hybrid,
        minMaxZoomPreference: const gm.MinMaxZoomPreference(7, 17),
        polygons: _polygons(selectedId, opacity),
        // The app's own toolbar replaces Google's controls.
        zoomControlsEnabled: false,
        webCameraControlEnabled: false,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        // Full-screen map: scroll and pinch zoom without holding Ctrl.
        webGestureHandling: gm.WebGestureHandling.greedy,
        // Taps on a zone are consumed by its polygon; this is empty map.
        onTap: (_) {
          setState(() => _showOpacity = false);
          ref.read(selectedZoneIdProvider.notifier).select(null);
        },
      ),
      AsyncData() || AsyncError() => _MapMessage(l.mapNoKey),
      _ => const ColoredBox(color: Colors.black),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Stack(
          children: [
            Positioned.fill(child: map),
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: mapsAuthFailed,
                builder: (context, failed, _) => failed
                    ? _MapMessage(l.mapKeyRejected)
                    : const SizedBox.shrink(),
              ),
            ),
            // The floating toolbar aligns itself by filling the map; shrink
            // it to its own size so the interceptor covers only the buttons.
            Align(
              alignment: const Alignment(1, -0.15),
              child: PointerInterceptor(
                child: UnconstrainedBox(child: _toolbar(l)),
              ),
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
                      ? PointerInterceptor(child: _OpacityCard(value: opacity))
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _toolbar(AppLocalizations l) {
    return M3EToolbar(
      axis: Axis.vertical,
      colorStyle: M3EToolbarColorStyle.vibrant,
      actions: <M3EToolbarItem>[
        M3EToolbarAction(
          icon: Icons.center_focus_strong,
          tooltip: l.showWholeCatchment,
          onPressed: () {
            Haptics.selection();
            _fit(_lakePoints);
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
    );
  }

  static gm.LatLng _center(Catchment c) {
    final pts = [for (final z in c.zones) ...z.allPoints];
    final lat = pts.fold<double>(0, (s, p) => s + p.latitude) / pts.length;
    final lng = pts.fold<double>(0, (s, p) => s + p.longitude) / pts.length;
    return gm.LatLng(lat, lng);
  }
}

/// Shown instead of the map when Google Maps can't load.
class _MapMessage extends StatelessWidget {
  const _MapMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ErrorState(message: message),
          ),
        ),
      ),
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
