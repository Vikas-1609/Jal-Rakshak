import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lakes_repository.dart';
import '../domain/lake.dart';

/// Every lake with data, ranked by soil lost per hectare (worst first).
final lakesProvider = FutureProvider<List<Lake>>((ref) async {
  final lakes = await ref.watch(lakesRepositoryProvider).fetchAll();
  return lakes..sort((a, b) => b.meanSoilLoss.compareTo(a.meanSoilLoss));
});

/// The lake shown on the Map and Plan tabs. Null until lakes load,
/// then defaults to the first lake.
final selectedLakeIdProvider = NotifierProvider<SelectedLakeId, String?>(
  SelectedLakeId.new,
);

class SelectedLakeId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

final selectedLakeProvider = Provider<Lake?>((ref) {
  final lakes = ref.watch(lakesProvider).value;
  if (lakes == null || lakes.isEmpty) return null;
  final id = ref.watch(selectedLakeIdProvider);
  return lakes.firstWhere((l) => l.id == id, orElse: () => lakes.first);
});
