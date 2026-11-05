#' Score wind shelter
#'
#' Returns a 0--1 score from a shelter index: 0 at or below `exposed`, 1 at
#' or above `sheltered`, and linear in between. Higher input means more
#' sheltered, so the score rises with it.
#'
#' The default breakpoints suit Sx in degrees from [wind_exposure()] or
#' [exposure_along_direction()]. They are a judgment call, not published
#' thresholds. Sx at 0 or below means the upwind horizon is level or
#' falls away. Around Lake Vesuvius, mean Sx was 13.7 degrees in valleys
#' and 2.2 degrees on ridges. For [topex()], which sums `n_directions`
#' angles, scale both breakpoints by about `n_directions`.
#'
#' @param shelter Single-layer `SpatRaster` of a shelter index, such as Sx
#'   or TOPEX, in degrees. Higher values are more sheltered.
#' @param exposed Value at or below which the score is 0.
#' @param sheltered Value at or above which the score is 1.
#'
#' @return Single-layer `SpatRaster` named `shelter_score`.
#'
#' @section Hazards:
#' Sheltered ground collects cold air on clear, calm nights and often sits
#' in drainages that flood. Combine this score with [channel_exclusion()].
#' Exposed ridges carry lightning risk.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(system.file("extdata", "ridge.tif", package = "leeward"))
#' freq <- wind_direction_freq(c(250, 260, 270, 280, 90), n_sectors = 8)
#' sx <- wind_exposure(dem, freq, max_dist = 300)
#' terra::plot(shelter_score(sx))
#'
#' # TOPEX over 8 directions: scale the breakpoints by 8
#' tx <- topex(dem, max_dist = 300)
#' terra::plot(shelter_score(tx, exposed = 0, sheltered = 80))
#' @export
shelter_score <- function(shelter, exposed = 0, sheltered = 10) {
  ok <- inherits(shelter, "SpatRaster") && terra::nlyr(shelter) == 1
  if (!ok) {
    cli::cli_abort(c(
      "{.arg shelter} must be a single-layer {.cls SpatRaster}.",
      "i" = "Create one with {.fn wind_exposure} or {.fn topex}."
    ))
  }
  ok <- is.numeric(exposed) && is.numeric(sheltered) &&
    length(exposed) == 1 && length(sheltered) == 1 &&
    is.finite(exposed) && is.finite(sheltered) && exposed < sheltered
  if (!ok) {
    cli::cli_abort(
      "{.arg exposed} and {.arg sheltered} must be single numbers with
       {.arg exposed} < {.arg sheltered}."
    )
  }

  score <- terra::clamp((shelter - exposed) / (sheltered - exposed), 0, 1)
  names(score) <- "shelter_score"
  score
}
