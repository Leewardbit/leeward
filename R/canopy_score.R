#' Score tree canopy cover
#'
#' Returns a 0--1 score from percent tree canopy cover. With
#' `prefer = "cover"`, the score rises from 0 at `open` percent to 1 at
#' `closed` percent, for wind shelter and shade. With `prefer = "open"`, it
#' runs the other way, for views, dry ground, and fewer trees overhead.
#'
#' NLCD Tree Canopy Cover (USDA Forest Service, 30 m, 0--100 percent) is
#' one source. Project it to the DEM grid first, e.g.
#' `terra::project(canopy, dem, method = "bilinear")`. The result is still
#' 30 m data: the finer grid does not add detail.
#'
#' @param canopy Single-layer `SpatRaster` of canopy cover in percent,
#'   0--100, on the grid of the other layers.
#' @param open,closed Percent cover where the score reaches its low and high
#'   ends. The defaults are a judgment call.
#' @param prefer `"cover"` to favor canopy, or `"open"` to favor open
#'   ground.
#'
#' @return Single-layer `SpatRaster` named `canopy_score`.
#'
#' @section Hazards:
#' Canopy is where falling limbs and dead trees ("widowmakers") are, and a
#' canopy raster cannot show which trees are dead. Favoring cover favors
#' that hazard. Look up before you pitch a tent, especially after storms,
#' fire, or insect kill.
#'
#' @references
#' USDA Forest Service (2023). USFS NLCD Percent Tree Canopy CONUS v2021-4.
#' Sioux Falls, SD. <https://www.mrlc.gov/data>
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' canopy <- terra::rast(
#'   system.file("extdata", "vesuvius_canopy.tif", package = "leeward")
#' )
#' canopy <- terra::project(canopy, dem, method = "bilinear")
#' terra::plot(canopy_score(canopy, prefer = "cover"))
#' @export
canopy_score <- function(canopy, open = 20, closed = 70,
                         prefer = c("cover", "open")) {
  prefer <- rlang::arg_match(prefer)
  ok <- inherits(canopy, "SpatRaster") && terra::nlyr(canopy) == 1
  if (!ok) {
    cli::cli_abort("{.arg canopy} must be a single-layer {.cls SpatRaster}.")
  }
  ok <- is.numeric(open) && is.numeric(closed) &&
    length(open) == 1 && length(closed) == 1 &&
    is.finite(open) && is.finite(closed) &&
    open >= 0 && closed <= 100 && open < closed
  if (!ok) {
    cli::cli_abort(
      "{.arg open} and {.arg closed} must be percentages with
       0 <= {.arg open} < {.arg closed} <= 100."
    )
  }
  range <- terra::minmax(canopy, compute = TRUE)[, 1]
  if (!all(is.na(range)) && (range[1] < 0 || range[2] > 100)) {
    cli::cli_abort(c(
      "{.arg canopy} must be percent cover, 0--100, but ranges from
       {range[1]} to {range[2]}.",
      "i" = "NLCD uses 254 and 255 for no data. Set them to {.code NA}
             first, e.g. {.code terra::classify(canopy, cbind(c(254, 255),
             NA))}."
    ))
  }

  score <- terra::clamp((canopy - open) / (closed - open), 0, 1)
  if (prefer == "open") {
    score <- 1 - score
  }
  names(score) <- "canopy_score"
  score
}
