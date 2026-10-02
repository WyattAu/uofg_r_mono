#' Validate that an argument is a non-empty numeric vector
#'
#' A small helper shared across the monorepo so that every package
#' reports input errors the same way. Returns the unchanged input on
#' success, so it can wrap arguments inline.
#'
#' @param x The object to validate.
#' @param x_name The argument name to use in error messages; defaults
#'   to the expression passed as `x`.
#'
#' @return `x`, unchanged.
#'
#' @export
#'
#' @examples
#' validate_numeric(c(1, 2, 3))
validate_numeric <- function(x, x_name = deparse1(substitute(x))) {
  if (length(x) == 0L) {
    stop("`", x_name, "` must not be empty.", call. = FALSE)
  }
  if (!is.numeric(x)) {
    stop("`", x_name, "` must be a numeric vector.", call. = FALSE)
  }
  x
}
