import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/local_store.dart';
import 'features/lakes/application/lakes_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loaded before the first frame so settings (theme, language) apply at once.
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  // Ask for the lakes now, while the first frame is being drawn, rather
  // than once the Lakes page asks for them.
  container.read(lakesProvider);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const JalRakshakApp(),
    ),
  );
}
