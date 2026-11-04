#' Upwind terrain shelter for one wind direction
#'
#' Computes the Winstral et al. (2002) Sx index: for each cell, the maximum
#' angle from the cell to any upwind cell within `max_dist`. Positive values
#' are sheltered (terrain rises upwind); negative values are exposed.
#'
#' The upwind line is sampled at one-cell steps using nearest-neighbor
#' lookup. Cells whose search line leaves the DEM, or whose own elevation is
#' `NA`, return `NA`. `NA` cells along the line are skipped.
#'
#' @param dem Single-layer `SpatRaster` of elevation in meters, in a
#'   projected CRS with meter units.
#' @param direction Wind direction in degrees the wind blows **from**,
#'   0 = north, clockwise.
#' @param max_dist Upwind search distance in meters. If missing, chosen by
#'   [suggest_max_dist()] with a message.
#'
#' @return Single-layer `SpatRaster` named `sx`, in degrees, on the grid of
#'   `dem`.
#'
#' @references
#' Winstral, A., Elder, K., & Davis, R. E. (2002). Spatial snow modeling of
#' wind-redistributed snow using terrain-based parameters. *Journal of
#' Hydrometeorology*, 3(5), 524--538.
#' \doi{10.1175/1525-7541(2002)003<0524:SSMOWR>2.0.CO;2}
#'
#' @seealso [wind_exposure()] to combine directions using a wind climatology.
#'
#' @examples
#' dem <- terra::rast(system.file("extdata", "ridge.tif", package = "leeward"))
#' sx <- exposure_along_direction(dem, direction = 270, max_dist = 300)
#' terra::plot(sx)
#' @export
exposure_along_direction <- function(dem, direction, max_dist) {
  check_dem(dem)
  check_direction(direction)
  max_dist <- resolve_max_dist(dem, max_dist, missing(max_dist))

  z <- terra::as.matrix(dem, wide = TRUE)
  sx <- sx_matrix(z, terra::res(dem), direction, max_dist)

  out <- terra::rast(dem)
  terra::values(out) <- as.vector(t(sx))
  names(out) <- "sx"
  out
}

sx_matrix <- function(z, res, direction, max_dist) {
  offsets <- upwind_offsets(direction, max_dist, res)
  nr <- nrow(z)
  nc <- ncol(z)
  sx <- matrix(-Inf, nr, nc)

  for (k in seq_len(nrow(offsets))) {
    upwind <- shift_matrix(z, offsets$drow[k], offsets$dcol[k])
    angle <- atan((upwind - z) / offsets$dist[k]) * 180 / pi
    sx <- pmax(sx, angle, na.rm = TRUE)
  }

  last <- offsets[nrow(offsets), ]
  sx[is.na(shift_matrix(!is.na(z), last$drow, last$dcol))] <- NA
  sx[is.na(z) | is.infinite(sx)] <- NA
  sx
}

upwind_offsets <- function(direction, max_dist, res) {
  theta <- direction * pi / 180
  step <- min(res)
  dist <- seq(step, max_dist, by = step)
  # Rows increase southward, so a northerly source is a negative row offset.
  drow <- round(-cos(theta) * dist / res[2])
  dcol <- round(sin(theta) * dist / res[1])
  offsets <- unique(data.frame(drow = drow, dcol = dcol))
  offsets <- offsets[offsets$drow != 0 | offsets$dcol != 0, ]
  offsets$dist <- sqrt((offsets$drow * res[2])^2 + (offsets$dcol * res[1])^2)
  offsets[order(offsets$dist), ]
}

shift_matrix <- function(m, drow, dcol) {
  nr <- nrow(m)
  nc <- ncol(m)
  out <- matrix(NA, nr, nc)
  src_rows <- seq_len(nr) + drow
  src_cols <- seq_len(nc) + dcol
  ok_rows <- src_rows >= 1 & src_rows <= nr
  ok_cols <- src_cols >= 1 & src_cols <= nc
  out[ok_rows, ok_cols] <- m[src_rows[ok_rows], src_cols[ok_cols]]
  out
}

check_dem <- function(dem, call = rlang::caller_env()) {
  if (!inherits(dem, "SpatRaster")) {
    cli::cli_abort(
      "{.arg dem} must be a {.cls SpatRaster}, not {.obj_type_friendly {dem}}.",
      call = call
    )
  }
  if (terra::nlyr(dem) != 1) {
    cli::cli_abort(
      "{.arg dem} must have one layer, not {terra::nlyr(dem)}.",
      call = call
    )
  }
  if (terra::is.lonlat(dem)) {
    cli::cli_abort(
      c(
        "{.arg dem} must use a projected CRS with meter units.",
        "i" = "Reproject with {.code terra::project(dem, \"EPSG:<utm zone>\")}."
      ),
      call = call
    )
  }
  invisible(dem)
}

check_direction <- function(direction, call = rlang::caller_env()) {
  ok <- is.numeric(direction) && length(direction) == 1 && is.finite(direction)
  if (!ok) {
    cli::cli_abort(
      "{.arg direction} must be a single finite number of degrees,
       not {.val {direction}}.",
      call = call
    )
  }
  invisible(direction)
}
