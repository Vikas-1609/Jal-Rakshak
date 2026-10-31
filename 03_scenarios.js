// ============================================================
// JalRakshak — 03_scenarios
// Per-zone land cover, soil loss in tonnes, and intervention scenarios
// for the Jaisamand catchment. The app reads this export; it replaces
// 02_erosion's output (same RUSLE, plus a seasonal C fix for forest).
//
// Soil loss is split by land type so each fix applies only where it
// would actually be built:
//   cropland   → contour bunds              (lowers P)
//   hill land  → contour trenches            (lowers P)
//              → revegetation                (lowers C)
//   other land → no change (forest, built-up, etc.)
// ============================================================

// 0. Zones saved by 01_catchment
var zones = ee.FeatureCollection('projects/jal-rakshak-511510/assets/jaisamand_zones');
var catchment = zones.geometry();
Map.centerObject(zones, 10);

// 1–4. R, K, LS — identical to 02_erosion. C differs for forest (see below)
var annualRain = ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
  .filterDate('2015-01-01', '2025-01-01')
  .sum().divide(10).rename('rain_mm');
var R = annualRain.multiply(0.363).add(79).rename('R');

var sand = ee.Image('OpenLandMap/SOL/SOL_SAND-WFRACTION_USDA-3A1A1A_M/v02').select('b0').toFloat();
var clay = ee.Image('OpenLandMap/SOL/SOL_CLAY-WFRACTION_USDA-3A1A1A_M/v02').select('b0').toFloat();
var oc = ee.Image('OpenLandMap/SOL/SOL_ORGANIC-CARBON_USDA-6A1C_M/v02').select('b0')
  .toFloat().multiply(0.5);
var silt = ee.Image(100).toFloat().subtract(sand).subtract(clay);

var fSand = sand.multiply(-0.256).multiply(ee.Image(1).subtract(silt.divide(100))).exp().multiply(0.3).add(0.2);
var fClaySilt = silt.divide(clay.add(silt)).pow(0.3);
var fOrgC = ee.Image(1).subtract(oc.multiply(0.25).divide(oc.add(oc.multiply(-2.95).add(3.72).exp())));
var sn1 = ee.Image(1).subtract(sand.divide(100));
var fHiSand = ee.Image(1).subtract(sn1.multiply(0.7).divide(sn1.add(sn1.multiply(22.9).add(-5.51).exp())));
var K = fSand.multiply(fClaySilt).multiply(fOrgC).multiply(fHiSand).multiply(0.1317).rename('K');

var dem = ee.Image('USGS/SRTMGL1_003');
var slopeDeg = ee.Terrain.slope(dem).rename('slope_deg');
var slopeRad = slopeDeg.multiply(Math.PI / 180);
var slopePct = slopeRad.tan().multiply(100);
var m = ee.Image(0.2)
  .where(slopePct.gte(1), 0.3)
  .where(slopePct.gte(3), 0.4)
  .where(slopePct.gte(5), 0.5);
var sinS = slopeRad.sin();
var S = sinS.pow(2).multiply(65.41).add(sinS.multiply(4.56)).add(0.065);
var L = ee.Image(50 / 22.13).pow(m);
var LS = L.multiply(S).rename('LS');

var s2 = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(catchment)
  .filterDate('2026-04-01', '2026-06-10')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 10))
  .median();
var ndvi = s2.normalizedDifference(['B8', 'B4']).rename('ndvi');
var Cdry = ndvi.multiply(-2).divide(ee.Image(1).subtract(ndvi)).exp().clamp(0, 1);

// Land cover — ESA WorldCover 10 m (2021)
//    10 tree, 20 shrub, 30 grass, 40 cropland, 50 built-up, 60 bare/sparse, 80 water
var lc = ee.ImageCollection('ESA/WorldCover/v200').first();
var crop = lc.eq(40).rename('crop');
var hill = lc.eq(20).or(lc.eq(30)).or(lc.eq(60)).rename('hill');   // shrub, grass, bare: treatable non-farm land
var tree = lc.eq(10).rename('tree');
var built = lc.eq(50).rename('built');

// Forest C from post-monsoon NDVI. Aravalli forest is dry deciduous and
// leafless in Apr–May, but in leaf (with litter below) during the monsoon
// rains, so pre-monsoon NDVI would overstate its erosion.
// Cropland and scrub keep pre-monsoon C: fields are bare when the rains start.
var s2wet = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(catchment)
  .filterDate('2025-09-15', '2025-11-15')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20))
  .median();
var ndviWet = s2wet.normalizedDifference(['B8', 'B4']);
var Cwet = ndviWet.multiply(-2).divide(ee.Image(1).subtract(ndviWet)).exp().clamp(0, 1);
var C = Cdry.where(tree, Cwet.unmask(Cdry)).rename('C');

var landMask = ee.Image('JRC/GSW1_4/GlobalSurfaceWater').select('occurrence').unmask(0).lt(50);

// 5. Baseline soil loss (P = 1, no conservation measures)
var RKLS = R.multiply(K).multiply(LS);
var A = RKLS.multiply(C).rename('soil_loss').updateMask(landMask).clip(catchment);

// 6. Intervention factors
//    Contour structures (bunds on cropland, trenches on hill land):
//    P by slope, from the contouring table in Wischmeier & Smith (1978),
//    USDA Agriculture Handbook 537. Conservative: bunds usually do better.
var Pcontour = ee.Image(0.6)
  .where(slopePct.gt(2), 0.5)
  .where(slopePct.gt(8), 0.6)
  .where(slopePct.gt(12), 0.7)
  .where(slopePct.gt(16), 0.8)
  .where(slopePct.gt(20), 0.9)
  .where(slopePct.gt(25), 1.0);   // contouring stops working on very steep slopes

//    Revegetation: cover improves to the C of moderate scrub/grass (NDVI 0.45).
//    Pixels already greener than that keep their own C. Takes 2–3 seasons.
var targetNdvi = 0.45;
var Ctarget = Math.exp(-2 * targetNdvi / (1 - targetNdvi));
var Creveg = C.min(Ctarget);

var Abunds = A.multiply(Pcontour);
var Areveg = RKLS.multiply(Creveg).updateMask(landMask).clip(catchment);
var Aboth = Areveg.multiply(Pcontour);

// 7. Per-zone sums in hectares and tonnes/year
var ha = ee.Image.pixelArea().divide(1e4);
var bare = ndvi.lt(0.2);
var sums = ee.Image.cat([
  ha.rename('land_ha'),
  crop.multiply(ha).rename('crop_ha'),
  hill.multiply(ha).rename('hill_ha'),
  tree.multiply(ha).rename('tree_ha'),
  built.multiply(ha).rename('built_ha'),
  crop.multiply(bare).multiply(ha).rename('crop_bare_ha'),
  A.multiply(ha).rename('t_total'),
  A.multiply(crop).multiply(ha).rename('t_crop'),
  Abunds.multiply(crop).multiply(ha).rename('t_crop_bunds'),
  A.multiply(hill).multiply(ha).rename('t_hill'),
  Abunds.multiply(hill).multiply(ha).rename('t_hill_trench'),
  Areveg.multiply(hill).multiply(ha).rename('t_hill_reveg'),
  Aboth.multiply(hill).multiply(ha).rename('t_hill_both')
]).updateMask(A.mask());

var means = A.addBands(slopeDeg).addBands(ndvi).addBands(annualRain)
  .addBands(bare.rename('bare_frac'))
  .updateMask(A.mask());

var stats = sums.reduceRegions({
  collection: zones, reducer: ee.Reducer.sum(), scale: 30, tileScale: 4
});
stats = means.reduceRegions({
  collection: stats, reducer: ee.Reducer.mean(), scale: 30, tileScale: 4
});

// 8. Derived fields: fractions, risk class, zone type
//    Ravine zones can't be detected from these averages; they were
//    identified by checking satellite imagery (Z08: active ravines).
var ravineZones = ee.List(['Z08']);

var minA = ee.Number(stats.aggregate_min('soil_loss'));
var maxA = ee.Number(stats.aggregate_max('soil_loss'));

stats = stats.map(function (f) {
  var a = ee.Number(f.get('soil_loss'));
  var landHa = ee.Number(f.get('land_ha'));
  var cropHa = ee.Number(f.get('crop_ha'));
  var cropFrac = cropHa.divide(landHa);
  var slope = ee.Number(f.get('slope_deg'));

  var cls = ee.String(ee.Algorithms.If(a.lt(5), 'Slight',
            ee.Algorithms.If(a.lt(10), 'Moderate',
            ee.Algorithms.If(a.lt(20), 'High',
            ee.Algorithms.If(a.lt(40), 'Very high', 'Severe')))));
  var type = ee.String(ee.Algorithms.If(ravineZones.contains(f.get('zone_id')), 'ravine',
             ee.Algorithms.If(slope.gte(5.5), 'hill',
             ee.Algorithms.If(cropFrac.gte(0.35).and(slope.lt(4.5)), 'valley_farm', 'mixed'))));

  var tTotal = ee.Number(f.get('t_total'));
  return f.set({
    land_km2: landHa.divide(100),
    crop_frac: cropFrac,
    hill_frac: ee.Number(f.get('hill_ha')).divide(landHa),
    tree_frac: ee.Number(f.get('tree_ha')).divide(landHa),
    built_frac: ee.Number(f.get('built_ha')).divide(landHa),
    crop_bare_frac: ee.Number(f.get('crop_bare_ha')).divide(cropHa.max(1)),
    t_other: tTotal.subtract(f.get('t_crop')).subtract(f.get('t_hill')),
    risk_class: cls,
    risk_score: a.subtract(minA).divide(maxA.subtract(minA)).multiply(100).round(),
    zone_type: type
  });
});

// 9. Map
var typeColors = ee.Dictionary({hill: 'd95f02', ravine: '7570b3', valley_farm: '1b9e77', mixed: 'bbbbbb'});
var typed = stats.map(function (f) {
  return f.set('style', {color: '000000', width: 1,
    fillColor: ee.String(typeColors.get(f.get('zone_type'))).cat('99')});
});
Map.addLayer(crop.selfMask().clip(catchment), {palette: ['f1c40f']}, 'Cropland (WorldCover)', false);
Map.addLayer(hill.selfMask().clip(catchment), {palette: ['8e5b3a']}, 'Hill land (shrub/grass/bare)', false);
Map.addLayer(typed.style({styleProperty: 'style'}), {}, 'Zone type');

// 10. Console summary
var columns = [
  'zone_id', 'zone_type', 'risk_class', 'risk_score', 'soil_loss',
  'slope_deg', 'ndvi', 'bare_frac', 'rain_mm',
  'area_km2', 'land_km2', 'crop_frac', 'hill_frac', 'tree_frac', 'built_frac', 'crop_bare_frac',
  't_total', 't_crop', 't_crop_bunds', 't_hill', 't_hill_trench', 't_hill_reveg', 't_hill_both', 't_other'
];
print('Catchment soil loss, baseline (t/yr):', stats.aggregate_sum('t_total'));
print('  from cropland:', stats.aggregate_sum('t_crop'));
print('  from hill land:', stats.aggregate_sum('t_hill'));
print('  from other land:', stats.aggregate_sum('t_other'));
print('Catchment, all fixes everywhere (t/yr):',
  ee.Number(stats.aggregate_sum('t_crop_bunds'))
    .add(stats.aggregate_sum('t_hill_both'))
    .add(stats.aggregate_sum('t_other')));
print('Zones:', stats.select(columns).sort('soil_loss', false));

// 11. Export as GeoJSON to Google Drive (for the app)
//     (After running, open the Tasks tab and click RUN on this export.)
Export.table.toDrive({
  collection: stats.select(columns),
  description: 'jaisamand_zone_scenarios',
  fileFormat: 'GeoJSON'
});
