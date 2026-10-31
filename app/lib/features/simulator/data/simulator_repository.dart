import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/fixes.dart';
import '../domain/sim_result.dart';

final simulatorRepositoryProvider = Provider(
  (ref) => SimulatorRepository(ref.watch(dioProvider)),
);

class SimulatorRepository {
  SimulatorRepository(this._dio);

  final Dio _dio;

  Future<SimResult> simulate(String lakeId, Map<String, Fixes> fixes) =>
      guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/lakes/$lakeId/simulate',
          data: {
            'zones': {for (final e in fixes.entries) e.key: e.value.toJson()},
          },
        );
        return SimResult.fromJson(res.data!);
      });
}
