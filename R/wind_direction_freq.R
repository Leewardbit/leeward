#' Bin wind directions into compass sectors
#'
#' Returns the relative frequency of wind directions in `n_sectors`
#' equal-width sectors, optionally split by speed class. Sector 1 is centered
#' on north; with 16 sectors it spans 348.75 to 11.25 degrees.
#'
#' Directions are degrees the wind blows **from**, 0 = north, clockwise.
#' Values outside `[0, 360)` are wrapped, so 360 and -10 become 0 and 350.
#'
#' @param dir Numeric vector of wind directions in degrees. `NA`s are dropped.
#' @param n_sectors Number of sectors; a whole number >= 4.
#' @param speed Optional numeric vector of wind speeds, the same length as
#'   `dir`.
#' @param speed_breaks Strictly increasing break points for speed classes,
#'   passed to [cut()] with `right = FALSE`. Required when `speed` is given.
#'   Observations outside the breaks are dropped with a warning.
#'
#' @return A data frame with columns `sector` (1 = north), `sector_center`
#'   (degrees), `speed_class` (factor; only when `speed` is given), `count`,
#'   and `frequency` (sums to 1).
#'
#' @examples
#' wind_direction_freq(c(350, 10, 5, 355, 90, 180), n_sectors = 8)
#'
#' wind_direction_freq(
#'   dir = c(0, 90, 90, 270),
#'   speed = c(2, 6, 12, 4),
#'   speed_breaks = c(0, 5, 10, Inf),
#'   n_sectors = 4
#' )
#' @export
wind_direction_freq <- function(dir,
                                n_sectors = 16,
                                speed = NULL,
                                speed_breaks = NULL) {
  check_numeric(dir)
  check_whole_number(n_sectors, min = 4)
  if (any(is.infinite(dir))) {
    cli::cli_abort("{.arg dir} must not contain infinite values.")
  }

  keep <- !is.na(dir)
  speed_class <- NULL
  if (!is.null(speed)) {
    speed_class <- bin_speed(speed, speed_breaks, n = length(dir))
    keep <- keep & !is.na(speed_class)
  } else if (!is.null(speed_breaks)) {
    cli::cli_warn("{.arg speed_breaks} is ignored when {.arg speed} is NULL.")
  }
  if (!any(keep)) {
    cli::cli_abort("No usable observations: all are missing or out of range.")
  }

  sector <- direction_to_sector(dir[keep], n_sectors)
  centers <- (seq_len(n_sectors) - 1) * 360 / n_sectors

  if (is.null(speed_class)) {
    counts <- tabulate(sector, nbins = n_sectors)
    return(data.frame(
      sector = seq_len(n_sectors),
      sector_center = centers,
      count = counts,
      frequency = counts / sum(counts)
    ))
  }

  speed_class <- speed_class[keep]
  n_classes <- nlevels(speed_class)
  counts <- table(factor(sector, levels = seq_len(n_sectors)), speed_class)
  data.frame(
    sector = rep(seq_len(n_sectors), times = n_classes),
    sector_center = rep(centers, times = n_classes),
    speed_class = factor(
      rep(levels(speed_class), each = n_sectors),
      levels = levels(speed_class)
    ),
    count = as.vector(counts),
    frequency = as.vector(counts) / sum(counts)
  )
}

direction_to_sector <- function(dir, n_sectors) {
  width <- 360 / n_sectors
  sector <- floor(((dir %% 360 + width / 2) %% 360) / width) + 1L
  # Floating-point rounding can push a value just below 360 into sector n + 1.
  sector[sector > n_sectors] <- 1L
  sector
}

bin_speed <- function(speed, speed_breaks, n, call = rlang::caller_env()) {
  check_numeric(speed, call = call)
  if (length(speed) != n) {
    cli::cli_abort(
      "{.arg speed} must have the same length as {.arg dir} ({n}),
       not {length(speed)}.",
      call = call
    )
  }
  ok <- is.numeric(speed_breaks) && length(speed_breaks) >= 2 &&
    !is.unsorted(speed_breaks, strictly = TRUE)
  if (!ok) {
    cli::cli_abort(
      c(
        "{.arg speed_breaks} must be a strictly increasing numeric vector of
         length >= 2.",
        "i" = "It is required when {.arg speed} is supplied."
      ),
      call = call
    )
  }
  speed_class <- cut(speed, breaks = speed_breaks, right = FALSE)
  n_out <- sum(!is.na(speed) & is.na(speed_class))
  if (n_out > 0) {
    cli::cli_warn(
      "Dropped {n_out} observation{?s} with speed outside {.arg speed_breaks}.",
      call = call
    )
  }
  speed_class
}
