// ============================================================
// JalRakshak — 02_erosion
// RUSLE soil-loss estimate for each zone of the Jaisamand catchment
// A = R × K × LS × C × P   (tonnes per hectare per year)
// ============================================================

// 0. Zones saved by 01_catchment
var zones = ee.FeatureCollection('projects/jal-rakshak-511510/assets/jaisamand_zones');
var catchment = zones.geometry();
Map.centerObject(zones, 10);

// 1. R — rainfall erosivity, from CHIRPS (10-year average annual rainfall)
//    R = 79 + 0.363 × P, a formula commonly used for India
var annualRain = ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')
  .filterDate('2015-01-01', '2025-01-01')
  .sum().divide(10).rename('rain_mm');
var R = annualRain.multiply(0.363).add(79).rename('R');

// 2. K — soil erodibility, from OpenLandMap topsoil texture (Williams/EPIC method)
var sand = ee.Image('OpenLandMap/SOL/SOL_SAND-WFRACTION_USDA-3A1A1A_M/v02').select('b0').toFloat();
var clay = ee.Image('OpenLandMap/SOL/SOL_CLAY-WFRACTION_USDA-3A1A1A_M/v02').select('b0').toFloat();
var oc = ee.Image('OpenLandMap/SOL/SOL_ORGANIC-CARBON_USDA-6A1C_M/v02').select('b0')
  .toFloat().multiply(0.5);                     // stored as 5 g/kg units → percent
var silt = ee.Image(100).toFloat().subtract(sand).subtract(clay);

var fSand = sand.multiply(-0.256).multiply(ee.Image(1).subtract(silt.divide(100))).exp().multiply(0.3).add(0.2);
var fClaySilt = silt.divide(clay.add(silt)).pow(0.3);
var fOrgC = ee.Image(1).subtract(oc.multiply(0.25).divide(oc.add(oc.multiply(-2.95).add(3.72).exp())));
var sn1 = ee.Image(1).subtract(sand.divide(100));
var fHiSand = ee.Image(1).subtract(sn1.multiply(0.7).divide(sn1.add(sn1.multiply(22.9).add(-5.51).exp())));
var K = fSand.multiply(fClaySilt).multiply(fOrgC).multiply(fHiSand).multiply(0.1317).rename('K');

// 3. LS — slope length and steepness, from SRTM 30 m elevation
//    Simplified: fixed slope length of 50 m (refine later with flow accumulation)
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

// 4. C — cover management, from pre-monsoon Sentinel-2 NDVI (bare-soil season)
//    C = exp(-2 × NDVI / (1 − NDVI))
var s2 = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(catchment)
  .filterDate('2026-04-01', '2026-06-10')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 10))
  .median();
var ndvi = s2.normalizedDifference(['B8', 'B4']).rename('ndvi');
var C = ndvi.multiply(-2).divide(ee.Image(1).subtract(ndvi)).exp().clamp(0, 1).rename('C');

// 5. P — support practice. 1 = no conservation measures (current baseline)
var P = ee.Image(1).rename('P');

// 6. Mask out water (lake and ponds) so zones are scored on land only
var landMask = ee.Image('JRC/GSW1_4/GlobalSurfaceWater').select('occurrence').unmask(0).lt(50);

// 7. Soil loss
var A = R.multiply(K).multiply(LS).multiply(C).multiply(P)
  .rename('soil_loss').updateMask(landMask).clip(catchment);

// 8. Per-zone statistics
var bare = ndvi.lt(0.2).rename('bare_frac');
var stack = A.addBands(slopeDeg).addBands(ndvi).addBands(annualRain).addBands(bare)
  .updateMask(landMask);

var zoneStats = stack.reduceRegions({
  collection: zones,
  reducer: ee.Reducer.mean(),
  scale: 30,
  tileScale: 4
});

var minA = ee.Number(zoneStats.aggregate_min('soil_loss'));
var maxA = ee.Number(zoneStats.aggregate_max('soil_loss'));

zoneStats = zoneStats.map(function (f) {
  var a = ee.Number(f.get('soil_loss'));
  var cls = ee.String(ee.Algorithms.If(a.lt(5), 'Slight',
            ee.Algorithms.If(a.lt(10), 'Moderate',
            ee.Algorithms.If(a.lt(20), 'High',
            ee.Algorithms.If(a.lt(40), 'Very high', 'Severe')))));
  var col = ee.String(ee.Algorithms.If(a.lt(5), '1a9850',
            ee.Algorithms.If(a.lt(10), 'a6d96a',
            ee.Algorithms.If(a.lt(20), 'fdae61',
            ee.Algorithms.If(a.lt(40), 'f46d43', 'a50026')))));
  var score = a.subtract(minA).divide(maxA.subtract(minA)).multiply(100).round();
  return f.set({
    risk_class: cls,
    risk_score: score,
    style: {color: '000000', width: 1, fillColor: col.cat('B3')}
  });
});

// 9. Map
var lossVis = {min: 0, max: 40, palette: ['1a9850', 'fee08b', 'f46d43', 'a50026']};
Map.addLayer(A, lossVis, 'Soil loss (t/ha/yr)', false);
Map.addLayer(zoneStats.style({styleProperty: 'style'}), {}, 'Zone risk');

// 10. Console summary
var columns = ['zone_id', 'risk_class', 'risk_score', 'soil_loss', 'slope_deg', 'ndvi', 'bare_frac', 'rain_mm'];
print('Catchment mean soil loss (t/ha/yr):',
  A.reduceRegion({reducer: ee.Reducer.mean(), geometry: catchment, scale: 30, maxPixels: 1e10, tileScale: 4}));
print('Zones ranked by soil loss:', zoneStats.select(columns).sort('soil_loss', false));

// 11. Export zone results as GeoJSON to Google Drive (for the app)
//     (After running, open the Tasks tab and click RUN on this export.)
Export.table.toDrive({
  collection: zoneStats.select(columns),
  description: 'jaisamand_zone_risk',
  fileFormat: 'GeoJSON'
});