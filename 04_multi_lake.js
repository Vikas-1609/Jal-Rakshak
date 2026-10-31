// ============================================================
// JalRakshak — 04_multi_lake
// Catchment zones + RUSLE scenarios for several Aravalli lakes in one run.
// Combines 01_catchment and 03_scenarios; exports one GeoJSON where every
// zone carries lake_id / lake_name. Same model as 03 (incl. forest C fix).
// ============================================================

// 0. Lakes. `point` must be ON the lake's water, near the dam / outflow.
//    Coordinates for new lakes are approximate: check the Console
//    ("point on water") and the map outlines before trusting results.
//
//    Small rural tanks need two extra options:
//    - radius: 0 uses only the basin under the point. The default search
//      radius can catch a bigger river basin passing nearby.
//    - gridKm: cut the catchment into square zones this many km wide. One
//      HydroSHEDS level-12 basin (often 50-150 km²) can hold a whole small
//      catchment, which would leave a single zone.
//    - catchment (optional): the catchment outline, [[lon, lat], ...]. Use
//      it if the traced basin is much bigger than the real catchment
//      (compare catchment_km2 in the Console).
//
// Outlines traced from SRTM (D8 flow on a filled DEM) draining into the
// JRC water body under each lake point. The traced HydroSHEDS basins were
// 350 km² (Badi) and 198 km² (Siliserh), pulling in neighbouring streams.
var CATCHMENTS = {
  // 17.7 km²; published figure ~19 km².
  badi: [[73.5864, 24.6380], [73.5919, 24.6345], [73.5919, 24.6305], [73.5947, 24.6255], [73.5998, 24.6245], [73.6002, 24.6264], [73.6015, 24.6264], [73.6056, 24.6242], [73.6091, 24.6245], [73.6136, 24.6292], [73.6149, 24.6377], [73.6228, 24.6370], [73.6245, 24.6189], [73.6290, 24.6161], [73.6297, 24.6058], [73.6225, 24.6055], [73.6201, 24.6121], [73.6156, 24.6105], [73.6091, 24.6108], [73.6033, 24.6146], [73.5984, 24.6068], [73.5974, 24.6083], [73.5940, 24.6077], [73.5912, 24.6011], [73.5827, 24.5974], [73.5796, 24.5921], [73.5724, 24.5943], [73.5669, 24.5940], [73.5641, 24.6142], [73.5665, 24.6230], [73.5679, 24.6249], [73.5772, 24.6286], [73.5799, 24.6274], [73.5850, 24.6286], [73.5864, 24.6380]],
  // 134 km².
  siliserh: [[76.4961, 27.7060], [76.4992, 27.7027], [76.4992, 27.6990], [76.5019, 27.6945], [76.5006, 27.6866], [76.5026, 27.6857], [76.5050, 27.6869], [76.5088, 27.6844], [76.5122, 27.6847], [76.5153, 27.6762], [76.5143, 27.6704], [76.5109, 27.6677], [76.5054, 27.6565], [76.5098, 27.6546], [76.5088, 27.6522], [76.5102, 27.6513], [76.5143, 27.6543], [76.5181, 27.6522], [76.5157, 27.6489], [76.5098, 27.6455], [76.5105, 27.6394], [76.5060, 27.6331], [76.5054, 27.6279], [76.5023, 27.6264], [76.5036, 27.6203], [76.5057, 27.6200], [76.5047, 27.6130], [76.5067, 27.6060], [76.5050, 27.6017], [76.5060, 27.5917], [76.5036, 27.5844], [76.5081, 27.5813], [76.5109, 27.5835], [76.5109, 27.5877], [76.5163, 27.5883], [76.5198, 27.5826], [76.5236, 27.5838], [76.5246, 27.5819], [76.5301, 27.5804], [76.5308, 27.5786], [76.5417, 27.5765], [76.5486, 27.5719], [76.5500, 27.5737], [76.5545, 27.5746], [76.5610, 27.5704], [76.5579, 27.5667], [76.5524, 27.5640], [76.5462, 27.5564], [76.5465, 27.5481], [76.5442, 27.5463], [76.5459, 27.5342], [76.5448, 27.5244], [76.5397, 27.5202], [76.5400, 27.5180], [76.5297, 27.5174], [76.5301, 27.5192], [76.5263, 27.5229], [76.5229, 27.5223], [76.5167, 27.5265], [76.5102, 27.5223], [76.5105, 27.5183], [76.5084, 27.5165], [76.5091, 27.5092], [76.5067, 27.5055], [76.5033, 27.5086], [76.5006, 27.5058], [76.4968, 27.5095], [76.4933, 27.5086], [76.4896, 27.5104], [76.4834, 27.5098], [76.4789, 27.5022], [76.4755, 27.5004], [76.4734, 27.5034], [76.4703, 27.5034], [76.4690, 27.5052], [76.4621, 27.5040], [76.4556, 27.5052], [76.4549, 27.5040], [76.4518, 27.5058], [76.4511, 27.5074], [76.4528, 27.5095], [76.4504, 27.5110], [76.4487, 27.5165], [76.4521, 27.5177], [76.4532, 27.5159], [76.4552, 27.5159], [76.4563, 27.5214], [76.4583, 27.5220], [76.4573, 27.5265], [76.4590, 27.5363], [76.4570, 27.5381], [76.4570, 27.5411], [76.4587, 27.5424], [76.4624, 27.5415], [76.4659, 27.5448], [76.4700, 27.5433], [76.4717, 27.5460], [76.4690, 27.5521], [76.4645, 27.5570], [76.4669, 27.5634], [76.4642, 27.5655], [76.4648, 27.5670], [76.4594, 27.5789], [76.4604, 27.5804], [76.4532, 27.5929], [76.4497, 27.5941], [76.4480, 27.5978], [76.4518, 27.6011], [76.4490, 27.6172], [76.4518, 27.6367], [76.4518, 27.6616], [76.4556, 27.6689], [76.4556, 27.6747], [76.4611, 27.6768], [76.4600, 27.6802], [76.4621, 27.6869], [76.4707, 27.6987], [76.4796, 27.6954], [76.4913, 27.7003], [76.4961, 27.7060]]
};

var LAKES = [
  {id: 'jaisamand', name: 'Jaisamand Lake', point: [73.95, 24.25]},
  {id: 'rajsamand', name: 'Rajsamand Lake', point: [73.88, 25.07]},
  {id: 'jawai',     name: 'Jawai Dam',      point: [73.15, 25.08]},
  // Badi village, ~12 km NW of Udaipur; ~19 km² catchment of Aravalli hills.
  {id: 'badi',      name: 'Badi Lake',      point: [73.622, 24.616], radius: 0, gridKm: 1.5,
   catchment: CATCHMENTS.badi},
  // Paitpur, Alwar; Ramsar site since Dec 2025. Feeds a Ruparel tributary.
  {id: 'siliserh',  name: 'Siliserh Lake',  point: [76.529, 27.529], radius: 0, gridKm: 3,
   catchment: CATCHMENTS.siliserh}
];
// Search radius around each point for the lake's outlet basin (metres).
var OUTLET_RADIUS = 1500;
// Grid zones smaller than this share of a full cell (edge slivers) are
// dropped; keep it low so little land is lost.
var MIN_CELL_SHARE = 0.05;

// Ravines can't be detected from zone averages; tag them after checking
// satellite imagery. Zone numbers can shift if a catchment changes.
var RAVINE_ZONES = {jaisamand: ['Z08']};

var lv12 = ee.FeatureCollection('WWF/HydroSHEDS/v1/Basins/hybas_12');
var water = ee.Image('JRC/GSW1_4/GlobalSurfaceWater').select('occurrence').unmask(0);

// 1. Zones per lake: trace every sub-basin upstream of the outlet basin
function tracedBasins(lake) {
  var pt = ee.Geometry.Point(lake.point);
  var radius = lake.radius === undefined ? OUTLET_RADIUS : lake.radius;
  // Most downstream basin near the point = the one with the largest upstream area
  var outlet = lv12.filterBounds(radius ? pt.buffer(radius) : pt).sort('UP_AREA', false).first();
  var ids = ee.List([outlet.get('HYBAS_ID')]);
  for (var i = 0; i < 30; i++) {
    ids = ids.cat(lv12.filter(ee.Filter.inList('NEXT_DOWN', ids)).aggregate_array('HYBAS_ID')).distinct();
  }
  return lv12.filter(ee.Filter.inList('HYBAS_ID', ids)).sort('HYBAS_ID');
}

// Small catchments: square grid cells clipped to the catchment.
// UTM 43N covers all these lakes (72-78°E).
function gridCells(lake, basins) {
  var area = lake.catchment ? ee.Geometry.Polygon([lake.catchment]) : basins.geometry();
  var cellM = lake.gridKm * 1000;
  return area.coveringGrid(ee.Projection('EPSG:32643'), cellM)
    .map(function (cell) {
      var g = cell.geometry().intersection(area, 1);
      return ee.Feature(g, {cell_m2: g.area(1)});
    })
    .filter(ee.Filter.gte('cell_m2', cellM * cellM * MIN_CELL_SHARE));
}

function lakeZones(lake) {
  var basins = tracedBasins(lake);
  var parts = (lake.gridKm ? gridCells(lake, basins) : basins).toList(500);
  return ee.FeatureCollection(ee.List.sequence(0, parts.size().subtract(1)).map(function (i) {
    var f = ee.Feature(parts.get(i));
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
var outlineColors = ['ffff00', '00ffff', 'ff00ff', 'ff8800', '00ff00'];
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
