#' leeward: terrain wind exposure and campsite suitability
#'
#' leeward maps how sheltered terrain is from the wind and combines that with
#' slope, water, drainage, and land status into **candidate areas to scout**
#' for camping. It works on a projected DEM (`terra` `SpatRaster`, meters) and
#' a local wind record. Start with `vignette("getting-started", package =
#' "leeward")`.
#'
#' @section Directions:
#' Wind directions are degrees the wind blows **from**, 0 = north, clockwise.
#' Aspect (`preferred_aspect`) is the direction a slope **faces**. The two
#' are never mixed.
#'
#' @section Workflow:
#' 1. **Wind:** [wind_direction_freq()] bins a wind record by direction.
#' 2. **Shelter:** [wind_exposure()] (Winstral Sx, weighted by wind
#'    frequency), [exposure_along_direction()] for one direction, or
#'    [topex()] when there is no wind record. [suggest_max_dist()] proposes
#'    a search distance. [shelter_score()] turns either into a 0--1 score.
#' 3. **Scores (0--1, higher is better):** [flatness_score()],
#'    [aspect_score()], [water_score()] (from [water_distance()]),
#'    [drainage_score()] (SSURGO soils), and [canopy_score()] (tree cover).
#' 4. **Exclusions (logical, `TRUE` = out):** [water_exclusion()],
#'    [channel_exclusion()] (from [height_above_channel()] and
#'    [contributing_area()]), [flood_exclusion()] (SSURGO flooding
#'    frequency), and [land_exclusion()] for your own land-status polygons.
#' 5. **Combine:** [camp_suitability()] applies your weights and every
#'    exclusion. [candidate_areas()] ranks the best patches as polygons.
#'
#' @section Safety:
#' Results are candidate areas to scout, not safe campsites. Sheltered
#' hollows can flood and collect cold air; exposed ridges draw lightning; a
#' DEM cannot see dead trees overhead. The land-status layer is a filter you
#' supply, not an authority: check current rules and fire restrictions with
#' the managing agency.
#'
"_PACKAGE"
