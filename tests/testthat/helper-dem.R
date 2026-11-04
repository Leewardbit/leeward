dem_from_matrix <- function(z, res = 10) {
  terra::rast(
    z,
    extent = terra::ext(0, ncol(z) * res, 0, nrow(z) * res),
    crs = "EPSG:32617"
  )
}

sx_values <- function(r) terra::as.matrix(r, wide = TRUE)
