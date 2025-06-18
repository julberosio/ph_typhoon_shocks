// Load Philippine provinces from GAUL Level 2
// Alternative is to upload a shapefile but GEE has problems with files >100 MB

var provinces = ee.FeatureCollection("FAO/GAUL/2015/level2")
  .filter(ee.Filter.eq('ADM0_NAME', 'Philippines'))
  .map(function(f) {
    return f.set('province', f.get('ADM2_NAME'));
  });

// Load VIIRS monthly nighttime lights (2012–2024)

var viirs = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG")
  .select("avg_rad")
  .filterDate('2012-01-01', '2024-12-31')
  .map(function(img) {
    return img.set({
      'year': img.date().get('year'),
      'month': img.date().get('month')
    });
  });

// Aggregate lights by province per image

var monthlyStats = viirs.map(function(img) {
  var reduced = img.reduceRegions({
    collection: provinces,
    reducer: ee.Reducer.mean(),
    scale: 500
  });

  return reduced.map(function(f) {
    return ee.Feature(null, {
      'province': f.get('province'),
      'year': img.get('year'),
      'month': img.get('month'),
      'mean_lights': f.get('mean')
    });
  });
}).flatten();

// 4. Export clean CSV (we don't need all info, we only need the panel)

Export.table.toDrive({
  collection: monthlyStats,
  description: 'PH_VIIRS_Monthly_2012_2024_Provinces',
  fileFormat: 'CSV'
});
