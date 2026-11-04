#' Distance-limited topographic exposure (TOPEX)
#'
#' Returns the sum of skyline angles in `n_directions` equally spaced
#' directions, each the maximum angle from the cell to terrain within
#' `max_dist`. Higher values are more sheltered. Unlike [wind_exposure()],
#' every direction is weighted equally, so no wind record is needed.
#'
#' The skyline angle in one direction is the same quantity as Sx from
#' [exposure_along_direction()]. With `declination = TRUE`, angles below
#' horizontal count as negative, as in the DEM-based variants tested by
#' Quine and White (1998). With `declination = FALSE`, they are set to 0,
#' as in traditional field TOPEX. The default `max_dist` of 500 m was the
#' best-performing distance limit in that study (upland Britain).
#'
#' Cells whose search line leaves the DEM in any direction return `NA`.
#'
#' @inheritParams exposure_along_direction
#' @param max_dist Search distance in metres.
#' @param n_directions Number of directions, a whole number >= 4, starting at
#'   north and evenly spaced clockwise.
#' @param declination If `TRUE`, negative angles count; if `FALSE`, they
#'   are set to 0.
#'
#' @return Single-layer `SpatRaster` named `topex`, in degrees, on the grid
#'   of `dem`.
#'
#' @references
#' Quine, C. P., & White, I. M. S. (1998). The potential of distance-limited
#' topex in the prediction of site windiness. *Forestry*, 71(4), 325--332.
#' \doi{10.1093/forestry/71.4.325}
#'
#' Ruel, J.-C., Pin, D., Spacek, L., Cooper, K., & Benoit, R. (1997). The
#' estimation of wind exposure for windthrow hazard rating: comparison
#' between Strongblow, MC2, Topex and a wind tunnel study. *Forestry*,
#' 70(3), 253--266. \doi{10.1093/forestry/70.3.253}
#'
#' @examples
#' dem <- terra::rast(system.file("extdata", "ridge.tif", package = "leeward"))
#' tx <- topex(dem, max_dist = 300)
#' terra::plot(tx)
#' @export
topex <- function(dem, max_dist = 500, n_directions = 8, declination = TRUE) {
  check_dem(dem)
  check_whole_number(n_directions, min = 4)
  max_dist <- resolve_max_dist(dem, max_dist, is_missing = FALSE)
  stopifnot(rlang::is_bool(declination))

  z <- terra::as.matrix(dem, wide = TRUE)
  res <- terra::res(dem)
  directions <- (seq_len(n_directions) - 1) * 360 / n_directions
  skyline <- lapply(directions, function(d) sx_matrix(z, res, d, max_dist))
  if (!declination) {
    skyline <- lapply(skyline, pmax, 0)
  }

  out <- terra::rast(dem)
  terra::values(out) <- as.vector(t(Reduce(`+`, skyline)))
  names(out) <- "topex"
  out
}
