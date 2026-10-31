// ============================================================
// JalRakshak — 04_multi_lake
// Catchment zones + RUSLE scenarios for several Aravalli lakes in one run.
// Combines 01_catchment and 03_scenarios; exports one GeoJSON where every
// zone carries lake_id / lake_name. Same model as 03 (incl. forest C fix).
// ============================================================

// 0. Lakes. `point` must be ON the lake's water, near the dam / outflow.
//    Coordinates for new lakes are approximate: check the Console
//    ("point on water") and the map outlines before trusting results.
var LAKES = [
  {id: 'jaisamand', name: 'Jaisamand Lake',  point: [73.95, 24.25]},
  {id: 'rajsamand', name: 'Rajsamand Lake',  point: [73.88, 25.07]},
  {id: 'udaisagar', name: 'Udai Sagar Lake', point: [73.82, 24.57]},
  {id: 'jawai',     name: 'Jawai Dam',       point: [73.15, 25.08]}
];
// Search radius around each point for the lake's outlet basin (metres).
var OUTLET_RADIUS = 1500;

// Ravines can't be detected from zone averages; tag them after checking
// satellite imagery. Zone numbers can shift if a catchment changes.
var RAVINE_ZONES = {jaisamand: ['Z08']};

var lv12 = ee.FeatureCollection('WWF/HydroSHEDS/v1/Basins/hybas_12');
var water = ee.Image('JRC/GSW1_4/GlobalSurfaceWater').select('occurrence').unmask(0);

// 1. Zones per lake: trace every sub-basin upstream of the outlet basin
function lakeZones(lake) {
  var pt = ee.Geometry.Point(lake.point);
  // Most downstream basin near the point = the one with the largest upstream area
  var outlet = lv12.filterBounds(pt.buffer(OUTLET_RADIUS)).sort('UP_AREA', false).first();
  var ids = ee.List([outlet.get('HYBAS_ID')]);
  for (var i = 0; i < 30; i++) {
    ids = ids.cat(lv12.filter(ee.Filter.inList('NEXT_DOWN', ids)).aggregate_array('HYBAS_ID')).distinct();
  }
  var basins = lv12.filter(ee.Filter.inList('HYBAS_ID', ids)).sort('HYBAS_ID').toList(200);
  return ee.FeatureCollection(ee.List.sequence(0, basins.size().subtract(1)).map(function (i) {
    var f = ee.Feature(basins.get(i));
    return f.set({
      lake_id: lake.id,
      lake_name: lake.name,
      zone_id: ee.String('Z').cat(ee.Number(i).add(1).toInt().format('%02d')),
      area_km2: f.geometry().area(1).divide(1e6)
    });
  }));
}

var perLake = LAKES.map(lakeZones);
var zones = ee.FeatureCollection(perLake).flatten();
var region = zones.geometry();

// 2. RUSLE factors — identical to 03_scenarios
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
  .filterBounds(region)
  .filterDate('2026-04-01', '2026-06-10')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 10))
  .median();
var ndvi = s2.normalizedDifference(['B8', 'B4']).rename('ndvi');
var Cdry = ndvi.multiply(-2).divide(ee.Image(1).subtract(ndvi)).exp().clamp(0, 1);

var lc = ee.ImageCollection('ESA/WorldCover/v200').first();
var crop = lc.eq(40).rename('crop');
var hill = lc.eq(20).or(lc.eq(30)).or(lc.eq(60)).rename('hill');
var tree = lc.eq(10).rename('tree');
var built = lc.eq(50).rename('built');

// Forest C from post-monsoon NDVI (dry deciduous forest is leafless pre-monsoon)
var s2wet = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(region)
  .filterDate('2025-09-15', '2025-11-15')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20))
  .median();
var ndviWet = s2wet.normalizedDifference(['B8', 'B4']);
var Cwet = ndviWet.multiply(-2).divide(ee.Image(1).subtract(ndviWet)).exp().clamp(0, 1);
var C = Cdry.where(tree, Cwet.unmask(Cdry)).rename('C');

var landMask = water.lt(50);

// 3. Baseline and scenario soil loss (see 03_scenarios for the P/C choices)
var RKLS = R.multiply(K).multiply(LS);
var A = RKLS.multiply(C).rename('soil_loss').updateMask(landMask);

var Pcontour = ee.Image(0.6)
  .where(slopePct.gt(2), 0.5)
  .where(slopePct.gt(8), 0.6)
  .where(slopePct.gt(12), 0.7)
  .where(slopePct.gt(16), 0.8)
  .where(slopePct.gt(20), 0.9)
  .where(slopePct.gt(25), 1.0);
var targetNdvi = 0.45;
var Ctarget = Math.exp(-2 * targetNdvi / (1 - targetNdvi));
var Abunds = A.multiply(Pcontour);
var Areveg = RKLS.multiply(C.min(Ctarget)).updateMask(landMask);
var Aboth = Areveg.multiply(Pcontour);

// 4. Per-zone sums and means (all lakes in one pass)
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

var stats = sums.reduceRegions({collection: zones, reducer: ee.Reducer.sum(), scale: 30, tileScale: 8});
stats = means.reduceRegions({collection: stats, reducer: ee.Reducer.mean(), scale: 30, tileScale: 8});

// 5. Derived fields. risk_score is a rank within each lake's own catchment.
function finishLake(lake) {
  var lakeStats = stats.filter(ee.Filter.eq('lake_id', lake.id));
  var minA = ee.Number(lakeStats.aggregate_min('soil_loss'));
  var maxA = ee.Number(lakeStats.aggregate_max('soil_loss'));
  var ravines = ee.List(RAVINE_ZONES[lake.id] || []);
  return lakeStats.map(function (f) {
    var a = ee.Number(f.get('soil_loss'));
    var landHa = ee.Number(f.get('land_ha'));
    var cropHa = ee.Number(f.get('crop_ha'));
    var cropFrac = cropHa.divide(landHa);
    var slope = ee.Number(f.get('slope_deg'));
    var cls = ee.String(ee.Algorithms.If(a.lt(5), 'Slight',
              ee.Algorithms.If(a.lt(10), 'Moderate',
              ee.Algorithms.If(a.lt(20), 'High',
              ee.Algorithms.If(a.lt(40), 'Very high', 'Severe')))));
    var type = ee.String(ee.Algorithms.If(ravines.contains(f.get('zone_id')), 'ravine',
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
}
var result = ee.FeatureCollection(LAKES.map(finishLake)).flatten();

// 6. Map: one outline colour per lake, plus the lake points
var outlineColors = ['ffff00', '00ffff', 'ff00ff', 'ff8800'];
Map.centerObject(region, 8);
LAKES.forEach(function (lake, i) {
  Map.addLayer(perLake[i].style({color: outlineColors[i], fillColor: '00000000', width: 2}), {}, lake.name);
  Map.addLayer(ee.Geometry.Point(lake.point), {color: 'ff0000'}, lake.name + ' point');
});

// 7. Console: quick checks per lake (cheap; full numbers go to the export)
LAKES.forEach(function (lake, i) {
  var pt = ee.Geometry.Point(lake.point);
  print(lake.name, {
    point_on_water: water.reduceRegion(ee.Reducer.first(), pt, 30).get('occurrence'),
    zones: perLake[i].size(),
    catchment_km2: perLake[i].geometry().area(1).divide(1e6)
  });
});

// 8. Export as GeoJSON to Google Drive (Tasks tab → RUN)
var columns = [
  'lake_id', 'lake_name', 'zone_id', 'zone_type', 'risk_class', 'risk_score', 'soil_loss',
  'slope_deg', 'ndvi', 'bare_frac', 'rain_mm',
  'area_km2', 'land_km2', 'crop_frac', 'hill_frac', 'tree_frac', 'built_frac', 'crop_bare_frac',
  't_total', 't_crop', 't_crop_bunds', 't_hill', 't_hill_trench', 't_hill_reveg', 't_hill_both', 't_other'
];
Export.table.toDrive({
  collection: result.select(columns),
  description: 'aravalli_lake_scenarios',
  fileFormat: 'GeoJSON'
});
