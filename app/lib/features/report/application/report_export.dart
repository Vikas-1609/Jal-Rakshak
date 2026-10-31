import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/l10n/l10n.dart';
import '../../catchment/domain/catchment.dart';
import '../../insights/application/insights_providers.dart';
import '../../insights/domain/explanation.dart';
import '../../settings/application/settings_providers.dart';
import '../../simulator/application/simulator_providers.dart';
import '../data/plan_report_pdf.dart';

/// How many of the worst zones get a Gemini explanation in the report.
const _explainedZones = 3;

/// Builds the plan report for [catchment] and hands it to the platform:
/// a download on web, the share sheet on Android.
Future<void> exportPlanReport(
  WidgetRef ref,
  AppLocalizations l,
  Catchment catchment,
) async {
  final lakeId = catchment.lakeId;
  final sim = await ref.read(simResultProvider(lakeId).future);

  // Explanations are saved on the phone once fetched, so repeat exports are
  // fast. A zone whose explanation fails is just left out of the report.
  final explanations = <String, Explanation>{};
  await Future.wait([
    for (final z in catchment.byTonnes.take(_explainedZones))
      () async {
        try {
          explanations[z.id] = await ref
              .read(explanationProvider((lakeId: lakeId, zoneId: z.id)).future)
              .timeout(const Duration(seconds: 40));
        } catch (_) {}
      }(),
  ]);

  final bytes = await buildPlanReport(
    l,
    PlanReportData(
      catchment: catchment,
      fixes: ref.read(fixesProvider(lakeId)),
      sim: sim,
      explanations: explanations,
      lang: ref.read(appLanguageProvider),
    ),
  );
  final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'jalrakshak-plan-$lakeId-$stamp.pdf',
  );
}
