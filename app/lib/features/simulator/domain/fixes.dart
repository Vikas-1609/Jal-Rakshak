/// Interventions toggled for one zone.
/// Bunds apply to cropland; trenches and revegetation to scrub/bare hill land.
class Fixes {
  const Fixes({this.bunds = false, this.trenches = false, this.reveg = false});

  static const all = Fixes(bunds: true, trenches: true, reveg: true);

  final bool bunds, trenches, reveg;

  bool get any => bunds || trenches || reveg;

  Fixes copyWith({bool? bunds, bool? trenches, bool? reveg}) => Fixes(
    bunds: bunds ?? this.bunds,
    trenches: trenches ?? this.trenches,
    reveg: reveg ?? this.reveg,
  );

  Map<String, bool> toJson() => {
    'bunds': bunds,
    'trenches': trenches,
    'reveg': reveg,
  };

  @override
  bool operator ==(Object other) =>
      other is Fixes &&
      other.bunds == bunds &&
      other.trenches == trenches &&
      other.reveg == reveg;

  @override
  int get hashCode => Object.hash(bunds, trenches, reveg);
}
