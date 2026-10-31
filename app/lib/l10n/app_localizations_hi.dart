// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'जलरक्षक';

  @override
  String get navLakes => 'झीलें';

  @override
  String get navMap => 'नक्शा';

  @override
  String get navPlan => 'योजना';

  @override
  String tonnesLakh(String value) {
    return '$value लाख टन';
  }

  @override
  String tonnes(String value) {
    return '$value टन';
  }

  @override
  String perYear(String amount) {
    return '$amount/वर्ष';
  }

  @override
  String tPerHa(String value) {
    return '$value टन/हे.';
  }

  @override
  String tPerHaYear(String value) {
    return '$value टन/हे./वर्ष';
  }

  @override
  String km2(String value) {
    return '$value वर्ग कि.मी.';
  }

  @override
  String get regionHeadline => 'हर साल अरावली की झीलों में बहती मिट्टी';

  @override
  String lakeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count झीलें',
      one: '1 झील',
    );
    return '$_temp0';
  }

  @override
  String catchmentArea(String area) {
    return '$area वर्ग कि.मी. जलग्रहण क्षेत्र';
  }

  @override
  String get lakesByRate => 'प्रति हेक्टेयर मिट्टी के नुकसान के क्रम में झीलें';

  @override
  String districtZones(String district, int zones) {
    return '$district ज़िला · $zones क्षेत्र';
  }

  @override
  String get statSoilLostYear => 'मिट्टी का नुकसान / वर्ष';

  @override
  String get statPerHectare => 'प्रति हेक्टेयर';

  @override
  String get statFixable => 'रोका जा सकता है';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get chooseLake => 'झील चुनें';

  @override
  String lakePickerSubtitle(String district, String amount) {
    return '$district · $amount/वर्ष';
  }

  @override
  String get soilLostPerYear => 'हर साल मिट्टी का नुकसान';

  @override
  String wasSaving(String before, String saved) {
    return 'पहले $before · बचत $saved';
  }

  @override
  String areaZones(String area, int zones) {
    return '$area वर्ग कि.मी. · $zones क्षेत्र';
  }

  @override
  String get whereSoilFrom => 'मिट्टी कहाँ से बह रही है?';

  @override
  String get tapZoneHint =>
      'नक्शे पर किसी क्षेत्र को छुएँ और देखें कि वहाँ मिट्टी क्यों बहती है और क्या उपाय करें।';

  @override
  String get legendTitle => 'मिट्टी का नुकसान (टन प्रति हेक्टेयर प्रति वर्ष)';

  @override
  String get biggestSources => 'सबसे ज़्यादा नुकसान वाले क्षेत्र';

  @override
  String get showWholeCatchment => 'पूरा जलग्रहण क्षेत्र दिखाएँ';

  @override
  String get zoomIn => 'ज़ूम इन';

  @override
  String get zoomOut => 'ज़ूम आउट';

  @override
  String get layerOpacity => 'क्षेत्र परत की पारदर्शिता';

  @override
  String get attribution => '© Esri, Maxar, Earthstar Geographics';

  @override
  String zoneTitle(String id) {
    return 'क्षेत्र $id';
  }

  @override
  String get zoneHill => 'पहाड़ी क्षेत्र';

  @override
  String get zoneRavine => 'बीहड़ क्षेत्र';

  @override
  String get zoneValleyFarm => 'घाटी की खेती';

  @override
  String get zoneMixed => 'मिश्रित भूमि';

  @override
  String get riskSlight => 'कम';

  @override
  String get riskModerate => 'मध्यम';

  @override
  String get riskHigh => 'अधिक';

  @override
  String get riskVeryHigh => 'बहुत अधिक';

  @override
  String get riskSevere => 'गंभीर';

  @override
  String riskLabel(String level) {
    return '$level जोखिम';
  }

  @override
  String get statSoilLoss => 'मिट्टी का नुकसान';

  @override
  String get statPerYear => 'प्रति वर्ष';

  @override
  String get statOfLake => 'झील का हिस्सा';

  @override
  String captionAvg(String value) {
    return 'औसत $value';
  }

  @override
  String captionLakeAvg(String value) {
    return 'झील का औसत $value';
  }

  @override
  String captionLand(String value) {
    return '$value वर्ग कि.मी. भूमि';
  }

  @override
  String captionSlope(String value) {
    return 'ढलान $value°';
  }

  @override
  String get whyButton => 'मिट्टी क्यों बहती है और क्या करें';

  @override
  String get back => 'वापस';

  @override
  String get landAndSoil => 'भूमि और मिट्टी';

  @override
  String get landCover => 'भूमि का उपयोग';

  @override
  String get cropland => 'खेती';

  @override
  String get scrubBare => 'झाड़ी / खाली';

  @override
  String get forest => 'जंगल';

  @override
  String get builtUp => 'बस्ती';

  @override
  String get soilSources => 'मिट्टी कहाँ से बहती है';

  @override
  String get hillLand => 'पहाड़ी भूमि';

  @override
  String get otherLand => 'अन्य';

  @override
  String get whatIf => 'अगर यहाँ काम करें तो?';

  @override
  String get fixBunds => 'मेड़बंदी';

  @override
  String fixBundsSub(String pct) {
    return 'खेतों पर · क्षेत्र का $pct';
  }

  @override
  String get fixTrenches => 'कंटूर खाई';

  @override
  String fixTrenchesSub(String pct) {
    return 'झाड़ी और खाली पहाड़ी भूमि पर · क्षेत्र का $pct';
  }

  @override
  String get fixReveg => 'पौधारोपण और घास';

  @override
  String get fixRevegSub =>
      'पहाड़ी भूमि पर घास और झाड़ियाँ · 2–3 मौसम लगते हैं';

  @override
  String savingBanner(String saved, String pct, String rate) {
    return 'हर साल $saved मिट्टी अपनी जगह पर रहेगी (−$pct%)। नुकसान घटकर $rate टन/हे./वर्ष रह जाएगा।';
  }

  @override
  String get whyTitle => 'मिट्टी क्यों बहती है, और क्या करें';

  @override
  String get geminiLoading => 'Gemini इस क्षेत्र का डेटा पढ़ रहा है…';

  @override
  String get geminiFootnote =>
      'मिट्टी कटाव मॉडल के आँकड़ों से Gemini द्वारा लिखा गया।';

  @override
  String get savedOffline => 'इस फ़ोन में सहेजा गया';

  @override
  String explanationError(String error) {
    return 'जानकारी उपलब्ध नहीं: $error';
  }

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get planTitle => 'सुधार योजना';

  @override
  String get planSubtitle => 'हर क्षेत्र के लिए उपाय चुनें';

  @override
  String get howPlanWorks => 'योजना कैसे काम करती है';

  @override
  String get soilWithPlan => 'इस योजना के साथ हर साल मिट्टी का नुकसान';

  @override
  String noFixesYet(String baseline) {
    return 'अभी कोई उपाय नहीं · आधार $baseline/वर्ष';
  }

  @override
  String planSaving(String saved, String pct, String baseline) {
    return 'बचत $saved/वर्ष · $baseline का −$pct%';
  }

  @override
  String get quickPlans => 'तैयार योजनाएँ';

  @override
  String get worstZones => '4 सबसे खराब क्षेत्र';

  @override
  String get allHillLand => 'सारी पहाड़ी भूमि';

  @override
  String get allFarmBunds => 'सभी खेतों पर मेड़बंदी';

  @override
  String get clearPlan => 'हटाएँ';

  @override
  String get zonesBySoil => 'मिट्टी के नुकसान के क्रम में क्षेत्र';

  @override
  String get chipBunds => 'मेड़बंदी';

  @override
  String get chipTrenches => 'कंटूर खाई';

  @override
  String get chipReveg => 'पौधारोपण';

  @override
  String zoneSaves(String saved, String pct) {
    return 'बचत $saved/वर्ष (−$pct%)';
  }

  @override
  String get introTitle1 => 'सुधार योजना क्या है?';

  @override
  String get introBody1 =>
      'हर मानसून में बारिश पहाड़ियों और खेतों की मिट्टी को बहाकर झील में ले जाती है। योजना में तय होता है कि मिट्टी बचाने के सरल काम कहाँ करें, और जलरक्षक दिखाता है कि कितनी मिट्टी ज़मीन पर ही रुक जाएगी।';

  @override
  String get introTitle2 => 'तीन उपाय';

  @override
  String get introBody2 =>
      'मेड़बंदी: खेतों में ढलान के आर-पार मिट्टी की नीची मेड़, जो पानी की रफ़्तार कम करती है।\n\nकंटूर खाई: पहाड़ी ढलानों पर खोदी गई उथली खाइयाँ, जो बहते पानी को रोकती हैं।\n\nपौधारोपण और घास: खाली पहाड़ियों पर घास और झाड़ियाँ, जिनकी जड़ें मिट्टी को बाँधती हैं। 2–3 मौसम लगते हैं।';

  @override
  String get introTitle3 => 'आँकड़े कहाँ से आते हैं';

  @override
  String get introBody3 =>
      'बारिश, मिट्टी, ढलान और हरियाली का उपग्रह डेटा मिट्टी कटाव के एक मानक मॉडल (RUSLE) में जाता है। हर उपाय पानी के बहाव की रफ़्तार बदलता है। ये नतीजे जगहों की तुलना के लिए अनुमान हैं, नाप नहीं।';

  @override
  String get introTitle4 => 'सबसे ज़रूरी जगह से शुरू करें';

  @override
  String get introBody4 =>
      'उन क्षेत्रों से शुरू करें जहाँ सबसे ज़्यादा मिट्टी बहती है। ग्राम पंचायतें ये काम मनरेगा के तहत करवा सकती हैं। किसी भी क्षेत्र को छूकर देखें कि मिट्टी क्यों बहती है और क्या करें।';

  @override
  String get introNext => 'आगे';

  @override
  String get introSkip => 'छोड़ें';

  @override
  String get introStart => 'योजना बनाएँ';

  @override
  String get appearance => 'रूप';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम';

  @override
  String get hapticsTitle => 'कंपन प्रतिक्रिया';

  @override
  String get hapticsSub => 'छूने और बदलने पर हल्का कंपन';

  @override
  String get savedExplanations => 'सहेजी गई जानकारी';

  @override
  String savedExplanationsSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस फ़ोन में $count जानकारियाँ',
      one: 'इस फ़ोन में 1 जानकारी',
      zero: 'अभी कुछ सहेजा नहीं गया',
    );
    return '$_temp0';
  }

  @override
  String get clearSaved => 'हटाएँ';

  @override
  String get cleared => 'सहेजी गई जानकारी हटा दी गई';

  @override
  String get about => 'परिचय';

  @override
  String get aboutBody =>
      'जलरक्षक उपग्रह डेटा से अरावली की झीलों के आसपास मिट्टी कटाव का अनुमान लगाता है और मिट्टी बचाने के उपाय सुझाता है। GDG उदयपुर अरावली बिल्ड चैंपियनशिप के लिए बनाया गया।';

  @override
  String get chatTitle => 'इस क्षेत्र के बारे में पूछें';

  @override
  String get chatIntro =>
      'कोई सवाल जिसका जवाब ऊपर नहीं मिला? Gemini से पूछें। वह इस क्षेत्र के आँकड़ों से जवाब देता है।';

  @override
  String get chatSuggest1 => 'शुरुआत किस काम से करें?';

  @override
  String get chatSuggest2 => 'क्या यह काम मनरेगा में हो सकता है?';

  @override
  String get chatSuggest3 => 'किसान इस मौसम में क्या करें?';

  @override
  String get chatHint => 'अपना सवाल लिखें';

  @override
  String get chatSend => 'भेजें';

  @override
  String get chatThinking => 'Gemini सोच रहा है…';

  @override
  String chatError(String error) {
    return 'जवाब नहीं मिला: $error';
  }

  @override
  String get chatClear => 'बातचीत मिटाएँ';

  @override
  String get mapNoKey =>
      'नक्शे के लिए Google Maps API key चाहिए। app/.env में MAPS_API_KEY जोड़ें और --dart-define-from-file=.env के साथ चलाएँ।';

  @override
  String get mapKeyRejected =>
      'Google Maps ने API key अस्वीकार कर दी। जाँचें कि Maps JavaScript API चालू है और key की वेबसाइट पाबंदियों में यह साइट शामिल है।';

  @override
  String get chatFootnote =>
      'Gemini इस क्षेत्र के आँकड़ों से जवाब देता है और गलती कर सकता है। पैसा लगाने से पहले ब्लॉक कार्यालय से पूछ लें।';
}
