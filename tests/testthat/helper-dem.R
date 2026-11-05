dem_from_matrix <- function(z, res = 10) {
  terra::rast(
    z,
    extent = terra::ext(0, ncol(z) * res, 0, nrow(z) * res),
    crs = "EPSG:32617"
  )
}

sx_values <- function(r) terra::as.matrix(r, wide = TRUE)

tilted_plane <- function(drop_per_cell, facing = c("east", "south")) {
  facing <- match.arg(facing)
  z <- if (facing == "east") {
    matrix(rep(100 - seq_len(7) * drop_per_cell, each = 7), 7)
  } else {
    matrix(rep(100 - seq_len(7) * drop_per_cell, times = 7), 7)
  }
  dem_from_matrix(z)
}

water_grid <- function() dem_from_matrix(matrix(0, 20, 20))

stream <- function() {
  terra::vect("LINESTRING (100 0, 100 200)", crs = "EPSG:32617")
}

pond <- function() {
  terra::vect(
    "POLYGON ((20 20, 60 20, 60 60, 20 60, 20 20))",
    crs = "EPSG:32617"
  )
}
