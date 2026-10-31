import 'package:flutter/services.dart';

/// One place for haptic feedback, so the Settings switch turns it all off.
///
/// Three levels, softest first. Default to [selection]; the stronger ones are
/// for the few moments that should stand out.
abstract final class Haptics {
  static bool enabled = true;

  /// Softest tick: toggles, chips, tabs, slider steps, zone taps, and minor
  /// controls (zoom, close, info, retry, next).
  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Light impact: main navigation actions, e.g. opening a lake or a zone's
  /// full explanation.
  static void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Medium impact: a meaningful change, e.g. applying a quick plan.
  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
