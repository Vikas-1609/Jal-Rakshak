/// Gemini's explanation of one zone, from /api/lakes/{lake}/zones/{id}/explain.
class Explanation {
  Explanation.fromJson(Map<String, dynamic> j, {this.fromCache = false})
    : headline = j['headline'] as String,
      why = (j['why'] as List).cast<String>(),
      actions = [
        for (final a in j['actions'] as List)
          RecommendedAction.fromJson(a as Map<String, dynamic>),
      ],
      farmerTip = j['farmer_tip'] as String;

  final String headline;
  final List<String> why;
  final List<RecommendedAction> actions;
  final String farmerTip;

  /// True when loaded from the phone instead of the server.
  final bool fromCache;

  Map<String, dynamic> toJson() => {
    'headline': headline,
    'why': why,
    'actions': [for (final a in actions) a.toJson()],
    'farmer_tip': farmerTip,
  };
}

class RecommendedAction {
  RecommendedAction.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String,
      where = j['where'] as String,
      impact = j['impact'] as String;

  final String title, where, impact;

  Map<String, dynamic> toJson() => {
    'title': title,
    'where': where,
    'impact': impact,
  };
}
