check_numeric <- function(x,
                          arg = rlang::caller_arg(x),
                          call = rlang::caller_env()) {
  if (!is.numeric(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be numeric, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
}

check_whole_number <- function(x,
                               min = -Inf,
                               arg = rlang::caller_arg(x),
                               call = rlang::caller_env()) {
  ok <- is.numeric(x) && length(x) == 1 && !is.na(x) &&
    x == round(x) && x >= min
  if (!ok) {
    cli::cli_abort(
      "{.arg {arg}} must be a single whole number >= {min}, not {.val {x}}.",
      call = call
    )
  }
  invisible(x)
}

check_same_crs <- function(x, dem,
                           arg = rlang::caller_arg(x),
                           call = rlang::caller_env()) {
  if (!terra::same.crs(x, dem)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must use the same CRS as {.arg dem}.",
        "i" = "Reproject with {.code terra::project({arg}, dem)}."
      ),
      call = call
    )
  }
  invisible(x)
}

# sf objects become SpatVectors; anything else must already be one.
as_spat_vector <- function(x,
                           arg = rlang::caller_arg(x),
                           call = rlang::caller_env()) {
  force(arg)
  if (inherits(x, c("sf", "sfc"))) {
    x <- terra::vect(x)
  }
  if (!inherits(x, "SpatVector")) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls SpatVector} or {.cls sf} object, not
       {.obj_type_friendly {x}}.",
      call = call
    )
  }
  x
}
