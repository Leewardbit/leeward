# Builds inst/extdata/vesuvius_water.gpkg from the USGS National Map NHD
# (high resolution) service. Requires network access. Not run during checks.

# The National Map service often takes minutes to answer.
options(timeout = 600)

dem <- terra::rast("inst/extdata/vesuvius_dem.tif")
bbox <- paste(as.vector(terra::ext(dem))[c(1, 3, 2, 4)], collapse = ",")

nhd_query <- function(layer, fields) {
  url <- paste0(
    "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer/",
    layer, "/query?geometry=", bbox,
    "&geometryType=esriGeometryEnvelope&inSR=32617&outSR=32617",
    "&spatialRel=esriSpatialRelIntersects&where=1%3D1",
    "&outFields=", paste(fields, collapse = ","), "&f=geojson"
  )
  path <- tempfile(fileext = ".geojson")
  utils::download.file(url, path, quiet = TRUE, mode = "wb")
  terra::vect(path)
}

extent <- terra::as.polygons(terra::ext(dem), crs = terra::crs(dem))

# Layer 6: flowlines (large scale). fcode 46003 = intermittent,
# 46006 = perennial, 55800 = artificial path through a waterbody (dropped,
# the waterbody polygon covers it).
flow <- terra::crop(nhd_query(6, c("gnis_name", "fcode")), extent)
flow <- flow[flow$fcode %in% c(46003, 46006), ]
flowlines <- flow[, "gnis_name"]
flowlines$flow <- ifelse(flow$fcode == 46006, "perennial", "intermittent")

# Layer 12: waterbodies (large scale).
wb <- terra::crop(nhd_query(12, c("gnis_name", "fcode")), extent)
names(wb) <- tolower(names(wb))
waterbodies <- wb[, "gnis_name"]

path <- "inst/extdata/vesuvius_water.gpkg"
unlink(path)
terra::writeVector(flowlines, path, layer = "flowlines")
terra::writeVector(waterbodies, path, layer = "waterbodies", insert = TRUE)
