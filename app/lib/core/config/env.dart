/// Values from app/.env, passed in with `--dart-define-from-file=.env`.
abstract final class Env {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Google Maps JavaScript API key, for the web build only. Android reads
  /// MAPS_API_KEY into its manifest instead (see android/app/build.gradle.kts).
  /// A separate key restricted to your site's URLs is safest; without one,
  /// the Android key is used.
  ///
  /// Browser keys are always visible to the page: protect this one with
  /// HTTP-referrer and API restrictions in Google Cloud Console.
  static const mapsWebKey = String.fromEnvironment(
    'MAPS_WEB_API_KEY',
    defaultValue: String.fromEnvironment('MAPS_API_KEY'),
  );
}
