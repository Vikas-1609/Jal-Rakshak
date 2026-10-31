import 'package:dio/dio.dart';

/// A readable error from the JalRakshak API.
class ApiException implements Exception {
  ApiException(this.message);

  /// Uses the backend's `{"error": "..."}` body when there is one.
  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return ApiException(data['error'] as String);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.connectionError =>
        ApiException('Cannot reach the server. Is the backend running?'),
      DioExceptionType.receiveTimeout => ApiException(
        'The server took too long to answer.',
      ),
      _ => ApiException(e.message ?? 'Request failed'),
    };
  }

  final String message;

  @override
  String toString() => message;
}

/// Runs a Dio request and turns failures into [ApiException].
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
