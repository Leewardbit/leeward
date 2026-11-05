# Soils (SSURGO) and tree canopy (NLCD TCC 2021) for the Lake Vesuvius DEM.
# Needs network access and soilDB. Writes inst/extdata/vesuvius_soils.gpkg
# and inst/extdata/vesuvius_canopy.tif.
options(timeout = 600)

dem <- terra::rast("inst/extdata/vesuvius_dem.tif")
# Buffer past the DEM so no edge cell is left without a soil polygon: a
# missing class would count as excluded in camp_suitability().
area <- terra::as.polygons(terra::ext(dem), crs = terra::crs(dem))
area <- terra::buffer(area, 300)

# SSURGO map unit polygons, then map-unit aggregate attributes ----------
polygons <- soilDB::SDA_spatialQuery(
  terra::project(area, "EPSG:4326"),
  what = "mupolygon", geomIntersection = TRUE
)
keys <- paste(unique(polygons$mukey), collapse = ",")
attributes <- soilDB::SDA_query(sprintf(
  "SELECT mukey, muname, drclassdcd, flodfreqdcd, flodfreqmax
   FROM muaggatt WHERE mukey IN (%s)", keys
))
soils <- terra::merge(polygons, attributes, by = "mukey")
soils <- terra::project(soils, terra::crs(dem))
columns <- c("mukey", "muname", "drclassdcd", "flodfreqdcd", "flodfreqmax")
soils <- soils[, columns]

covered <- terra::rasterize(soils, terra::rast(dem), field = 1)
stopifnot(terra::global(is.na(covered), "sum")[1, 1] == 0)

terra::writeVector(
  soils, "inst/extdata/vesuvius_soils.gpkg",
  layer = "mapunits", overwrite = TRUE
)

# NLCD tree canopy cover 2021 (v2021-4) from the MRLC WCS ---------------
# Native grid: 30 m, EPSG:5070. Values 0-100 percent; 254 = non-processing
# area, 255 = background.
bbox <- terra::ext(terra::project(area, "EPSG:5070"))
url <- paste0(
  "https://www.mrlc.gov/geoserver/mrlc_download/wcs?service=WCS",
  "&version=2.0.1&request=GetCoverage",
  "&coverageId=mrlc_download__nlcd_tcc_conus_2021_v2021-4",
  sprintf("&subset=X(%.0f,%.0f)", bbox[1], bbox[2]),
  sprintf("&subset=Y(%.0f,%.0f)", bbox[3], bbox[4]),
  "&format=image/geotiff"
)
tmp <- tempfile(fileext = ".tif")
utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
canopy <- terra::rast(tmp)
terra::coltab(canopy) <- NULL
# The WCS tags 0 as NoData, but in NLCD TCC 0 is a real value (0 percent
# cover: water, fields, clearings). Restore it, then drop the true no-data
# codes.
canopy <- terra::subst(canopy, NA, 0)
canopy <- terra::classify(canopy, cbind(c(254, 255), NA))
names(canopy) <- "canopy"

# Keep the native 30 m cells, but in the DEM's UTM CRS so the example data
# share one CRS. Nearest neighbor keeps the original percent values.
canopy <- terra::project(canopy, terra::crs(dem), res = 30, method = "near")
terra::writeRaster(
  canopy, "inst/extdata/vesuvius_canopy.tif",
  datatype = "INT1U", overwrite = TRUE, gdal = "COMPRESS=DEFLATE"
)
