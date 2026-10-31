/// Values from app/.env, passed in with `--dart-define-from-file=.env`.
abstract final class Env {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );
}
