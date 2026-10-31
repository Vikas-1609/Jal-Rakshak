import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JalRakshak'**
  String get appTitle;

  /// No description provided for @navLakes.
  ///
  /// In en, this message translates to:
  /// **'Lakes'**
  String get navLakes;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @tonnesLakh.
  ///
  /// In en, this message translates to:
  /// **'{value} lakh t'**
  String tonnesLakh(String value);

  /// No description provided for @tonnes.
  ///
  /// In en, this message translates to:
  /// **'{value} t'**
  String tonnes(String value);

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'{amount}/yr'**
  String perYear(String amount);

  /// No description provided for @tPerHa.
  ///
  /// In en, this message translates to:
  /// **'{value} t/ha'**
  String tPerHa(String value);

  /// No description provided for @tPerHaYear.
  ///
  /// In en, this message translates to:
  /// **'{value} t/ha/yr'**
  String tPerHaYear(String value);

  /// No description provided for @km2.
  ///
  /// In en, this message translates to:
  /// **'{value} km²'**
  String km2(String value);

  /// No description provided for @regionHeadline.
  ///
  /// In en, this message translates to:
  /// **'Soil washing into Aravalli lakes every year'**
  String get regionHeadline;

  /// No description provided for @lakeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lake} other{{count} lakes}}'**
  String lakeCount(int count);

  /// No description provided for @catchmentArea.
  ///
  /// In en, this message translates to:
  /// **'{area} km² of catchment'**
  String catchmentArea(String area);

  /// No description provided for @lakesByRate.
  ///
  /// In en, this message translates to:
  /// **'Lakes by soil lost per hectare'**
  String get lakesByRate;

  /// No description provided for @districtZones.
  ///
  /// In en, this message translates to:
  /// **'{district} district · {zones} zones'**
  String districtZones(String district, int zones);

  /// No description provided for @statSoilLostYear.
  ///
  /// In en, this message translates to:
  /// **'Soil lost / yr'**
  String get statSoilLostYear;

  /// No description provided for @statPerHectare.
  ///
  /// In en, this message translates to:
  /// **'Per hectare'**
  String get statPerHectare;

  /// No description provided for @statFixable.
  ///
  /// In en, this message translates to:
  /// **'Fixable'**
  String get statFixable;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @chooseLake.
  ///
  /// In en, this message translates to:
  /// **'Choose a lake'**
  String get chooseLake;

  /// No description provided for @lakePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{district} · {amount}/yr'**
  String lakePickerSubtitle(String district, String amount);

  /// No description provided for @soilLostPerYear.
  ///
  /// In en, this message translates to:
  /// **'Soil lost per year'**
  String get soilLostPerYear;

  /// No description provided for @wasSaving.
  ///
  /// In en, this message translates to:
  /// **'was {before} · saving {saved}'**
  String wasSaving(String before, String saved);

  /// No description provided for @areaZones.
  ///
  /// In en, this message translates to:
  /// **'{area} km² · {zones} zones'**
  String areaZones(String area, int zones);

  /// No description provided for @whereSoilFrom.
  ///
  /// In en, this message translates to:
  /// **'Where is the soil coming from?'**
  String get whereSoilFrom;

  /// No description provided for @tapZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a zone on the map to see why it loses soil and what would fix it.'**
  String get tapZoneHint;

  /// No description provided for @legendTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil loss (tonnes per hectare per year)'**
  String get legendTitle;

  /// No description provided for @biggestSources.
  ///
  /// In en, this message translates to:
  /// **'Biggest sources'**
  String get biggestSources;

  /// No description provided for @showWholeCatchment.
  ///
  /// In en, this message translates to:
  /// **'Show whole catchment'**
  String get showWholeCatchment;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @layerOpacity.
  ///
  /// In en, this message translates to:
  /// **'Zone layer opacity'**
  String get layerOpacity;

  /// No description provided for @attribution.
  ///
  /// In en, this message translates to:
  /// **'© Esri, Maxar, Earthstar Geographics'**
  String get attribution;

  /// No description provided for @zoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Zone {id}'**
  String zoneTitle(String id);

  /// No description provided for @zoneHill.
  ///
  /// In en, this message translates to:
  /// **'Hill zone'**
  String get zoneHill;

  /// No description provided for @zoneRavine.
  ///
  /// In en, this message translates to:
  /// **'Ravine zone'**
  String get zoneRavine;

  /// No description provided for @zoneValleyFarm.
  ///
  /// In en, this message translates to:
  /// **'Valley farmland'**
  String get zoneValleyFarm;

  /// No description provided for @zoneMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed land'**
  String get zoneMixed;

  /// No description provided for @riskSlight.
  ///
  /// In en, this message translates to:
  /// **'Slight'**
  String get riskSlight;

  /// No description provided for @riskModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get riskModerate;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get riskHigh;

  /// No description provided for @riskVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very high'**
  String get riskVeryHigh;

  /// No description provided for @riskSevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get riskSevere;

  /// No description provided for @riskLabel.
  ///
  /// In en, this message translates to:
  /// **'{level} risk'**
  String riskLabel(String level);

  /// No description provided for @statSoilLoss.
  ///
  /// In en, this message translates to:
  /// **'Soil loss'**
  String get statSoilLoss;

  /// No description provided for @statPerYear.
  ///
  /// In en, this message translates to:
  /// **'Per year'**
  String get statPerYear;

  /// No description provided for @statOfLake.
  ///
  /// In en, this message translates to:
  /// **'Of the lake'**
  String get statOfLake;

  /// No description provided for @captionAvg.
  ///
  /// In en, this message translates to:
  /// **'avg {value}'**
  String captionAvg(String value);

  /// No description provided for @captionLakeAvg.
  ///
  /// In en, this message translates to:
  /// **'lake avg {value}'**
  String captionLakeAvg(String value);

  /// No description provided for @captionLand.
  ///
  /// In en, this message translates to:
  /// **'{value} km² land'**
  String captionLand(String value);

  /// No description provided for @captionSlope.
  ///
  /// In en, this message translates to:
  /// **'slope {value}°'**
  String captionSlope(String value);

  /// No description provided for @whyButton.
  ///
  /// In en, this message translates to:
  /// **'Why it erodes & what to do'**
  String get whyButton;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @landAndSoil.
  ///
  /// In en, this message translates to:
  /// **'Land and soil'**
  String get landAndSoil;

  /// No description provided for @landCover.
  ///
  /// In en, this message translates to:
  /// **'Land cover'**
  String get landCover;

  /// No description provided for @cropland.
  ///
  /// In en, this message translates to:
  /// **'Cropland'**
  String get cropland;

  /// No description provided for @scrubBare.
  ///
  /// In en, this message translates to:
  /// **'Scrub / bare'**
  String get scrubBare;

  /// No description provided for @forest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get forest;

  /// No description provided for @builtUp.
  ///
  /// In en, this message translates to:
  /// **'Built-up'**
  String get builtUp;

  /// No description provided for @soilSources.
  ///
  /// In en, this message translates to:
  /// **'Where its soil comes from'**
  String get soilSources;

  /// No description provided for @hillLand.
  ///
  /// In en, this message translates to:
  /// **'Hill land'**
  String get hillLand;

  /// No description provided for @otherLand.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLand;

  /// No description provided for @whatIf.
  ///
  /// In en, this message translates to:
  /// **'What if we act here?'**
  String get whatIf;

  /// No description provided for @fixBunds.
  ///
  /// In en, this message translates to:
  /// **'Contour bunds'**
  String get fixBunds;

  /// No description provided for @fixBundsSub.
  ///
  /// In en, this message translates to:
  /// **'On cropland · {pct} of the zone'**
  String fixBundsSub(String pct);

  /// No description provided for @fixTrenches.
  ///
  /// In en, this message translates to:
  /// **'Contour trenches'**
  String get fixTrenches;

  /// No description provided for @fixTrenchesSub.
  ///
  /// In en, this message translates to:
  /// **'On scrub & bare hill land · {pct} of the zone'**
  String fixTrenchesSub(String pct);

  /// No description provided for @fixReveg.
  ///
  /// In en, this message translates to:
  /// **'Revegetation'**
  String get fixReveg;

  /// No description provided for @fixRevegSub.
  ///
  /// In en, this message translates to:
  /// **'Grass & shrubs on hill land · takes 2–3 seasons'**
  String get fixRevegSub;

  /// No description provided for @savingBanner.
  ///
  /// In en, this message translates to:
  /// **'Keeps {saved} of soil in place every year (−{pct}%). Soil loss drops to {rate} t/ha/yr.'**
  String savingBanner(String saved, String pct, String rate);

  /// No description provided for @whyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why, and what to do'**
  String get whyTitle;

  /// No description provided for @geminiLoading.
  ///
  /// In en, this message translates to:
  /// **'Gemini is reading this zone\'s data…'**
  String get geminiLoading;

  /// No description provided for @geminiFootnote.
  ///
  /// In en, this message translates to:
  /// **'Written by Gemini from the erosion model\'s numbers.'**
  String get geminiFootnote;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get savedOffline;

  /// No description provided for @explanationError.
  ///
  /// In en, this message translates to:
  /// **'Explanation unavailable: {error}'**
  String explanationError(String error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Restoration plan'**
  String get planTitle;

  /// No description provided for @planSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick fixes zone by zone'**
  String get planSubtitle;

  /// No description provided for @howPlanWorks.
  ///
  /// In en, this message translates to:
  /// **'How planning works'**
  String get howPlanWorks;

  /// No description provided for @soilWithPlan.
  ///
  /// In en, this message translates to:
  /// **'Soil lost per year with this plan'**
  String get soilWithPlan;

  /// No description provided for @noFixesYet.
  ///
  /// In en, this message translates to:
  /// **'No fixes yet · baseline {baseline}/yr'**
  String noFixesYet(String baseline);

  /// No description provided for @planSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving {saved}/yr · −{pct}% of {baseline}'**
  String planSaving(String saved, String pct, String baseline);

  /// No description provided for @quickPlans.
  ///
  /// In en, this message translates to:
  /// **'Quick plans'**
  String get quickPlans;

  /// No description provided for @worstZones.
  ///
  /// In en, this message translates to:
  /// **'4 worst zones'**
  String get worstZones;

  /// No description provided for @allHillLand.
  ///
  /// In en, this message translates to:
  /// **'All hill land'**
  String get allHillLand;

  /// No description provided for @allFarmBunds.
  ///
  /// In en, this message translates to:
  /// **'All farm bunds'**
  String get allFarmBunds;

  /// No description provided for @clearPlan.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearPlan;

  /// No description provided for @zonesBySoil.
  ///
  /// In en, this message translates to:
  /// **'Zones by soil lost'**
  String get zonesBySoil;

  /// No description provided for @chipBunds.
  ///
  /// In en, this message translates to:
  /// **'Bunds'**
  String get chipBunds;

  /// No description provided for @chipTrenches.
  ///
  /// In en, this message translates to:
  /// **'Trenches'**
  String get chipTrenches;

  /// No description provided for @chipReveg.
  ///
  /// In en, this message translates to:
  /// **'Revegetation'**
  String get chipReveg;

  /// No description provided for @zoneSaves.
  ///
  /// In en, this message translates to:
  /// **'Saves {saved}/yr (−{pct}%)'**
  String zoneSaves(String saved, String pct);

  /// No description provided for @introTitle1.
  ///
  /// In en, this message translates to:
  /// **'What is a restoration plan?'**
  String get introTitle1;

  /// No description provided for @introBody1.
  ///
  /// In en, this message translates to:
  /// **'Every monsoon, rain washes soil off hills and fields into the lake. A plan picks where to build simple soil-saving works, and JalRakshak shows how much soil would stay on the land instead.'**
  String get introBody1;

  /// No description provided for @introTitle2.
  ///
  /// In en, this message translates to:
  /// **'Three fixes'**
  String get introTitle2;

  /// No description provided for @introBody2.
  ///
  /// In en, this message translates to:
  /// **'Contour bunds: low earth walls along the slope of farm fields that slow water down.\n\nContour trenches: shallow trenches dug along hill slopes that catch running water.\n\nRevegetation: grass and shrubs on bare hills whose roots hold the soil. Takes 2–3 seasons.'**
  String get introBody2;

  /// No description provided for @introTitle3.
  ///
  /// In en, this message translates to:
  /// **'Where the numbers come from'**
  String get introTitle3;

  /// No description provided for @introBody3.
  ///
  /// In en, this message translates to:
  /// **'Satellite data on rainfall, soil, slope and plant cover feeds a standard soil-erosion model (RUSLE). Each fix changes how fast water runs off. The results are estimates to compare places, not measurements.'**
  String get introBody3;

  /// No description provided for @introTitle4.
  ///
  /// In en, this message translates to:
  /// **'Start where it matters most'**
  String get introTitle4;

  /// No description provided for @introBody4.
  ///
  /// In en, this message translates to:
  /// **'Begin with the zones that lose the most soil. Gram panchayats can fund these works under MGNREGA. Tap any zone to see why it erodes and what to do.'**
  String get introBody4;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introStart.
  ///
  /// In en, this message translates to:
  /// **'Start planning'**
  String get introStart;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @hapticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticsTitle;

  /// No description provided for @hapticsSub.
  ///
  /// In en, this message translates to:
  /// **'Gentle vibrations when you tap and toggle'**
  String get hapticsSub;

  /// No description provided for @savedExplanations.
  ///
  /// In en, this message translates to:
  /// **'Saved explanations'**
  String get savedExplanations;

  /// No description provided for @savedExplanationsSub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None saved yet} =1{1 explanation on this phone} other{{count} explanations on this phone}}'**
  String savedExplanationsSub(int count);

  /// No description provided for @clearSaved.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSaved;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Saved explanations cleared'**
  String get cleared;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'JalRakshak estimates soil erosion around Aravalli lakes from satellite data and suggests soil-saving works. Built for the GDG Udaipur Aravalli Build Championship.'**
  String get aboutBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
