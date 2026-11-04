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
