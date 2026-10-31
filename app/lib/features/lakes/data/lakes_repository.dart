import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/lake.dart';

final lakesRepositoryProvider = Provider(
  (ref) => LakesRepository(ref.watch(dioProvider)),
);

class LakesRepository {
  LakesRepository(this._dio);

  final Dio _dio;

  Future<List<Lake>> fetchAll() => guardApi(() async {
    final res = await _dio.get<List<dynamic>>('/api/lakes');
    return [
      for (final j in res.data!) Lake.fromJson(j as Map<String, dynamic>),
    ];
  });
}
