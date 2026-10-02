#' Compute a trailing rolling mean
#'
#' Computes the mean of `x` over trailing windows of length `window`
#' using a cumulative-sum algorithm (O(length(x)) time). Input
#' validation is delegated to [uofgcore::validate_numeric()], which
#' demonstrates how packages in this monorepo depend on one another.
#'
#' @param x A numeric vector.
#' @param window A single positive integer, the window size. Must not
#'   exceed `length(x)`.
#'
#' @return A numeric vector of length `length(x) - window + 1` where
#'   element `i` is `mean(x[seq.int(i, i + window - 1)])`.
#'
#' @export
#'
#' @examples
#' rolling_mean(c(1, 2, 3, 4, 5), 2)
#' rolling_mean(c(1, 2, 3, 4, 5), 5)
rolling_mean <- function(x, window) {
  x <- uofgcore::validate_numeric(x)
  is_bad_window <- !is.numeric(window) || length(window) != 1L ||
    is.na(window) || window < 1 || window != floor(window)
  if (is_bad_window) {
    stop("`window` must be a single positive integer.", call. = FALSE)
  }
  if (window > length(x)) {
    stop("`window` must not exceed `length(x)`.", call. = FALSE)
  }

  cs <- c(0, cumsum(x))
  start <- seq.int(window, length(x))
  (cs[start + 1L] - cs[start - window + 1L]) / window
}
