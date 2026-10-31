import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../data/insights_repository.dart';
import '../domain/explanation.dart';

typedef ZoneRef = ({String lakeId, String zoneId});

/// Explanation for a zone in the app's current language. Switching language
/// in Settings refetches (or loads the saved copy) in that language.
/// No automatic retry: errors show right away and the card has a Retry button.
final explanationProvider = FutureProvider.family<Explanation, ZoneRef>(
  (ref, zone) => ref
      .watch(insightsRepositoryProvider)
      .explain(zone.lakeId, zone.zoneId, ref.watch(appLanguageProvider)),
  retry: (_, _) => null,
);
