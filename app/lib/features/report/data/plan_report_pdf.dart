import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/risk_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../catchment/domain/catchment.dart';
import '../../catchment/domain/zone.dart';
import '../../catchment/presentation/zone_labels.dart';
import '../../insights/domain/explanation.dart';
import '../../simulator/application/simulator_providers.dart';
import '../../simulator/domain/fixes.dart';
import '../../simulator/domain/sim_result.dart';
import 'pdf_text_shaper.dart';

/// Everything one plan report shows.
class PlanReportData {
  const PlanReportData({
    required this.catchment,
    required this.fixes,
    required this.sim,
    required this.explanations,
    required this.lang,
  });

  final Catchment catchment;
  final Map<String, Fixes> fixes;
  final SimResult? sim;

  /// Gemini explanations for the worst zones, by zone ID.
  final Map<String, Explanation> explanations;
  final String lang;
}

const _ink = PdfColor.fromInt(0xFF1B1C1A);
const _muted = PdfColor.fromInt(0xFF5F6360);
const _line = PdfColor.fromInt(0xFFD9DCD6);
const _accent = PdfColor.fromInt(0xFF2E6B4F);
const _accentBg = PdfColor.fromInt(0xFFE6F0EA);

/// Page content width: A4 less the 36pt side margins.
final _contentWidth = PdfPageFormat.a4.width - 72;

PdfColor _pdfColor(int argb) => PdfColor.fromInt(argb);

/// Builds the A4 plan report in the app's language. Fonts come from
/// Google Fonts on first use and are cached by the printing package.
Future<Uint8List> buildPlanReport(AppLocalizations l, PlanReportData d) async {
  final regular = await PdfGoogleFonts.notoSansRegular();
  final bold = await PdfGoogleFonts.notoSansBold();
  final devaRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devaBold = await PdfGoogleFonts.notoSansDevanagariBold();
  await PdfTextShaper.loadFonts(
    regular: regular as pw.TtfFont,
    bold: bold as pw.TtfFont,
    devaRegular: devaRegular as pw.TtfFont,
    devaBold: devaBold as pw.TtfFont,
  );
  final t = PdfTextShaper();
  final c = d.catchment;
  final lake = c.lakeName(d.lang);
  final date = DateFormat.yMMMMd(l.localeName).format(DateTime.now());

  pw.Widget footnote() => t.text(
    l.reportFootnote,
    const pw.TextStyle(fontSize: 7, color: _muted),
    maxWidth: _contentWidth - 50,
  );
  List<pw.Widget> content() => [
    t.text(
      l.reportTitle(lake),
      pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _ink),
      maxWidth: _contentWidth,
    ),
    pw.SizedBox(height: 4),
    t.text(
      l.reportGenerated(date),
      const pw.TextStyle(fontSize: 9, color: _muted),
      maxWidth: _contentWidth,
    ),
    pw.SizedBox(height: 16),
    _summary(t, l, d),
    pw.SizedBox(height: 20),
    _heading(t, l.reportMapTitle),
    _map(d),
    pw.SizedBox(height: 6),
    _legend(t, l, c),
    pw.SizedBox(height: 4),
    t.text(
      l.reportMapCaption,
      const pw.TextStyle(fontSize: 8, color: _muted),
      maxWidth: _contentWidth,
    ),
    pw.SizedBox(height: 20),
    _heading(t, l.reportZoneTable),
    _zoneTable(t, l, d),
    if (d.explanations.isNotEmpty) ...[
      pw.SizedBox(height: 20),
      _heading(t, l.reportInsights),
      for (final z in c.byTonnes)
        if (d.explanations[z.id] case final ex?) _insight(t, l, z, ex),
    ],
  ];

  // First pass records the Hindi text to shape; the page build reuses it.
  content();
  footnote();
  await t.shapePending();

  final doc = pw.Document(
    title: l.reportTitle(lake),
    author: 'JalRakshak',
    theme: pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [devaRegular, devaBold],
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 30),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: footnote()),
            pw.SizedBox(width: 16),
            pw.Text(
              '${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (_) => content(),
    ),
  );
  return doc.save();
}

pw.Widget _heading(PdfTextShaper t, String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 8),
  child: t.text(
    text,
    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink),
    maxWidth: _contentWidth,
  ),
);

pw.Widget _summary(PdfTextShaper t, AppLocalizations l, PlanReportData d) {
  final baseline = d.catchment.summary.totalT;
  final sim = d.sim;
  // Three equal boxes with 8pt gaps, 12pt padding and a 1pt border.
  final inner = (_contentWidth - 16) / 3 - 26;
  pw.Widget stat(String label, String value, {String? sub, bool hi = false}) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: hi ? _accentBg : null,
            border: pw.Border.all(color: hi ? _accentBg : _line),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              t.text(
                label,
                const pw.TextStyle(fontSize: 8, color: _muted),
                maxWidth: inner,
              ),
              pw.SizedBox(height: 4),
              t.text(
                value,
                pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: hi ? _accent : _ink,
                ),
                maxWidth: inner,
              ),
              if (sub != null)
                t.text(
                  sub,
                  const pw.TextStyle(fontSize: 8, color: _muted),
                  maxWidth: inner,
                ),
            ],
          ),
        ),
      );

  return pw.Row(
    children: [
      stat(l.reportBaseline, fmtTonnes(l, baseline)),
      pw.SizedBox(width: 8),
      stat(
        l.reportWithPlan,
        fmtTonnes(l, sim?.scenarioT ?? baseline),
        sub: l.reportZonesTreated(d.fixes.length),
      ),
      pw.SizedBox(width: 8),
      stat(
        l.reportSaved,
        fmtTonnes(l, sim?.savedT ?? 0),
        sub: '−${(sim?.savedPct ?? 0).toStringAsFixed(0)}%',
        hi: true,
      ),
    ],
  );
}

/// Zone polygons drawn as vectors, coloured by soil loss with the plan.
pw.Widget _map(PlanReportData d) {
  final c = d.catchment;
  final pts = [for (final z in c.zones) ...z.allPoints];
  final minLat = pts.map((p) => p.latitude).reduce(math.min);
  final maxLat = pts.map((p) => p.latitude).reduce(math.max);
  final minLng = pts.map((p) => p.longitude).reduce(math.min);
  final maxLng = pts.map((p) => p.longitude).reduce(math.max);
  // Equirectangular: shrink longitude by cos(latitude) to keep shapes true.
  final kx = math.cos((minLat + maxLat) / 2 * math.pi / 180);
  final w = (maxLng - minLng) * kx;
  final h = maxLat - minLat;
  final height = math.min(280.0, _contentWidth * h / w);

  return pw.Container(
    decoration: pw.BoxDecoration(
      color: const PdfColor.fromInt(0xFFF6F7F4),
      border: pw.Border.all(color: _line),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    padding: const pw.EdgeInsets.all(10),
    child: pw.CustomPaint(
      size: PdfPoint(_contentWidth - 20, height - 20),
      painter: (canvas, size) {
        final scale = math.min(size.x / w, size.y / h);
        final ox = (size.x - w * scale) / 2;
        final oy = (size.y - h * scale) / 2;
        canvas
          ..setStrokeColor(PdfColors.white)
          ..setLineWidth(0.6)
          ..setLineJoin(PdfLineJoin.round);
        for (final z in c.zones) {
          final color = riskColor(soilLossNow(z, d.sim), c.minLoss, c.maxLoss);
          canvas.setFillColor(_pdfColor(color.toARGB32()));
          for (final ring in z.rings) {
            for (final (i, p) in ring.indexed) {
              final x = ox + (p.longitude - minLng) * kx * scale;
              final y = oy + (p.latitude - minLat) * scale;
              i == 0 ? canvas.moveTo(x, y) : canvas.lineTo(x, y);
            }
            canvas.closePath();
          }
          canvas.fillAndStrokePath();
        }
      },
    ),
  );
}

pw.Widget _legend(PdfTextShaper t, AppLocalizations l, Catchment c) {
  const steps = 5;
  return pw.Row(
    children: [
      for (var i = 0; i < steps; i++) ...[
        () {
          final v = c.minLoss + (c.maxLoss - c.minLoss) * i / (steps - 1);
          return pw.Row(
            children: [
              pw.Container(
                width: 10,
                height: 10,
                decoration: pw.BoxDecoration(
                  color: _pdfColor(
                    riskColor(v, c.minLoss, c.maxLoss).toARGB32(),
                  ),
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(width: 4),
              t.text(
                l.tPerHaYear(fmt1(v)),
                const pw.TextStyle(fontSize: 8, color: _muted),
                maxWidth: _contentWidth,
              ),
            ],
          );
        }(),
        if (i < steps - 1) pw.SizedBox(width: 12),
      ],
    ],
  );
}

String _fixNames(AppLocalizations l, Fixes? f) {
  if (f == null || !f.any) return l.noFixes;
  return [
    if (f.bunds) l.chipBunds,
    if (f.trenches) l.chipTrenches,
    if (f.reveg) l.chipReveg,
  ].join(', ');
}

const _columnFlex = [0.9, 1.4, 1.2, 1.2, 2.8, 1.2];
const _cellPad = 8.0;

pw.Widget _zoneTable(PdfTextShaper t, AppLocalizations l, PlanReportData d) {
  final c = d.catchment;
  const head = pw.TextStyle(fontSize: 8, color: _muted);
  const cell = pw.TextStyle(fontSize: 8.5, color: _ink);
  final flexSum = _columnFlex.reduce((a, b) => a + b);
  double colWidth(int i) =>
      _contentWidth * _columnFlex[i] / flexSum - 2 * _cellPad;
  pw.Widget pad(pw.Widget child, {bool right = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: _cellPad, vertical: 5),
    child: right
        ? pw.Align(alignment: pw.Alignment.centerRight, child: child)
        : child,
  );
  pw.Widget text(
    int col,
    String s, {
    bool right = false,
    pw.TextStyle style = cell,
  }) => pad(t.text(s, style, maxWidth: colWidth(col)), right: right);

  return pw.Table(
    columnWidths: {
      for (final (i, f) in _columnFlex.indexed) i: pw.FlexColumnWidth(f),
    },
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      bottom: pw.BorderSide(color: _line, width: 0.5),
    ),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 0.8)),
        ),
        repeat: true,
        children: [
          text(0, l.colZone, style: head),
          text(1, l.colType, style: head),
          text(2, l.colRate, style: head, right: true),
          text(3, l.colPerYear, style: head, right: true),
          text(4, l.colFixes, style: head),
          text(5, l.colSaved, style: head, right: true),
        ],
      ),
      for (final z in c.byTonnes)
        () {
          final now = soilLossNow(z, d.sim);
          final saved = d.sim?.zones[z.id]?.savedT ?? 0;
          final treated = d.fixes[z.id]?.any ?? false;
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              pad(
                pw.Row(
                  children: [
                    pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(
                        color: _pdfColor(
                          riskColor(now, c.minLoss, c.maxLoss).toARGB32(),
                        ),
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(z.id, style: cell),
                  ],
                ),
              ),
              text(1, l.zoneType(z.type)),
              text(
                2,
                treated && saved > 0
                    ? '${fmt1(z.soilLoss)} › ${fmt1(now)}'
                    : fmt1(z.soilLoss),
                right: true,
              ),
              text(3, fmtTonnes(l, z.tTotal), right: true),
              text(
                4,
                _fixNames(l, d.fixes[z.id]),
                style: treated
                    ? cell
                    : const pw.TextStyle(fontSize: 8.5, color: _muted),
              ),
              text(
                5,
                saved > 0 ? fmtTonnes(l, saved) : '–',
                right: true,
                style: saved > 0
                    ? pw.TextStyle(
                        fontSize: 8.5,
                        color: _accent,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : cell,
              ),
            ],
          );
        }(),
    ],
  );
}

pw.Widget _insight(
  PdfTextShaper t,
  AppLocalizations l,
  Zone z,
  Explanation ex,
) {
  const body = pw.TextStyle(fontSize: 9, color: _ink, lineSpacing: 2);
  const label = pw.TextStyle(fontSize: 8, color: _muted);
  // Card: 12pt padding and a 1pt border each side.
  final inner = _contentWidth - 26;
  const bulletWidth = 12.0;
  pw.Widget bullet(String s) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1.5),
          child: pw.SizedBox(
            width: bulletWidth,
            child: pw.Text('•', style: body),
          ),
        ),
        pw.Expanded(child: t.text(s, body, maxWidth: inner - bulletWidth)),
      ],
    ),
  );

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        t.text(
          '${l.zoneTitle(z.id)} · ${l.zoneType(z.type)} · '
          '${l.riskLabel(l.riskClass(z.riskClass))}',
          label,
          maxWidth: inner,
        ),
        pw.SizedBox(height: 3),
        t.text(
          ex.headline,
          pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          maxWidth: inner,
        ),
        pw.SizedBox(height: 8),
        t.text(l.reportWhy, label, maxWidth: inner),
        pw.SizedBox(height: 3),
        for (final w in ex.why) bullet(w),
        pw.SizedBox(height: 6),
        t.text(l.reportActions, label, maxWidth: inner),
        pw.SizedBox(height: 3),
        for (final a in ex.actions)
          bullet('${a.title}: ${a.where}. ${a.impact}'),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: _accentBg,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: t.text(
            '${l.reportTip}: ${ex.farmerTip}',
            const pw.TextStyle(fontSize: 9, color: _accent),
            maxWidth: inner - 16,
          ),
        ),
      ],
    ),
  );
}
