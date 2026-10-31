import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/catchment.dart';
import '../domain/zone.dart';

final catchmentRepositoryProvider = Provider(
  (ref) => CatchmentRepository(ref.watch(dioProvider)),
);

class CatchmentRepository {
  CatchmentRepository(this._dio);

  final Dio _dio;

  Future<Catchment> fetch(String lakeId) => guardApi(() async {
    final (zones, summary) = await (
      _dio.get<Map<String, dynamic>>('/api/lakes/$lakeId/zones'),
      _dio.get<Map<String, dynamic>>('/api/lakes/$lakeId/summary'),
    ).wait;
    return Catchment(
      zones: [
        for (final f in zones.data!['features'] as List)
          Zone.fromFeature(f as Map<String, dynamic>),
      ],
      summary: CatchmentSummary.fromJson(summary.data!),
    );
  });
}
