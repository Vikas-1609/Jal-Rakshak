import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../config/env.dart';
import 'maps_loader_stub.dart'
    if (dart.library.js_interop) 'maps_loader_web.dart'
    as platform;

/// True once Google Maps can be shown. On the web this loads the Maps
/// JavaScript API with the key from .env (it isn't in index.html, so the
/// key never sits in the source). Android loads the SDK itself.
final googleMapsReadyProvider = FutureProvider<bool>(
  (ref) => platform.loadGoogleMaps(Env.mapsWebKey, mapsAuthFailed),
);

/// Set when Google rejects the key: wrong key, a referrer restriction
/// that doesn't include this site, or the Maps JavaScript API not enabled.
final mapsAuthFailed = ValueNotifier(false);
