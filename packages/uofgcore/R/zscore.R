#' Standardize a vector to zero mean and unit variance
#'
#' Computes the classic z-score transformation. Demonstrates the
#' monorepo conventions: shared validation from [validate_numeric()],
#' an explicit `na_rm` flag (no implicit missing-value behavior), and
#' a hard error for mathematically undefined input.
#'
#' @param x A numeric vector.
#' @param na_rm If `TRUE`, missing values are ignored when computing the
#'   mean and standard deviation, and remain `NA` in the output. If
#'   `FALSE` (the default), any missing value makes the result `NA`.
#'
#' @return A numeric vector of the same length as `x`.
#'
#' @export
#'
#' @examples
#' zscore(c(1, 2, 3, 4, 5))
#' zscore(c(1, 2, NA, 4), na_rm = TRUE)
zscore <- function(x, na_rm = FALSE) {
  x <- validate_numeric(x)
  if (!is.logical(na_rm) || length(na_rm) != 1L || is.na(na_rm)) {
    stop("`na_rm` must be a single TRUE or FALSE.", call. = FALSE)
  }

  mu <- mean(x, na.rm = na_rm)
  sd_x <- stats::sd(x, na.rm = na_rm)
  if (is.na(sd_x)) {
    if (na_rm) {
      stop("`x` must contain at least two non-missing values.", call. = FALSE)
    }
    # Missing values with na_rm = FALSE simply propagate.
    return(rep(NA_real_, length(x)))
  }
  if (sd_x == 0) {
    stop("`x` must have defined, non-zero variance.", call. = FALSE)
  }
  (x - mu) / sd_x
}
