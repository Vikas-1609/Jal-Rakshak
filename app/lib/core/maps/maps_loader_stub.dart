import 'package:flutter/foundation.dart';

/// Android: the Maps SDK is set up from the manifest, nothing to load.
Future<bool> loadGoogleMaps(String key, ValueNotifier<bool> authFailed) =>
    Future.value(true);
