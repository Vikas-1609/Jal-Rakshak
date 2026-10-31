// ============================================================
// JalRakshak — 01_catchment
// Jaisamand (Dhebar) Lake catchment, split into natural zones
// ============================================================

// 1. Outlet point (inside the lake; verified to capture the full lake)
var outlet = ee.Geometry.Point([73.95, 24.25]);

// 2. Trace every small sub-basin that drains into the lake
var lv12 = ee.FeatureCollection('WWF/HydroSHEDS/v1/Basins/hybas_12');
var ids = lv12.filterBounds(outlet).aggregate_array('HYBAS_ID');
for (var i = 0; i < 25; i++) {
  ids = ids.cat(
    lv12.filter(ee.Filter.inList('NEXT_DOWN', ids)).aggregate_array('HYBAS_ID')
  ).distinct();
}
var subBasins = lv12.filter(ee.Filter.inList('HYBAS_ID', ids)).sort('HYBAS_ID');

// 3. Give each sub-basin a simple zone name (Z01, Z02, ...) and its area
var basinList = subBasins.toList(100);
var zones = ee.FeatureCollection(
  ee.List.sequence(0, basinList.size().subtract(1)).map(function (i) {
    var f = ee.Feature(basinList.get(i));
    var n = ee.Number(i).add(1).toInt();
    return f.set({
      zone_id: ee.String('Z').cat(n.format('%02d')),
      area_km2: f.geometry().area(1).divide(1e6)
    });
  })
);
var outline = zones.union(10);

// 4. Pre-monsoon Sentinel-2 image (bare-soil season), clipped to the catchment
var s2 = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(outline)
  .filterDate('2026-04-01', '2026-06-10')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 10))
  .median()
  .clip(outline);

// 5. Map
Map.centerObject(outline, 10);
Map.addLayer(s2, {bands: ['B4', 'B3', 'B2'], min: 0, max: 3000}, 'Sentinel-2 (pre-monsoon)');
Map.addLayer(zones.style({color: 'yellow', fillColor: '00000000', width: 1}), {}, 'Zones');
Map.addLayer(outline.style({color: 'red', fillColor: '00000000', width: 3}), {}, 'Catchment boundary');

// 6. Console summary
print('Number of zones:', zones.size());
print('Total catchment area (km²):', outline.geometry().area(1).divide(1e6));
print('Zones:', zones.select(['zone_id', 'area_km2']));

// 7. Save zones as an asset so later scripts can load them instantly
//    (After running, open the Tasks tab and click RUN on this export.)
Export.table.toAsset({
  collection: zones.select(['zone_id', 'area_km2', 'HYBAS_ID']),
  description: 'jaisamand_zones',
  assetId: 'projects/jal-rakshak-511510/assets/jaisamand_zones'
});