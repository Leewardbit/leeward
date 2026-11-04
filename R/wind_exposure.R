#' Frequency-weighted terrain shelter
#'
#' Computes [exposure_along_direction()] at each sector center and combines
#' the results, weighting each by how often the wind blows from that sector.
#' Sectors with zero frequency are skipped. If `wind_freq` has speed classes,
#' frequencies are summed over classes.
#'
#' A cell is `NA` if its upwind line leaves the DEM in any weighted
#' direction, so the output loses a band up to `max_dist` wide on each side
#' the wind comes from. Clip the DEM with a buffer of at least `max_dist`
#' around the area of interest.
#'
#' @inheritParams exposure_along_direction
#' @param wind_freq Data frame from [wind_direction_freq()], or any data
#'   frame with `sector_center` (degrees) and `frequency` columns.
#'
#' @return Single-layer `SpatRaster` named `sx`: the weighted mean Sx in
#'   degrees. Positive values are sheltered from the prevailing winds.
#'
#' @examples
#' dem <- terra::rast(system.file("extdata", "ridge.tif", package = "leeward"))
#' freq <- wind_direction_freq(c(250, 260, 270, 280, 90), n_sectors = 8)
#' sx <- wind_exposure(dem, freq, max_dist = 300)
#' terra::plot(sx)
#' @export
wind_exposure <- function(dem, wind_freq, max_dist) {
  check_dem(dem)
  check_wind_freq(wind_freq)
  max_dist <- resolve_max_dist(dem, max_dist, missing(max_dist))

  weights <- tapply(wind_freq$frequency, wind_freq$sector_center, sum)
  weights <- weights[weights > 0]
  weights <- weights / sum(weights)
  directions <- as.numeric(names(weights))

  z <- terra::as.matrix(dem, wide = TRUE)
  res <- terra::res(dem)
  sx <- Reduce(
    `+`,
    Map(
      function(direction, w) w * sx_matrix(z, res, direction, max_dist),
      directions,
      weights
    )
  )

  out <- terra::rast(dem)
  terra::values(out) <- as.vector(t(sx))
  names(out) <- "sx"
  out
}

check_wind_freq <- function(wind_freq, call = rlang::caller_env()) {
  needed <- c("sector_center", "frequency")
  if (!is.data.frame(wind_freq) || !all(needed %in% names(wind_freq))) {
    cli::cli_abort(
      c(
        "{.arg wind_freq} must be a data frame with columns {.field {needed}}.",
        "i" = "Create one with {.fn wind_direction_freq}."
      ),
      call = call
    )
  }
  freq <- wind_freq$frequency
  ok <- !anyNA(freq) && all(freq >= 0) && sum(freq) > 0
  if (!ok) {
    cli::cli_abort(
      "{.field frequency} must be non-negative with a positive sum.",
      call = call
    )
  }
  invisible(wind_freq)
}
