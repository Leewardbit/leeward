#' Bin wind directions into compass sectors
#'
#' Bins observed wind directions into `n_sectors` equal-width compass sectors
#' and returns the relative frequency of each sector. Sector 1 is centred on
#' north (0 degrees), so with 16 sectors it spans 348.75 to 11.25 degrees.
#'
#' **Direction convention:** degrees, the direction the wind blows *from*,
#' 0 = north, increasing clockwise. Values outside `[0, 360)` are wrapped,
#' so 360 and -10 are treated as 0 and 350.
#'
#' @param dir Numeric vector of wind directions in degrees (direction the
#'   wind blows FROM). `NA` values are dropped.
#' @param n_sectors Whole number of sectors, at least 4 (default 16).
#' @param speed Optional numeric vector of wind speeds, the same length as
#'   `dir`. If supplied, frequencies are also split by speed class.
#' @param speed_breaks Numeric vector of break points for the speed classes,
#'   passed to [cut()] with `right = FALSE`. Required when `speed` is
#'   supplied. Speeds outside the breaks are dropped with a warning.
#'
#' @return A data frame with one row per sector (or per sector x speed
#'   class) and columns:
#'   \describe{
#'     \item{sector}{Sector index, 1 = north.}
#'     \item{sector_center}{Sector centre in degrees.}
#'     \item{speed_class}{Factor of speed classes (only if `speed` is given).}
#'     \item{count}{Number of observations.}
#'     \item{frequency}{Proportion of all retained observations; sums to 1.}
#'   }
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
wind_direction_freq <- function(dir, n_sectors = 16, speed = NULL,
                                 speed_breaks = NULL) {
  if (!is.numeric(dir)) {
    stop("`dir` must be a numeric vector of directions in degrees.",
         call. = FALSE)
  }
  if (!is.numeric(n_sectors) || length(n_sectors) != 1 ||
      is.na(n_sectors) || n_sectors < 4 || n_sectors != round(n_sectors)) {
    stop("`n_sectors` must be a single whole number >= 4.", call. = FALSE)
  }
  n_sectors <- as.integer(n_sectors)

  has_speed <- !is.null(speed)
  if (has_speed) {
    if (!is.numeric(speed) || length(speed) != length(dir)) {
      stop("`speed` must be a numeric vector the same length as `dir`.",
           call. = FALSE)
    }
    if (is.null(speed_breaks) || !is.numeric(speed_breaks) ||
        length(speed_breaks) < 2 || is.unsorted(speed_breaks, strictly = TRUE)) {
      stop("`speed_breaks` must be a strictly increasing numeric vector of ",
           "length >= 2 when `speed` is supplied.", call. = FALSE)
    }
  } else if (!is.null(speed_breaks)) {
    warning("`speed_breaks` ignored because `speed` is NULL.", call. = FALSE)
  }

  if (any(is.infinite(dir))) {
    stop("`dir` contains infinite values.", call. = FALSE)
  }

  keep <- !is.na(dir)
  if (has_speed) {
    speed_class <- cut(speed, breaks = speed_breaks, right = FALSE)
    out_of_range <- keep & !is.na(speed) & is.na(speed_class)
    if (any(out_of_range)) {
      warning(sum(out_of_range), " observation(s) with speed outside ",
              "`speed_breaks` dropped.", call. = FALSE)
    }
    keep <- keep & !is.na(speed_class)
  }
  if (!any(keep)) {
    stop("No usable (non-missing) observations supplied.", call. = FALSE)
  }

  width  <- 360 / n_sectors
  sector <- floor((((dir[keep] %% 360) + width / 2) %% 360) / width) + 1L
  # Guard against floating-point edge cases landing in sector n + 1.
  sector[sector > n_sectors] <- 1L
  centers <- (seq_len(n_sectors) - 1) * width

  if (!has_speed) {
    counts <- tabulate(sector, nbins = n_sectors)
    return(data.frame(
      sector        = seq_len(n_sectors),
      sector_center = centers,
      count         = counts,
      frequency     = counts / sum(counts)
    ))
  }

  sc  <- speed_class[keep]
  tab <- table(factor(sector, levels = seq_len(n_sectors)), sc)
  out <- data.frame(
    sector        = rep(seq_len(n_sectors), times = nlevels(sc)),
    sector_center = rep(centers, times = nlevels(sc)),
    speed_class   = factor(rep(levels(sc), each = n_sectors),
                           levels = levels(sc)),
    count         = as.vector(tab)
  )
  out$frequency <- out$count / sum(out$count)
  out
}
