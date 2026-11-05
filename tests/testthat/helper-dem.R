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

const <- function(value, n = 3) dem_from_matrix(matrix(value, n, n))

no_exclusion <- function() const(0) == 1

cell <- function(r, i) unname(terra::values(r)[i, 1])

grid_4x4 <- function() {
  terra::rast(
    nrows = 4, ncols = 4, xmin = 0, xmax = 40, ymin = 0, ymax = 40,
    crs = "EPSG:32617", vals = 1
  )
}

square <- function(size) {
  terra::vect(
    sprintf("POLYGON ((0 0, %1$s 0, %1$s %1$s, 0 %1$s, 0 0))", size),
    crs = "EPSG:32617"
  )
}
