#' Distance to the nearest water
#'
#' Returns the distance from each cell center to the nearest water feature.
#' Cells inside a waterbody polygon are 0.
#'
#' Water data are only as complete as the source. Medium-resolution NHD
#' misses many small headwater streams, so check the features against a
#' topographic map or the high-resolution NHD before relying on distances.
#'
#' @inheritParams exposure_along_direction
#' @param water A `SpatVector` or `sf` object of streams (lines) and/or
#'   waterbodies (polygons), or a list of them. It must use the same CRS as
#'   `dem`.
#'
#' @return Single-layer `SpatRaster` named `water_distance`, in meters, on
#'   the grid of `dem`.
#'
#' @family suitability layers
#' @seealso [water_score()] and [water_exclusion()] use the result.
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' gpkg <- system.file("extdata", "vesuvius_water.gpkg", package = "leeward")
#' water <- list(
#'   terra::vect(gpkg, layer = "flowlines"),
#'   terra::vect(gpkg, layer = "waterbodies")
#' )
#' terra::plot(water_distance(dem, water))
#' @export
water_distance <- function(dem, water) {
  check_dem(dem)
  water <- as_water_list(water, dem)

  template <- terra::rast(dem)
  distances <- lapply(water, function(w) terra::distance(template, w))
  out <- if (length(distances) == 1) {
    distances[[1]]
  } else {
    terra::app(terra::rast(distances), min)
  }
  out <- terra::mask(out, dem)
  names(out) <- "water_distance"
  out
}

#' Score water access
#'
#' Returns a 0--1 score from distance to water: 0 within `setback`, 1 just
#' outside it, falling linearly to 0 at `reach`. Combine it with
#' [water_exclusion()]. The score alone cannot keep a weighted suitability
#' sum from ranking a cell inside the setback highly.
#'
#' @param distance `SpatRaster` from [water_distance()].
#' @param setback Minimum distance from water, in meters. The default 61 m
#'   (200 ft) is the common Leave No Trace guideline. It is not a universal
#'   rule: setbacks vary by district and season. Check local regulations.
#' @param reach Distance in meters beyond which water access no longer adds
#'   value.
#'
#' @return Single-layer `SpatRaster` named `water_score`.
#'
#' @section Hazards:
#' Low ground near streams is where flash floods run, and sheltered hollows
#' often hold intermittent channels that look dry. Never camp in a channel
#' or on a low bank during unsettled weather. Results are candidate areas
#' to scout, not safe campsites.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' gpkg <- system.file("extdata", "vesuvius_water.gpkg", package = "leeward")
#' d <- water_distance(dem, terra::vect(gpkg, layer = "flowlines"))
#' terra::plot(water_score(d, setback = 61, reach = 800))
#' @export
water_score <- function(distance, setback = 61, reach = 800) {
  check_distance(distance)
  check_breakpoints(setback, reach)

  score <- terra::clamp((reach - distance) / (reach - setback), 0, 1)
  score <- terra::ifel(distance < setback, 0, score)
  names(score) <- "water_score"
  score
}

#' Exclude cells too close to water
#'
#' Returns a hard exclusion mask: `TRUE` for cells within `setback` of water
#' or inside a waterbody.
#'
#' @inheritParams water_score
#'
#' @return Single-layer logical `SpatRaster` named `water_exclusion`;
#'   `TRUE` means excluded.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' gpkg <- system.file("extdata", "vesuvius_water.gpkg", package = "leeward")
#' d <- water_distance(dem, terra::vect(gpkg, layer = "flowlines"))
#' terra::plot(water_exclusion(d))
#' @export
water_exclusion <- function(distance, setback = 61) {
  check_distance(distance)
  ok <- is.numeric(setback) && length(setback) == 1 &&
    is.finite(setback) && setback >= 0
  if (!ok) {
    cli::cli_abort("{.arg setback} must be a single non-negative number.")
  }

  out <- distance < setback
  names(out) <- "water_exclusion"
  out
}

as_water_list <- function(water, dem, call = rlang::caller_env()) {
  if (inherits(water, c("SpatVector", "sf", "sfc"))) {
    water <- list(water)
  }
  if (!is.list(water) || length(water) == 0) {
    cli::cli_abort(
      "{.arg water} must be a {.cls SpatVector}, an {.cls sf} object, or a
       list of them.",
      call = call
    )
  }
  lapply(water, function(w) {
    w <- as_spat_vector(w, arg = "water", call = call)
    check_same_crs(w, dem, arg = "water", call = call)
  })
}

check_distance <- function(distance, call = rlang::caller_env()) {
  ok <- inherits(distance, "SpatRaster") && terra::nlyr(distance) == 1
  if (!ok) {
    cli::cli_abort(
      c(
        "{.arg distance} must be a single-layer {.cls SpatRaster}.",
        "i" = "Create one with {.fn water_distance}."
      ),
      call = call
    )
  }
  invisible(distance)
}
