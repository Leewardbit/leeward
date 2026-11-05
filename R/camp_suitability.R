#' Combine scores and exclusions into campsite suitability
#'
#' Returns the weighted mean of 0--1 score layers, with every exclusion
#' applied as a hard rule. A cell is excluded if any exclusion layer is
#' `TRUE` **or `NA`**, because `NA` means unknown, not safe. Excluded cells
#' get `NA` suitability, whatever their scores.
#'
#' Results are **candidate areas to scout**, not safe campsites. The model
#' cannot see dead trees, recent closures, or the ground itself. Check the
#' hazards in [height_above_channel()] and [shelter_score()], and confirm
#' land status with the managing agency.
#'
#' @param scores Named list of single-layer `SpatRaster`s with values in
#'   0--1, or one multi-layer `SpatRaster`, such as [flatness_score()],
#'   [shelter_score()], [aspect_score()], and [water_score()]. An unnamed
#'   list uses the layer names.
#' @param weights Named non-negative numbers, one per score, with names
#'   matching `scores`. They are scaled to sum to 1. There is no default:
#'   what makes a good site depends on the trip. Layers with weight 0 are
#'   skipped.
#' @param exclusions List of logical `SpatRaster`s, or one multi-layer
#'   logical `SpatRaster`, where `TRUE` means excluded, such as
#'   [water_exclusion()], [channel_exclusion()], and [land_exclusion()].
#'   Required: pass `list()` to apply none on purpose.
#'
#' @return Two-layer `SpatRaster`:
#'   * `suitability`: weighted mean score, 0--1. `NA` where the cell is
#'     excluded or a weighted score is `NA`.
#'   * `excluded`: logical, `TRUE` where any exclusion applies. This tells
#'     excluded cells apart from cells with unknown scores.
#'
#' @family suitability layers
#' @seealso [candidate_areas()] ranks the best patches.
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' gpkg <- system.file("extdata", "vesuvius_water.gpkg", package = "leeward")
#' water <- water_distance(dem, terra::vect(gpkg, layer = "flowlines"))
#' hand <- height_above_channel(dem)
#'
#' suit <- camp_suitability(
#'   scores = list(
#'     flat = flatness_score(dem),
#'     water = water_score(water)
#'   ),
#'   weights = c(flat = 2, water = 1),
#'   exclusions = list(water_exclusion(water), channel_exclusion(hand))
#' )
#' terra::plot(suit$suitability)
#' @export
camp_suitability <- function(scores, weights, exclusions) {
  if (missing(weights)) {
    cli::cli_abort(c(
      "{.arg weights} is required.",
      "i" = "There is no default: choose how much each score matters, e.g.
             {.code weights = c(flat = 2, water = 1)}."
    ))
  }
  if (missing(exclusions)) {
    cli::cli_abort(c(
      "{.arg exclusions} is required.",
      "i" = "Pass hazard masks such as {.fn channel_exclusion} and
             {.fn water_exclusion}, or {.code list()} to apply none."
    ))
  }
  scores <- as_layer_list(scores)
  if (length(scores) == 0) {
    cli::cli_abort("{.arg scores} must contain at least one layer.")
  }
  exclusions <- as_layer_list(exclusions)
  weights <- check_weights(weights, names(scores))
  check_same_grid(c(scores, exclusions))
  call <- rlang::current_env()
  for (nm in names(scores)) {
    check_unit_range(scores[[nm]], nm, call = call)
  }
  for (i in seq_along(exclusions)) {
    check_logical(exclusions[[i]], i, call = call)
  }

  used <- names(weights)[weights > 0]
  weights <- weights[used] / sum(weights[used])
  suitability <- Reduce(
    `+`,
    Map(function(s, w) s * w, scores[used], weights)
  )

  excluded <- terra::init(scores[[1]], 0) == 1
  for (e in exclusions) {
    excluded <- excluded | is.na(e) | e
  }
  suitability <- terra::ifel(excluded, NA, suitability)

  out <- c(suitability, excluded)
  names(out) <- c("suitability", "excluded")
  out
}

#' Rank candidate areas
#'
#' Returns polygons of connected cells with suitability at or above
#' `min_score`, ranked by mean suitability. Patches join along edges and
#' corners. Cells with `NA` suitability, including all excluded cells, are
#' never part of a candidate.
#'
#' These are **candidate areas to scout**, not safe campsites. A 10--30 m
#' DEM shows gentle areas, not tent pads, and cannot see dead trees,
#' closures, or wet ground. Visit and judge each site in person.
#'
#' @param suitability `SpatRaster` from [camp_suitability()]. Only the
#'   `suitability` layer is used.
#' @param min_score Lowest suitability, 0--1, that a cell can have and still
#'   be part of a candidate.
#' @param min_area Smallest candidate kept, in square meters. The default
#'   400 m² is about four 10 m cells, enough room for a small group.
#'
#' @return `SpatVector` of polygons, one per candidate, with columns `rank`
#'   (1 = highest mean), `area_m2`, `mean_score`, and `max_score`. It has
#'   no rows if nothing qualifies.
#'
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' hand <- height_above_channel(dem)
#' suit <- camp_suitability(
#'   scores = list(flat = flatness_score(dem)),
#'   weights = c(flat = 1),
#'   exclusions = list(channel_exclusion(hand))
#' )
#' sites <- candidate_areas(suit, min_score = 0.9)
#' head(sites)
#' @export
candidate_areas <- function(suitability, min_score = 0.7, min_area = 400) {
  ok <- inherits(suitability, "SpatRaster") &&
    (terra::nlyr(suitability) == 1 || "suitability" %in% names(suitability))
  if (!ok) {
    cli::cli_abort(c(
      "{.arg suitability} must be a {.cls SpatRaster} with a
       {.field suitability} layer.",
      "i" = "Create one with {.fn camp_suitability}."
    ))
  }
  if ("suitability" %in% names(suitability)) {
    suitability <- suitability[["suitability"]]
  }
  ok <- is.numeric(min_score) && length(min_score) == 1 &&
    is.finite(min_score) && min_score >= 0 && min_score <= 1
  if (!ok) {
    cli::cli_abort("{.arg min_score} must be a single number from 0 to 1.")
  }
  ok <- is.numeric(min_area) && length(min_area) == 1 &&
    is.finite(min_area) && min_area >= 0
  if (!ok) {
    cli::cli_abort(
      "{.arg min_area} must be a single non-negative number of square meters."
    )
  }

  good <- terra::ifel(suitability >= min_score, 1, NA)
  patches <- terra::patches(good, directions = 8)
  stats <- patch_stats(suitability, patches)
  stats <- stats[stats$area_m2 >= min_area, , drop = FALSE]
  stats <- stats[order(-stats$mean_score, -stats$area_m2), , drop = FALSE]
  stats$rank <- seq_len(nrow(stats))

  polygons <- terra::as.polygons(patches)
  polygons <- polygons[match(stats$patch, polygons[[1]][[1]]), ]
  columns <- c("rank", "area_m2", "mean_score", "max_score")
  terra::values(polygons) <- stats[columns]
  polygons
}

patch_stats <- function(suitability, patches) {
  values <- data.frame(
    patch = as.vector(terra::values(patches)),
    score = as.vector(terra::values(suitability))
  )
  values <- values[!is.na(values$patch), , drop = FALSE]
  if (nrow(values) == 0) {
    return(data.frame(
      patch = numeric(), area_m2 = numeric(),
      mean_score = numeric(), max_score = numeric()
    ))
  }
  cells <- tapply(values$score, values$patch, length)
  data.frame(
    patch = as.numeric(names(cells)),
    area_m2 = as.vector(cells) * prod(terra::res(suitability)),
    mean_score = as.vector(tapply(values$score, values$patch, mean)),
    max_score = as.vector(tapply(values$score, values$patch, max))
  )
}

as_layer_list <- function(x,
                          arg = rlang::caller_arg(x),
                          call = rlang::caller_env()) {
  if (inherits(x, "SpatRaster")) {
    x <- lapply(seq_len(terra::nlyr(x)), function(i) x[[i]])
  }
  if (!is.list(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a list of {.cls SpatRaster}s or a
       {.cls SpatRaster}, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  is_single <- vapply(x, function(r) {
    inherits(r, "SpatRaster") && terra::nlyr(r) == 1
  }, logical(1))
  if (!all(is_single)) {
    cli::cli_abort(
      "Every element of {.arg {arg}} must be a single-layer
       {.cls SpatRaster}.",
      call = call
    )
  }
  layer_names <- vapply(x, names, character(1))
  if (is.null(names(x))) {
    names(x) <- layer_names
  }
  names(x)[names(x) == ""] <- layer_names[names(x) == ""]
  x
}

check_weights <- function(weights, score_names, call = rlang::caller_env()) {
  ok <- is.numeric(weights) && !is.null(names(weights)) &&
    all(is.finite(weights)) && all(weights >= 0) && sum(weights) > 0
  if (!ok) {
    cli::cli_abort(
      "{.arg weights} must be named, non-negative numbers with a positive
       sum.",
      call = call
    )
  }
  missing_w <- setdiff(score_names, names(weights))
  extra_w <- setdiff(names(weights), score_names)
  if (length(missing_w) > 0 || length(extra_w) > 0 || anyDuplicated(
    names(weights)
  )) {
    cli::cli_abort(
      c(
        "{.arg weights} names must match {.arg scores} names exactly.",
        "x" = if (length(missing_w) > 0) "No weight for {.val {missing_w}}.",
        "x" = if (length(extra_w) > 0) "No score named {.val {extra_w}}.",
        "i" = "Scores: {.val {score_names}}."
      ),
      call = call
    )
  }
  weights[score_names]
}

check_same_grid <- function(layers, call = rlang::caller_env()) {
  same <- vapply(layers[-1], function(r) {
    terra::compareGeom(layers[[1]], r, stopOnError = FALSE)
  }, logical(1))
  if (!all(same)) {
    cli::cli_abort(
      c(
        "All {.arg scores} and {.arg exclusions} must share one grid.",
        "x" = "{.val {names(layers)[-1][!same]}} {?does/do} not match
               {.val {names(layers)[1]}} in extent, resolution, or CRS.",
        "i" = "Build every layer from the same DEM, or align them with
               {.code terra::resample()}."
      ),
      call = call
    )
  }
  invisible()
}

check_unit_range <- function(score, name, call = rlang::caller_env()) {
  range <- terra::minmax(score, compute = TRUE)[, 1]
  tolerance <- 1e-9
  ok <- all(is.na(range)) ||
    (range[1] >= -tolerance && range[2] <= 1 + tolerance)
  if (!ok) {
    cli::cli_abort(
      c(
        "Score {.val {name}} must be in 0--1, but ranges from
         {signif(range[1], 3)} to {signif(range[2], 3)}.",
        "i" = "Convert raw indexes first, e.g. {.fn shelter_score} for Sx."
      ),
      call = call
    )
  }
  invisible()
}

check_logical <- function(exclusion, i, call = rlang::caller_env()) {
  if (!terra::is.bool(exclusion)) {
    cli::cli_abort(
      c(
        "Exclusion {i} ({.val {names(exclusion)}}) must be logical.",
        "i" = "Use a comparison, e.g. {.code dist < 61}, or an
               {.fn *_exclusion} function."
      ),
      call = call
    )
  }
  invisible()
}
