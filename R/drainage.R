#' Upslope contributing area
#'
#' Returns the area draining through each cell, in square meters, including
#' the cell itself. Depressions are filled first (Planchon and Darboux, 2002)
#' with a small gradient so that flats and pits drain, then each cell drains
#' to its steepest downslope neighbor (D8). Water leaves the DEM at its edge
#' and at `NA` cells.
#'
#' Contributing area is truncated where the true catchment extends beyond the
#' DEM, so clip with a buffer that covers the catchments of interest.
#'
#' @inheritParams exposure_along_direction
#'
#' @return Single-layer `SpatRaster` named `contributing_area`, in square
#'   meters, on the grid of `dem`.
#'
#' @references
#' Planchon, O., & Darboux, F. (2002). A fast, simple and versatile
#' algorithm to fill the depressions of digital elevation models. *Catena*,
#' 46(2--3), 159--176. \doi{10.1016/S0341-8162(01)00164-3}
#'
#' @family suitability layers
#' @seealso [height_above_channel()] uses it to define channels.
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' area <- contributing_area(dem)
#' terra::plot(log10(area))
#' @export
contributing_area <- function(dem) {
  check_dem(dem)
  routing <- route_flow(dem)
  as_layer(dem, routing$area, "contributing_area")
}

#' Height above the nearest channel
#'
#' Returns each cell's height above the channel cell it drains to (HAND,
#' Rennó et al. 2008; Nobre et al. 2011). Channels are cells whose
#' [contributing_area()] is at least `min_area`. Low values mark ground that
#' floods when the channel rises. Unlike [water_distance()], this measure
#' needs no mapped streams, so it also covers the dry hollows and
#' intermittent channels that stream maps leave out.
#'
#' Cells in filled depressions can sit below their drainage cell; they are
#' set to 0, because standing water collects there. Cells that drain off the
#' DEM without reaching a channel are `NA`.
#'
#' @inheritParams exposure_along_direction
#' @param min_area Contributing area, in square meters, at which a channel
#'   starts. The default of 1 ha was chosen on the Lake Vesuvius example,
#'   where it recovers nearly all mapped streams and adds the unmapped
#'   hollows above them. Where channels start depends on climate, soil, and
#'   geology, so check the result against the ground or a topographic map.
#'
#' @return Single-layer `SpatRaster` named `height_above_channel`, in
#'   meters, on the grid of `dem`.
#'
#' @section Hazards:
#' A DEM can only show channels that are wider than a few cells. Narrow
#' gullies, culverts, and channels under dense canopy may be missing or
#' misplaced, so treat low values as a minimum hazard area, not a complete
#' one.
#'
#' Contributing area stops at the DEM edge. A stream entering from outside
#' starts with too little area to count as a channel, so its banks are not
#' flagged. Clip the DEM to cover the upstream catchments of the area of
#' interest. `NA` means unknown, not safe: treat `NA` in the result, and in
#' [channel_exclusion()], as excluded.
#'
#' Never camp in a channel or on a low bank during unsettled weather.
#'
#' @references
#' Rennó, C. D., Nobre, A. D., Cuartas, L. A., Soares, J. V., Hodnett, M. G.,
#' Tomasella, J., & Waterloo, M. J. (2008). HAND, a new terrain descriptor
#' using SRTM-DEM: Mapping terra-firme rainforest environments in Amazonia.
#' *Remote Sensing of Environment*, 112(9), 3469--3481.
#' \doi{10.1016/j.rse.2008.03.018}
#'
#' Nobre, A. D., Cuartas, L. A., Hodnett, M., Rennó, C. D., Rodrigues, G.,
#' Silveira, A., Waterloo, M., & Saleska, S. (2011). Height Above the Nearest
#' Drainage -- a hydrologically relevant new terrain model. *Journal of
#' Hydrology*, 404(1--2), 13--29. \doi{10.1016/j.jhydrol.2011.03.051}
#'
#' @family suitability layers
#' @seealso [channel_exclusion()] uses the result.
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' hand <- height_above_channel(dem)
#' terra::plot(hand)
#' @export
height_above_channel <- function(dem, min_area = 1e4) {
  check_dem(dem)
  ok <- is.numeric(min_area) && length(min_area) == 1 &&
    is.finite(min_area) && min_area > 0
  if (!ok) {
    cli::cli_abort(
      "{.arg min_area} must be a single positive number of square meters."
    )
  }

  routing <- route_flow(dem)
  channel <- !is.na(routing$area) & routing$area >= min_area
  drain_z <- rep(NA_real_, length(routing$z))
  # Visit cells from low to high filled elevation, so each cell's downstream
  # neighbor is done first.
  for (i in rev(routing$order)) {
    if (channel[i]) {
      drain_z[i] <- routing$z[i]
    } else if (routing$down[i] > 0) {
      drain_z[i] <- drain_z[routing$down[i]]
    }
  }
  hand <- pmax(routing$z - drain_z, 0)
  as_layer(dem, hand, "height_above_channel")
}

#' Exclude low ground along channels
#'
#' Returns a hard exclusion mask: `TRUE` for cells at most `min_height`
#' above the channel they drain to, including the channels themselves.
#'
#' @param height `SpatRaster` from [height_above_channel()].
#' @param min_height Height above the channel, in meters, at or below which
#'   cells are excluded. The 3 m default is a judgment call, not a
#'   published flood standard. Raise it in large valleys or where flash
#'   floods are common.
#'
#' @return Single-layer logical `SpatRaster` named `channel_exclusion`;
#'   `TRUE` means excluded.
#'
#' @inheritSection height_above_channel Hazards
#' @family suitability layers
#' @examples
#' dem <- terra::rast(
#'   system.file("extdata", "vesuvius_dem.tif", package = "leeward")
#' )
#' terra::plot(channel_exclusion(height_above_channel(dem)))
#' @export
channel_exclusion <- function(height, min_height = 3) {
  ok <- inherits(height, "SpatRaster") && terra::nlyr(height) == 1
  if (!ok) {
    cli::cli_abort(c(
      "{.arg height} must be a single-layer {.cls SpatRaster}.",
      "i" = "Create one with {.fn height_above_channel}."
    ))
  }
  ok <- is.numeric(min_height) && length(min_height) == 1 &&
    is.finite(min_height) && min_height >= 0
  if (!ok) {
    cli::cli_abort("{.arg min_height} must be a single non-negative number.")
  }

  out <- height <= min_height
  names(out) <- "channel_exclusion"
  out
}

# Fill depressions, route flow by D8, and accumulate area. Returns vectors in
# matrix (column-major) order: original elevation `z`, downstream cell index
# `down` (0 = leaves the DEM), contributing `area`, and `order`, the valid
# cells from highest to lowest filled elevation.
route_flow <- function(dem) {
  z <- terra::as.matrix(dem, wide = TRUE)
  res <- terra::res(dem)
  filled <- fill_depressions(z, res)
  down <- d8_downstream(filled, res)

  order <- order(filled, decreasing = TRUE, na.last = NA)
  area <- ifelse(is.na(z), NA_real_, prod(res))
  # Each cell needs its full upstream total before it passes it on, so this
  # is a per-cell loop rather than a raster operation. It is O(cells) and
  # takes well under a second on the 400 x 400 example.
  for (i in order) {
    d <- down[i]
    if (d > 0) {
      area[d] <- area[d] + area[i]
    }
  }
  list(z = as.vector(z), down = down, area = area, order = order)
}

# Planchon and Darboux (2002), basic algorithm: start with water everywhere
# except at outlets, then lower each cell to its own elevation or to its
# lowest neighbor plus a small gradient, until nothing changes. Only cells
# next to a cell that changed can change, so each pass updates that frontier
# instead of the whole grid; a full-grid pass per step was 10x slower.
fill_depressions <- function(z, res, gradient = 1e-5) {
  nb <- neighbors8(res)
  index <- neighbor_index(dim(z), nb)
  step <- gradient * nb$dist
  valid <- !is.na(z)
  outlet <- valid & rowSums(is.na(matrix(z[index], ncol = nrow(nb)))) > 0

  w <- ifelse(outlet, z, Inf)
  w[!valid] <- NA
  can_change <- valid & !outlet
  active <- which(can_change)
  while (length(active) > 0) {
    lowest <- lowest_neighbor(w, index, active, step)
    new <- pmax(z[active], pmin(w[active], lowest))
    changed <- active[new != w[active]]
    w[active] <- new
    next_active <- logical(length(w))
    next_active[index[changed, ]] <- TRUE
    active <- which(next_active & can_change)
  }
  matrix(w, nrow(z), ncol(z))
}

# Linear index of each neighbor of each cell (rows) at each offset
# (columns); NA where the neighbor is off the grid.
neighbor_index <- function(dims, nb) {
  rows <- rep(seq_len(dims[1]), dims[2])
  cols <- rep(seq_len(dims[2]), each = dims[1])
  index <- vapply(seq_len(nrow(nb)), function(k) {
    r <- rows + nb$drow[k]
    c <- cols + nb$dcol[k]
    ifelse(r >= 1 & r <= dims[1] & c >= 1 & c <= dims[2],
      (c - 1L) * dims[1] + r, NA_integer_
    )
  }, integer(length(rows)))
  matrix(index, ncol = nrow(nb))
}

lowest_neighbor <- function(w, index, cells, step) {
  lowest <- w[index[cells, 1]] + step[1]
  for (k in seq_along(step)[-1]) {
    lowest <- pmin(lowest, w[index[cells, k]] + step[k], na.rm = TRUE)
  }
  lowest
}

# Index of the steepest downslope neighbor of each cell, or 0 if none.
d8_downstream <- function(w, res) {
  nb <- neighbors8(res)
  nr <- nrow(w)
  rows <- row(w)
  cols <- col(w)
  best_drop <- matrix(0, nr, ncol(w))
  down <- matrix(0L, nr, ncol(w))
  for (k in seq_len(nrow(nb))) {
    drop <- (w - shift_matrix(w, nb$drow[k], nb$dcol[k])) / nb$dist[k]
    steeper <- !is.na(drop) & drop > best_drop
    best_drop[steeper] <- drop[steeper]
    target <- (cols + nb$dcol[k] - 1L) * nr + rows + nb$drow[k]
    down[steeper] <- target[steeper]
  }
  as.vector(down)
}

neighbors8 <- function(res) {
  nb <- expand.grid(drow = -1:1, dcol = -1:1)
  nb <- nb[nb$drow != 0 | nb$dcol != 0, ]
  nb$dist <- sqrt((nb$drow * res[2])^2 + (nb$dcol * res[1])^2)
  nb
}

# Matrix-order vector -> SpatRaster on the grid of `dem`.
as_layer <- function(dem, values, name) {
  out <- terra::rast(dem)
  m <- matrix(values, terra::nrow(dem), terra::ncol(dem))
  terra::values(out) <- as.vector(t(m))
  names(out) <- name
  out
}
