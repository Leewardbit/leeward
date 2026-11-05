#' Score soil drainage
#'
#' Returns a 0--1 score from SSURGO drainage class: well-drained ground
#' scores high, wet ground low. Each cell takes the class of the soil
#' polygon its center falls in.
#'
#' Get soil polygons with drainage classes from SSURGO, for example with
#' `soilDB::SDA_spatialQuery()` and the `muaggatt` table (column
#' `drclassdcd`, the dominant condition). See `data-raw/` in the package
#' source for a worked example.
#'
#' @inheritParams exposure_along_direction
#' @param soils `SpatVector` or `sf` polygons of soil map units, in the CRS
#'   of `dem`.
#' @param column Name of the column holding the drainage class.
#' @param scores Named numbers in 0--1, one per drainage class. The
#'   defaults are a judgment call. Classes in the data but missing from
#'   `scores` are an error, so nothing is scored silently.
#'
#' @return Single-layer `SpatRaster` named `drainage_score` on the grid of
#'   `dem`. Cells with no class (water, disturbed land, or no polygon) are
#'   `NA`, which makes their suitability unknown.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' soils <- terra::vect(
#'   system.file("extdata", "vesuvius_soils.gpkg", package = "leeward")
#' )
#' terra::plot(drainage_score(dem, soils))
#' @export
drainage_score <- function(dem, soils, column = "drclassdcd",
                           scores = c(
                             "Excessively drained" = 0.8,
                             "Somewhat excessively drained" = 0.9,
                             "Well drained" = 1,
                             "Moderately well drained" = 0.8,
                             "Somewhat poorly drained" = 0.4,
                             "Poorly drained" = 0.1,
                             "Very poorly drained" = 0,
                             "Subaqueous" = 0
                           )) {
  check_dem(dem)
  soils <- check_soils(soils, dem, column)
  ok <- is.numeric(scores) && !is.null(names(scores)) &&
    all(is.finite(scores)) && all(scores >= 0 & scores <= 1)
  if (!ok) {
    cli::cli_abort("{.arg scores} must be named numbers from 0 to 1.")
  }
  check_known_classes(
    soils[[column, drop = TRUE]], names(scores),
    hint = "Add the missing classes to {.arg scores}, or recode the column."
  )

  soils$value <- unname(scores[soils[[column, drop = TRUE]]])
  out <- terra::rasterize(soils, terra::rast(dem), field = "value")
  out <- terra::mask(out, dem)
  names(out) <- "drainage_score"
  out
}

# nolint start: line_length_linter. The NRCS URL cannot be wrapped.
#' Exclude soils that flood
#'
#' Returns a hard exclusion mask from SSURGO flooding frequency: `TRUE`
#' where a soil map unit floods at least as often as `exclude` allows.
#' Cells touching a flooding map unit are excluded. Cells with no flooding
#' class are `NA`, which [camp_suitability()] treats as excluded.
#'
#' Use the `muaggatt` column `flodfreqmax`, the most frequent class of any
#' component in the map unit, rather than the dominant condition
#' (`flodfreqdcd`): a small flood-prone component, such as a strip along a
#' creek, is hidden in the dominant condition.
#'
#' NRCS flooding frequency classes (Soil Survey Staff):
#' * None: nearly 0% chance of flooding in any year.
#' * Very rare: under 1% in any year.
#' * Rare: 1--5% in any year.
#' * Occasional: 5--50% in any year.
#' * Frequent: over 50% in any year, but under 50% in all months.
#' * Very frequent: over 50% in all months of any year.
#' * Common: an obsolete class covering occasional and frequent.
#'
#' @inheritParams drainage_score
#' @param column Name of the column holding the flooding frequency class.
#' @param exclude Classes to exclude. The default, Occasional and wetter (at
#'   least a 5% chance in any year), is a judgment call. A flash flood can
#'   also reach soils rated rare.
#'
#' @return Single-layer logical `SpatRaster` named `flood_exclusion` on the
#'   grid of `dem`; `TRUE` means excluded.
#'
#' @section Hazards:
#' Soil flooding classes describe stream overflow on floodplains. They miss
#' flash floods in small hollows, so use this together with
#' [channel_exclusion()], not instead of it.
#'
#' @references
#' Soil Survey Staff, Natural Resources Conservation Service. Flooding
#' Frequency Class (Maximum). Web Soil Survey map documentation.
#' <https://www.nrcs.usda.gov/sites/default/files/2023-05/FloodingFrequency_Maximum.pdf>
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' soils <- terra::vect(
#'   system.file("extdata", "vesuvius_soils.gpkg", package = "leeward")
#' )
#' terra::plot(flood_exclusion(dem, soils))
#' @export
flood_exclusion <- function(dem, soils, column = "flodfreqmax",
                            exclude = c(
                              "Occasional", "Common", "Frequent",
                              "Very frequent"
                            )) {
  check_dem(dem)
  soils <- check_soils(soils, dem, column)
  classes <- c(
    "None", "Very rare", "Rare", "Occasional", "Common", "Frequent",
    "Very frequent"
  )
  if (!is.character(exclude) || !all(exclude %in% classes)) {
    cli::cli_abort(c(
      "{.arg exclude} must contain flooding frequency classes.",
      "i" = "Classes: {.val {classes}}."
    ))
  }
  check_known_classes(
    soils[[column, drop = TRUE]], classes,
    hint = "Recode the column to NRCS class names: {.val {known}}."
  )

  flood_class <- soils[[column, drop = TRUE]]
  template <- terra::rast(dem)
  known <- soils[!is.na(flood_class), ]
  known_cells <- terra::rasterize(known, template, field = 1)
  flooding <- soils[!is.na(flood_class) & flood_class %in% exclude, ]
  touched <- if (nrow(flooding) > 0) {
    terra::rasterize(flooding, template, touches = TRUE, background = 0) == 1
  } else {
    terra::init(template, 0) == 1
  }

  # ifel() returns numbers; compare to get the logical layer exclusions need.
  out <- terra::ifel(touched, 1, terra::ifel(is.na(known_cells), NA, 0)) == 1
  out <- terra::mask(out, dem)
  names(out) <- "flood_exclusion"
  out
}
# nolint end

check_soils <- function(soils, dem, column, call = rlang::caller_env()) {
  soils <- check_polygons(soils, dem, arg = "soils", call = call)
  ok <- is.character(column) && length(column) == 1 &&
    column %in% names(soils)
  if (!ok) {
    cli::cli_abort(
      c(
        "{.arg soils} has no column {.val {column}}.",
        "i" = "Columns: {.val {names(soils)}}."
      ),
      call = call
    )
  }
  soils
}

check_known_classes <- function(values, known, hint,
                                call = rlang::caller_env()) {
  unknown <- setdiff(stats::na.omit(unique(values)), known)
  if (length(unknown) > 0) {
    cli::cli_abort(
      c("Unknown class{?es} in {.arg soils}: {.val {unknown}}.", "i" = hint),
      call = call
    )
  }
  invisible()
}
