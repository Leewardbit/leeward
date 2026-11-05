#' Suggest an upwind search distance from terrain relief
#'
#' Returns a starting value for `max_dist` based on the DEM's median local
#' relief: the elevation range within about 1 km of each cell. These tiers
#' are a rule of thumb for campsite-scale shelter, not a calibrated result.
#'
#' | Median local relief | Terrain             | Suggested `max_dist` |
#' |---------------------|---------------------|----------------------|
#' | < 100 m             | rolling, low hills  | 200 m                |
#' | 100--300 m          | dissected hills     | 300 m                |
#' | > 300 m             | mountains           | 500 m                |
#'
#' A better value is the typical distance from where you would camp to the
#' nearest upwind ridgeline or tree line that blocks the wind. Measure a few
#' on a topographic map of your area and use that.
#'
#' @inheritParams exposure_along_direction
#'
#' @return A list with `max_dist` (meters), `relief` (median local relief,
#'   meters), and `terrain` (tier label).
#'
#' @examples
#' dem <- terra::rast(system.file("extdata", "ridge.tif", package = "leeward"))
#' suggest_max_dist(dem)
#' @export
suggest_max_dist <- function(dem) {
  check_dem(dem)
  relief <- median_local_relief(dem)
  tier <- findInterval(relief, c(100, 300)) + 1
  list(
    max_dist = c(200, 300, 500)[tier],
    relief = relief,
    terrain = c("rolling", "dissected hills", "mountains")[tier]
  )
}

median_local_relief <- function(dem, window = 1000) {
  # Aggregating to ~100 m first keeps a 1 km focal window small on fine DEMs.
  fact <- max(1, floor(100 / min(terra::res(dem))))
  coarse_max <- terra::aggregate(dem, fact = fact, fun = "max", na.rm = TRUE)
  coarse_min <- terra::aggregate(dem, fact = fact, fun = "min", na.rm = TRUE)
  n <- 2 * max(1, round(window / 2 / min(terra::res(coarse_max)))) + 1
  if (n > min(dim(coarse_max)[1:2])) {
    return(diff(range(terra::values(dem), na.rm = TRUE)))
  }
  hi <- terra::focal(coarse_max, w = n, fun = "max", na.rm = TRUE)
  lo <- terra::focal(coarse_min, w = n, fun = "min", na.rm = TRUE)
  stats::median(terra::values(hi - lo), na.rm = TRUE)
}

resolve_max_dist <- function(dem, max_dist, is_missing,
                             call = rlang::caller_env()) {
  if (is_missing) {
    s <- suggest_max_dist(dem)
    cli::cli_inform(
      c(
        "Using {.code max_dist = {s$max_dist}} m ({s$terrain}; median local
         relief {round(s$relief)} m).",
        "i" = "Set {.arg max_dist} to the typical distance from a campsite to
               the nearest upwind ridgeline in your area.",
        "i" = "Rough guide: 200 m rolling hills, 300 m dissected hills, 500 m
               mountains. See {.fn leeward::suggest_max_dist}."
      ),
      class = "leeward_max_dist_default",
      .frequency = "regularly",
      .frequency_id = "leeward_max_dist_default"
    )
    max_dist <- s$max_dist
  }
  step <- min(terra::res(dem))
  diagonal <- sqrt(sum((dim(dem)[2:1] * terra::res(dem))^2))
  ok <- is.numeric(max_dist) && length(max_dist) == 1 &&
    is.finite(max_dist) && max_dist >= step
  if (!ok) {
    cli::cli_abort(
      "{.arg max_dist} must be a single number >= the DEM resolution
       ({step} m), not {.val {max_dist}}.",
      call = call
    )
  }
  if (max_dist > diagonal) {
    cli::cli_abort(
      c(
        "{.arg max_dist} ({max_dist} m) exceeds the DEM diagonal
         ({round(diagonal)} m), so every cell would be {.val NA}.",
        "i" = "Use a larger DEM or a smaller {.arg max_dist}."
      ),
      call = call
    )
  }
  max_dist
}
