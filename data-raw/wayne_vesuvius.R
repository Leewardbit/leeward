# Builds inst/extdata/vesuvius_dem.tif and inst/extdata/hts_wind.csv.
# Requires network access, elevatr, riem, and sf. Not run during checks.

aoi_lonlat <- terra::vect(
  data.frame(lon = -82.625, lat = 38.605),
  geom = c("lon", "lat"),
  crs = "EPSG:4326"
)
aoi <- terra::buffer(terra::project(aoi_lonlat, "EPSG:32617"), width = 2000)

# elevatr wants an sf/sp object; z = 13 is about 12 m at this latitude.
dem_raw <- elevatr::get_elev_raster(
  sf::st_as_sf(aoi), z = 13, clip = "bbox", src = "aws"
)
dem <- terra::project(
  terra::rast(dem_raw),
  terra::rast(terra::ext(aoi), resolution = 10, crs = "EPSG:32617"),
  method = "bilinear"
)
names(dem) <- "elevation"
terra::writeRaster(
  dem, "inst/extdata/vesuvius_dem.tif",
  overwrite = TRUE, datatype = "FLT4S", gdal = "COMPRESS=DEFLATE"
)

wind <- riem::riem_measures(
  station = "HTS", date_start = "2021-01-01", date_end = "2025-12-31"
)
# drct = 0 with sknt = 0 is calm, not a north wind; VRB reports are NA.
wind <- wind[!is.na(wind$drct) & !is.na(wind$sknt) & wind$sknt > 0, ]
# Keep routine hourly METARs (:51 at HTS) so specials don't overweight storms.
wind <- wind[format(wind$valid, "%M") == "51", ]
utils::write.csv(
  data.frame(
    month = as.integer(format(wind$valid, "%m")),
    drct = wind$drct,
    sknt = wind$sknt
  ),
  "inst/extdata/hts_wind.csv",
  row.names = FALSE
)
