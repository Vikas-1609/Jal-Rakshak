import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catchment/application/catchment_providers.dart';
import '../../catchment/domain/zone.dart';
import '../data/simulator_repository.dart';
import '../domain/fixes.dart';
import '../domain/sim_result.dart';

/// Fixes toggled per zone ID, kept separately for each lake.
final fixesProvider =
    NotifierProvider.family<FixesController, Map<String, Fixes>, String>(
      FixesController.new,
    );

class FixesController extends Notifier<Map<String, Fixes>> {
  FixesController(this.lakeId);

  final String lakeId;

  @override
  Map<String, Fixes> build() => const {};

  void set(String zoneId, Fixes fixes) {
    state = {...state, zoneId: fixes}..removeWhere((_, f) => !f.any);
  }

  /// Apply every fix to the [n] zones that lose the most soil.
  void applyToWorst(int n) {
    final catchment = ref.read(catchmentProvider(lakeId)).value;
    if (catchment == null) return;
    state = {
      ...state,
      for (final z in catchment.byTonnes.take(n)) z.id: Fixes.all,
    };
  }

  /// Apply [fixes] to every zone, replacing the current plan.
  void applyEverywhere(Fixes fixes) {
    final catchment = ref.read(catchmentProvider(lakeId)).value;
    if (catchment == null) return;
    state = {for (final z in catchment.zones) z.id: fixes};
  }

  void reset() => state = const {};
}

/// Backend result for a lake's current fixes; null when nothing is applied.
/// Re-runs whenever the fixes change, so stale responses are dropped.
final simResultProvider = FutureProvider.family<SimResult?, String>((
  ref,
  lakeId,
) async {
  final fixes = ref.watch(fixesProvider(lakeId));
  if (fixes.isEmpty) return null;
  return ref.watch(simulatorRepositoryProvider).simulate(lakeId, fixes);
});

/// Soil loss (t/ha/yr) a zone currently shows on the map, with fixes applied.
double soilLossNow(Zone zone, SimResult? sim) =>
    sim?.zones[zone.id]?.soilLossNew ?? zone.soilLoss;
