import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lakes/application/lakes_providers.dart';
import '../data/catchment_repository.dart';
import '../domain/catchment.dart';
import '../domain/zone.dart';

/// Zones and totals for one lake, cached per lake.
final catchmentProvider = FutureProvider.family<Catchment, String>(
  (ref, lakeId) => ref.watch(catchmentRepositoryProvider).fetch(lakeId),
);

/// The selected lake's catchment, including the lakes list's own loading
/// and error states, so pages only need to watch this one provider.
final currentCatchmentProvider = Provider<AsyncValue<Catchment>>((ref) {
  final lake = ref.watch(selectedLakeProvider);
  if (lake != null) return ref.watch(catchmentProvider(lake.id));
  return switch (ref.watch(lakesProvider)) {
    AsyncError(:final error, :final stackTrace) => AsyncError(
      error,
      stackTrace,
    ),
    AsyncData() => AsyncError('No lakes available', StackTrace.current),
    _ => const AsyncLoading(),
  };
});

/// Reloads whatever [currentCatchmentProvider] failed on.
void retryCurrentCatchment(WidgetRef ref) {
  final lake = ref.read(selectedLakeProvider);
  if (lake == null) {
    ref.invalidate(lakesProvider);
  } else {
    ref.invalidate(catchmentProvider(lake.id));
  }
}

/// The zone tapped on the map; resets to null when the lake changes.
final selectedZoneIdProvider = NotifierProvider<SelectedZoneId, String?>(
  SelectedZoneId.new,
);

class SelectedZoneId extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(selectedLakeIdProvider);
    return null;
  }

  void select(String? id) => state = id;
}

final selectedZoneProvider = Provider<Zone?>((ref) {
  final id = ref.watch(selectedZoneIdProvider);
  return id == null
      ? null
      : ref.watch(currentCatchmentProvider).value?.byId[id];
});
