import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../settings/application/settings_providers.dart';
import '../application/catchment_providers.dart';
import 'widgets/zone_detail_content.dart';
import 'widgets/zone_header.dart';

/// Zone details as a page (opened from the Plan tab). The Map tab shows the
/// same content in its expanding sheet.
class ZoneDetailPage extends ConsumerWidget {
  const ZoneDetailPage({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = ref.watch(appLanguageProvider);
    final catchment = ref.watch(currentCatchmentProvider);
    return Scaffold(
      appBar: M3EAppBar.top(
        variant: M3EAppBarVariant.mediumFlexible,
        titleText: l.zoneTitle(zoneId),
        subtitleText: catchment.value?.lakeName(lang),
        leading: M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: const Icon(Icons.arrow_back),
          tooltip: l.back,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: AsyncView(
        value: catchment,
        onRetry: () => retryCurrentCatchment(ref),
        data: (c) {
          final zone = c.byId[zoneId];
          if (zone == null) return ErrorState(message: l.zoneTitle(zoneId));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              ZoneHeader(catchment: c, zone: zone),
              const SizedBox(height: 16),
              ZoneDetailContent(catchment: c, zone: zone),
            ],
          );
        },
      ),
    );
  }
}
