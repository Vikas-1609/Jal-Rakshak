import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Adds the Maps JavaScript API script to the page and waits for it.
/// False when there is no key or the script can't load.
Future<bool> loadGoogleMaps(String key, ValueNotifier<bool> authFailed) {
  if (key.isEmpty) return Future.value(false);
  // Google calls this global when it rejects the key.
  globalContext.setProperty(
    'gm_authFailure'.toJS,
    (() => authFailed.value = true).toJS,
  );
  final loaded = Completer<bool>();
  final script = web.HTMLScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js'
        '?key=${Uri.encodeQueryComponent(key)}&v=weekly'
    ..async = true;
  script.onload = ((web.Event _) => loaded.complete(true)).toJS;
  script.onerror = ((web.Event _) => loaded.complete(false)).toJS;
  web.document.head!.append(script);
  return loaded.future;
}
