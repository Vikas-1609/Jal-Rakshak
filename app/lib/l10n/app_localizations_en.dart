// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JalRakshak';

  @override
  String get navLakes => 'Lakes';

  @override
  String get navMap => 'Map';

  @override
  String get navPlan => 'Plan';

  @override
  String tonnesLakh(String value) {
    return '$value lakh t';
  }

  @override
  String tonnes(String value) {
    return '$value t';
  }

  @override
  String perYear(String amount) {
    return '$amount/yr';
  }

  @override
  String tPerHa(String value) {
    return '$value t/ha';
  }

  @override
  String tPerHaYear(String value) {
    return '$value t/ha/yr';
  }

  @override
  String km2(String value) {
    return '$value km²';
  }

  @override
  String get regionHeadline => 'Soil washing into Aravalli lakes every year';

  @override
  String lakeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lakes',
      one: '1 lake',
    );
    return '$_temp0';
  }

  @override
  String catchmentArea(String area) {
    return '$area km² of catchment';
  }

  @override
  String get lakesByRate => 'Lakes by soil lost per hectare';

  @override
  String districtZones(String district, int zones) {
    return '$district district · $zones zones';
  }

  @override
  String get statSoilLostYear => 'Soil lost / yr';

  @override
  String get statPerHectare => 'Per hectare';

  @override
  String get statFixable => 'Fixable';

  @override
  String get settings => 'Settings';

  @override
  String get chooseLake => 'Choose a lake';

  @override
  String lakePickerSubtitle(String district, String amount) {
    return '$district · $amount/yr';
  }

  @override
  String get soilLostPerYear => 'Soil lost per year';

  @override
  String wasSaving(String before, String saved) {
    return 'was $before · saving $saved';
  }

  @override
  String areaZones(String area, int zones) {
    return '$area km² · $zones zones';
  }

  @override
  String get whereSoilFrom => 'Where is the soil coming from?';

  @override
  String get tapZoneHint =>
      'Tap a zone on the map to see why it loses soil and what would fix it.';

  @override
  String get legendTitle => 'Soil loss (tonnes per hectare per year)';

  @override
  String get biggestSources => 'Biggest sources';

  @override
  String get showWholeCatchment => 'Show whole catchment';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get layerOpacity => 'Zone layer opacity';

  @override
  String get attribution => '© Esri, Maxar, Earthstar Geographics';

  @override
  String zoneTitle(String id) {
    return 'Zone $id';
  }

  @override
  String get zoneHill => 'Hill zone';

  @override
  String get zoneRavine => 'Ravine zone';

  @override
  String get zoneValleyFarm => 'Valley farmland';

  @override
  String get zoneMixed => 'Mixed land';

  @override
  String get riskSlight => 'Slight';

  @override
  String get riskModerate => 'Moderate';

  @override
  String get riskHigh => 'High';

  @override
  String get riskVeryHigh => 'Very high';

  @override
  String get riskSevere => 'Severe';

  @override
  String riskLabel(String level) {
    return '$level risk';
  }

  @override
  String get statSoilLoss => 'Soil loss';

  @override
  String get statPerYear => 'Per year';

  @override
  String get statOfLake => 'Of the lake';

  @override
  String captionAvg(String value) {
    return 'avg $value';
  }

  @override
  String captionLakeAvg(String value) {
    return 'lake avg $value';
  }

  @override
  String captionLand(String value) {
    return '$value km² land';
  }

  @override
  String captionSlope(String value) {
    return 'slope $value°';
  }

  @override
  String get whyButton => 'Why it erodes & what to do';

  @override
  String get back => 'Back';

  @override
  String get landAndSoil => 'Land and soil';

  @override
  String get landCover => 'Land cover';

  @override
  String get cropland => 'Cropland';

  @override
  String get scrubBare => 'Scrub / bare';

  @override
  String get forest => 'Forest';

  @override
  String get builtUp => 'Built-up';

  @override
  String get soilSources => 'Where its soil comes from';

  @override
  String get hillLand => 'Hill land';

  @override
  String get otherLand => 'Other';

  @override
  String get whatIf => 'What if we act here?';

  @override
  String get fixBunds => 'Contour bunds';

  @override
  String fixBundsSub(String pct) {
    return 'On cropland · $pct of the zone';
  }

  @override
  String get fixTrenches => 'Contour trenches';

  @override
  String fixTrenchesSub(String pct) {
    return 'On scrub & bare hill land · $pct of the zone';
  }

  @override
  String get fixReveg => 'Revegetation';

  @override
  String get fixRevegSub => 'Grass & shrubs on hill land · takes 2–3 seasons';

  @override
  String savingBanner(String saved, String pct, String rate) {
    return 'Keeps $saved of soil in place every year (−$pct%). Soil loss drops to $rate t/ha/yr.';
  }

  @override
  String get whyTitle => 'Why, and what to do';

  @override
  String get geminiLoading => 'Gemini is reading this zone\'s data…';

  @override
  String get geminiFootnote =>
      'Written by Gemini from the erosion model\'s numbers.';

  @override
  String get savedOffline => 'Saved on this phone';

  @override
  String explanationError(String error) {
    return 'Explanation unavailable: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get planTitle => 'Restoration plan';

  @override
  String get planSubtitle => 'Pick fixes zone by zone';

  @override
  String get howPlanWorks => 'How planning works';

  @override
  String get soilWithPlan => 'Soil lost per year with this plan';

  @override
  String noFixesYet(String baseline) {
    return 'No fixes yet · baseline $baseline/yr';
  }

  @override
  String planSaving(String saved, String pct, String baseline) {
    return 'Saving $saved/yr · −$pct% of $baseline';
  }

  @override
  String get quickPlans => 'Quick plans';

  @override
  String get worstZones => '4 worst zones';

  @override
  String get allHillLand => 'All hill land';

  @override
  String get allFarmBunds => 'All farm bunds';

  @override
  String get clearPlan => 'Clear';

  @override
  String get zonesBySoil => 'Zones by soil lost';

  @override
  String get chipBunds => 'Bunds';

  @override
  String get chipTrenches => 'Trenches';

  @override
  String get chipReveg => 'Revegetation';

  @override
  String zoneSaves(String saved, String pct) {
    return 'Saves $saved/yr (−$pct%)';
  }

  @override
  String get introTitle1 => 'What is a restoration plan?';

  @override
  String get introBody1 =>
      'Every monsoon, rain washes soil off hills and fields into the lake. A plan picks where to build simple soil-saving works, and JalRakshak shows how much soil would stay on the land instead.';

  @override
  String get introTitle2 => 'Three fixes';

  @override
  String get introBody2 =>
      'Contour bunds: low earth walls along the slope of farm fields that slow water down.\n\nContour trenches: shallow trenches dug along hill slopes that catch running water.\n\nRevegetation: grass and shrubs on bare hills whose roots hold the soil. Takes 2–3 seasons.';

  @override
  String get introTitle3 => 'Where the numbers come from';

  @override
  String get introBody3 =>
      'Satellite data on rainfall, soil, slope and plant cover feeds a standard soil-erosion model (RUSLE). Each fix changes how fast water runs off. The results are estimates to compare places, not measurements.';

  @override
  String get introTitle4 => 'Start where it matters most';

  @override
  String get introBody4 =>
      'Begin with the zones that lose the most soil. Gram panchayats can fund these works under MGNREGA. Tap any zone to see why it erodes and what to do.';

  @override
  String get introNext => 'Next';

  @override
  String get introSkip => 'Skip';

  @override
  String get introStart => 'Start planning';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get hapticsTitle => 'Haptic feedback';

  @override
  String get hapticsSub => 'Gentle vibrations when you tap and toggle';

  @override
  String get savedExplanations => 'Saved explanations';

  @override
  String savedExplanationsSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count explanations on this phone',
      one: '1 explanation on this phone',
      zero: 'None saved yet',
    );
    return '$_temp0';
  }

  @override
  String get clearSaved => 'Clear';

  @override
  String get cleared => 'Saved explanations cleared';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'JalRakshak estimates soil erosion around Aravalli lakes from satellite data and suggests soil-saving works. Built for the GDG Udaipur Aravalli Build Championship.';

  @override
  String get chatTitle => 'Ask about this zone';

  @override
  String get chatIntro =>
      'Have a question the explanation didn\'t cover? Ask Gemini. It answers from this zone\'s numbers.';

  @override
  String get chatSuggest1 => 'Which fix should we start with?';

  @override
  String get chatSuggest2 => 'Can this be done under MGNREGA?';

  @override
  String get chatSuggest3 => 'What can farmers do this season?';

  @override
  String get chatHint => 'Ask a follow-up question';

  @override
  String get chatSend => 'Send';

  @override
  String get chatThinking => 'Gemini is thinking…';

  @override
  String chatError(String error) {
    return 'No answer: $error';
  }

  @override
  String get chatClear => 'Clear chat';

  @override
  String get mapNoKey =>
      'The map needs a Google Maps API key. Add MAPS_API_KEY to app/.env and run with --dart-define-from-file=.env.';

  @override
  String get mapKeyRejected =>
      'Google Maps rejected the API key. Check that the Maps JavaScript API is enabled and that the key\'s website restrictions include this site.';

  @override
  String get chatFootnote =>
      'Gemini answers from this zone\'s numbers and can make mistakes. Check with your block office before spending money.';

  @override
  String get videosTitle => 'Learn how: video guides';

  @override
  String get exportReport => 'Export PDF report';

  @override
  String get exportingReport => 'Preparing report…';

  @override
  String exportFailed(String error) {
    return 'Couldn\'t create the report: $error';
  }

  @override
  String reportTitle(String lake) {
    return 'Soil restoration plan · $lake';
  }

  @override
  String reportGenerated(String date) {
    return 'Generated $date by JalRakshak';
  }

  @override
  String get reportBaseline => 'Soil lost per year today';

  @override
  String get reportWithPlan => 'With this plan';

  @override
  String get reportSaved => 'Kept in place';

  @override
  String reportZonesTreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones treated',
      one: '1 zone treated',
      zero: 'No zones treated yet',
    );
    return '$_temp0';
  }

  @override
  String get reportMapTitle => 'Catchment zones with the plan applied';

  @override
  String get reportMapCaption =>
      'Colour shows soil loss per hectare with the plan applied: green is low, red is severe.';

  @override
  String get reportZoneTable => 'Zone by zone';

  @override
  String get colZone => 'Zone';

  @override
  String get colType => 'Type';

  @override
  String get colRate => 't/ha/yr';

  @override
  String get colPerYear => 'Lost / yr';

  @override
  String get colFixes => 'Fixes';

  @override
  String get colSaved => 'Saved / yr';

  @override
  String get noFixes => 'None';

  @override
  String get reportInsights => 'Why the worst zones erode';

  @override
  String get reportWhy => 'Why';

  @override
  String get reportActions => 'What to do';

  @override
  String get reportTip => 'Tip for farmers';

  @override
  String get reportFootnote =>
      'Estimates from a RUSLE soil-erosion model on satellite data, for comparing places, not measurements. Explanations written by Gemini and can contain mistakes.';
}
