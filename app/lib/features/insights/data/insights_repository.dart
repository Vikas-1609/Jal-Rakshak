import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/local_store.dart';
import '../domain/explanation.dart';

/// Prefix of saved explanations in the local store.
const explanationCachePrefix = 'explain:v1:';

final insightsRepositoryProvider = Provider(
  (ref) =>
      InsightsRepository(ref.watch(dioProvider), ref.watch(localStoreProvider)),
);

/// Gemini explanations, saved on the phone per lake, zone and language:
/// a zone opened once loads instantly and works offline afterwards.
class InsightsRepository {
  InsightsRepository(this._dio, this._store);

  final Dio _dio;
  final LocalStore _store;

  Future<Explanation> explain(String lakeId, String zoneId, String lang) async {
    final key = '$explanationCachePrefix$lakeId|$zoneId|$lang';
    final saved = _store.readJson(key);
    if (saved != null) return Explanation.fromJson(saved, fromCache: true);

    final ex = await guardApi(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/lakes/$lakeId/zones/$zoneId/explain',
        queryParameters: {'lang': lang},
      );
      return Explanation.fromJson(
        res.data!['explanation'] as Map<String, dynamic>,
      );
    });
    await _store.writeJson(key, ex.toJson());
    return ex;
  }

  int savedCount() => _store.countWithPrefix(explanationCachePrefix);

  Future<void> clearSaved() => _store.removeWithPrefix(explanationCachePrefix);
}
