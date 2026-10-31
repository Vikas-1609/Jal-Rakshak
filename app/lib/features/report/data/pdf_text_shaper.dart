import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _sans = 'JalRakshakReportSans';
const _deva = 'JalRakshakReportDeva';

/// Pixels per PDF point in shaped text, so it stays sharp when printed.
const _scale = 4.0;

final _devanagari = RegExp('[ऀ-ॿ]');

/// The pdf package draws glyphs in string order without shaping, so Hindi
/// comes out wrong: "ि" lands after its consonant and conjuncts break apart.
/// Text with Devanagari is drawn by Flutter's engine instead (which shapes it)
/// and embedded as an image; everything else stays real PDF text.
///
/// Usage is two passes: build the content once so [text] records what it
/// needs, await [shapePending], then build again for real.
class PdfTextShaper {
  static bool _fontsLoaded = false;

  final _shaped = <String, ({Uint8List png, double width, double height})>{};
  final _pending = <String, (String, pw.TextStyle, double)>{};

  /// Loads the report's fonts into Flutter so shaped text matches the rest.
  static Future<void> loadFonts({
    required pw.TtfFont regular,
    required pw.TtfFont bold,
    required pw.TtfFont devaRegular,
    required pw.TtfFont devaBold,
  }) async {
    if (_fontsLoaded) return;
    await (FontLoader(_sans)
          ..addFont(Future.value(regular.data))
          ..addFont(Future.value(bold.data)))
        .load();
    await (FontLoader(_deva)
          ..addFont(Future.value(devaRegular.data))
          ..addFont(Future.value(devaBold.data)))
        .load();
    _fontsLoaded = true;
  }

  pw.Widget text(String s, pw.TextStyle style, {required double maxWidth}) {
    if (!_devanagari.hasMatch(s)) return pw.Text(s, style: style);
    final key =
        '$s|${style.fontSize}|${style.fontWeight}|${style.color?.toInt()}|'
        '${style.lineSpacing}|$maxWidth';
    final shaped = _shaped[key];
    if (shaped == null) {
      _pending[key] = (s, style, maxWidth);
      return pw.SizedBox();
    }
    return pw.Image(
      pw.MemoryImage(shaped.png),
      width: shaped.width,
      height: shaped.height,
    );
  }

  Future<void> shapePending() async {
    for (final MapEntry(:key, value: (s, style, maxWidth))
        in _pending.entries) {
      _shaped[key] = await _shape(s, style, maxWidth);
    }
    _pending.clear();
  }

  static Future<({Uint8List png, double width, double height})> _shape(
    String s,
    pw.TextStyle style,
    double maxWidth,
  ) async {
    final size = style.fontSize ?? 10;
    final painter = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: _sans,
          fontFamilyFallback: const [_deva],
          fontSize: size,
          fontWeight: style.fontWeight == pw.FontWeight.bold
              ? FontWeight.bold
              : FontWeight.normal,
          color: Color((style.color ?? PdfColors.black).toInt()),
          height: 1.45 + (style.lineSpacing ?? 0) / size,
        ),
      ),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout(maxWidth: maxWidth);

    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder)..scale(_scale), Offset.zero);
    final image = await recorder.endRecording().toImage(
      (painter.width * _scale).ceil(),
      (painter.height * _scale).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final (width, height) = (painter.width, painter.height);
    image.dispose();
    painter.dispose();
    return (png: bytes!.buffer.asUint8List(), width: width, height: height);
  }
}
