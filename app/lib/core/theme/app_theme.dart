import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Water-teal brand colour; the whole palette derives from it.
const brandSeed = Color(0xFF0E6E7E);

/// Vibrant scheme: stronger chroma than the default tonal spot.
M3EColorScheme _scheme(Brightness b) => M3EColorScheme.fromColorScheme(
  ColorScheme.fromSeed(
    seedColor: brandSeed,
    brightness: b,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  ),
);

/// Material 3 Expressive tokens (type, shape, motion) for each brightness.
final M3EThemeData lightThemeData = M3EThemeData.light(seedColor: brandSeed)
    .copyWith(colorScheme: _scheme(Brightness.light));

final M3EThemeData darkThemeData = M3EThemeData.dark(seedColor: brandSeed)
    .copyWith(colorScheme: _scheme(Brightness.dark));

/// Shorthand for the expressive emphasized type scale (bolder, for
/// headlines, key numbers and selected states).
M3ETypeScale emphasized(BuildContext context) =>
    M3ETheme.of(context).typography.emphasized;
