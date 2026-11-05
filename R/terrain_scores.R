#' Score terrain flatness
#'
#' Returns a 0--1 score from slope: 1 at or below `flat` degrees, 0 at or
#' above `steep` degrees, and linear in between.
#'
#' A 10--30 m DEM shows gentle *areas*, not individual tent pads. Slope is
#' averaged over each cell, so a flat-scoring cell can still contain roots,
#' rocks, or a pitch too steep to sleep on. 1 m lidar (USGS 3DEP) resolves
#' pad-scale terrain.
#'
#' @inheritParams exposure_along_direction
#' @param flat Slope in degrees at or below which the score is 1.
#' @param steep Slope in degrees at or above which the score is 0.
#'
#' @return Single-layer `SpatRaster` named `flatness_score`. The outer
#'   row and column are `NA`.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' terra::plot(flatness_score(dem))
#' @export
flatness_score <- function(dem, flat = 5, steep = 15) {
  check_dem(dem)
  check_breakpoints(flat, steep)

  slope <- terra::terrain(dem, "slope", unit = "degrees")
  score <- terra::clamp((steep - slope) / (steep - flat), 0, 1)
  names(score) <- "flatness_score"
  score
}

#' Score slope aspect against a preferred facing direction
#'
#' Returns a 0--1 score that is 1 on slopes facing `preferred_aspect`, 0 on
#' slopes facing the opposite way, and 0.5 on flat ground. The effect ramps up
#' with slope and reaches full strength at `full_effect_slope`, because
#' aspect has little meaning on near-flat ground.
#'
#' The score is `0.5 + 0.5 * cos(aspect - preferred_aspect) * w`, where
#' `w = min(slope / full_effect_slope, 1)`.
#'
#' @inheritParams exposure_along_direction
#' @param preferred_aspect Direction the slope **faces** (downhill), in
#'   degrees clockwise from north. This is not a wind direction. The default,
#'   135 (southeast), gets morning sun and afternoon shade in the northern
#'   hemisphere.
#' @param full_effect_slope Slope in degrees at and above which aspect has its
#'   full effect.
#'
#' @return Single-layer `SpatRaster` named `aspect_score`. The outer row
#'   and column are `NA`.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' terra::plot(aspect_score(dem, preferred_aspect = 135))
#' @export
aspect_score <- function(dem, preferred_aspect = 135, full_effect_slope = 10) {
  check_dem(dem)
  check_direction(preferred_aspect)
  ok <- is.numeric(full_effect_slope) && length(full_effect_slope) == 1 &&
    is.finite(full_effect_slope) && full_effect_slope > 0
  if (!ok) {
    cli::cli_abort(
      "{.arg full_effect_slope} must be a single positive number of degrees."
    )
  }

  terr <- terra::terrain(dem, c("slope", "aspect"), unit = "radians")
  weight <- terra::clamp(terr$slope / (full_effect_slope * pi / 180), 0, 1)
  score <- 0.5 + 0.5 * cos(terr$aspect - preferred_aspect * pi / 180) * weight
  names(score) <- "aspect_score"
  score
}

check_breakpoints <- function(low, high,
                              low_arg = rlang::caller_arg(low),
                              high_arg = rlang::caller_arg(high),
                              call = rlang::caller_env()) {
  ok <- is.numeric(low) && is.numeric(high) &&
    length(low) == 1 && length(high) == 1 &&
    is.finite(low) && is.finite(high) && low >= 0 && low < high
  if (!ok) {
    cli::cli_abort(
      "{.arg {low_arg}} and {.arg {high_arg}} must be single numbers with
       0 <= {.arg {low_arg}} < {.arg {high_arg}}.",
      call = call
    )
  }
  invisible()
}
