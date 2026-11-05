#' Exclude land where camping is not allowed
#'
#' Returns a hard exclusion mask from polygons you supply: `TRUE` outside
#' every `allowed` polygon and inside or touching any `prohibited` polygon.
#' Both rules lean toward exclusion. A cell counts as allowed only if its
#' center falls inside an allowed polygon. A cell is prohibited if any part
#' of it touches a prohibited polygon.
#'
#' This is a filter built from your data, not a statement of the law.
#' Land status comes from sources such as PAD-US, USFS Motor Vehicle Use
#' Maps, and wilderness boundaries, which can be out of date. Camping rules
#' vary by district and season, and fire restrictions change. Check with
#' the managing agency before you go.
#'
#' @inheritParams exposure_along_direction
#' @param allowed Optional `SpatVector` or `sf` polygons where camping is
#'   allowed. Cells whose centers fall outside them are excluded.
#' @param prohibited Optional `SpatVector` or `sf` polygons where camping is
#'   not allowed, such as developed recreation areas or closures. Cells
#'   touching them are excluded.
#'
#' @return Single-layer logical `SpatRaster` named `land_exclusion` on the
#'   grid of `dem`; `TRUE` means excluded. Cells that are `NA` in `dem` are
#'   `NA`.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' # A made-up closure around the lake's north arm
#' closure <- terra::vect(
#'   "POLYGON ((358000 4275000, 359000 4275000, 359000 4276200,
#'              358000 4276200, 358000 4275000))",
#'   crs = terra::crs(dem)
#' )
#' terra::plot(land_exclusion(dem, prohibited = closure))
#' @export
land_exclusion <- function(dem, allowed = NULL, prohibited = NULL) {
  check_dem(dem)
  if (is.null(allowed) && is.null(prohibited)) {
    cli::cli_abort("Supply {.arg allowed}, {.arg prohibited}, or both.")
  }

  template <- terra::rast(dem)
  out <- terra::ifel(is.na(dem), NA, FALSE)
  if (!is.null(allowed)) {
    allowed <- check_polygons(allowed, dem)
    inside <- terra::rasterize(allowed, template, background = 0)
    out <- out | inside == 0
  }
  if (!is.null(prohibited)) {
    prohibited <- check_polygons(prohibited, dem)
    touching <- terra::rasterize(
      prohibited, template,
      background = 0, touches = TRUE
    )
    out <- out | touching == 1
  }
  out <- terra::mask(out, dem)
  names(out) <- "land_exclusion"
  out
}

check_polygons <- function(x, dem,
                           arg = rlang::caller_arg(x),
                           call = rlang::caller_env()) {
  force(arg)
  x <- as_spat_vector(x, arg = arg, call = call)
  if (terra::geomtype(x) != "polygons") {
    cli::cli_abort(
      "{.arg {arg}} must contain polygons, not {terra::geomtype(x)}.",
      call = call
    )
  }
  check_same_crs(x, dem, arg = arg, call = call)
}
