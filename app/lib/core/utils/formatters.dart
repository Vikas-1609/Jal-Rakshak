import '../../l10n/app_localizations.dart';

/// Tonnes with Indian units: 1128950 → "11.3 lakh t" / "11.3 लाख टन",
/// 12003 → "12,003 t" / "12,003 टन".
String fmtTonnes(AppLocalizations l, double t) {
  if (t.abs() >= 100000) return l.tonnesLakh((t / 100000).toStringAsFixed(1));
  return l.tonnes(groupIndian(t.round()));
}

/// Indian digit grouping: 141386 → "1,41,386".
String groupIndian(int n) {
  final neg = n < 0;
  var s = n.abs().toString();
  if (s.length > 3) {
    var head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final parts = <String>[];
    while (head.length > 2) {
      parts.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    parts.insert(0, head);
    s = '${parts.join(',')},$tail';
  }
  return neg ? '-$s' : s;
}

/// Fraction as a whole percentage: 0.234 → "23%".
String fmtPct(double frac) => '${(frac * 100).round()}%';

/// One decimal place, e.g. soil loss rates and slopes.
String fmt1(double v) => v.toStringAsFixed(1);
