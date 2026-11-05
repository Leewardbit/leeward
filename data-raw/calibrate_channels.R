# Choose the default `min_area` for height_above_channel(): for each
# candidate, the share of mapped NHD flowline length within 20 m of a
# derived channel (recall), and the derived channel length.
pkgload::load_all()

dem <- terra::rast("inst/extdata/vesuvius_dem.tif")
gpkg <- "inst/extdata/vesuvius_water.gpkg"
flowlines <- terra::vect(gpkg, layer = "flowlines")
flowlines <- terra::crop(flowlines, terra::ext(dem) - 50)
points <- terra::as.points(terra::densify(flowlines, 10))
area <- contributing_area(dem)

for (min_area in c(0.25, 0.5, 1, 2, 4, 8, 16) * 1e4) {
  channel <- terra::ifel(area >= min_area, 1, NA)
  recall <- mean(terra::extract(terra::distance(channel), points)[, 2] <= 20)
  length_km <- terra::global(!is.na(channel), "sum")[1, 1] * 10 / 1000
  cat(sprintf(
    "%5.2f ha: recall %.2f, derived %3.0f km (mapped %.1f km)\n",
    min_area / 1e4, recall, length_km, sum(terra::perim(flowlines)) / 1000
  ))
}
