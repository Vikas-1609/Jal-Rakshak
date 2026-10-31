import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      // Gemini explanations can take a while on first request.
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }
  ref.onDispose(dio.close);
  return dio;
});
