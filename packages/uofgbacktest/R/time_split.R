#' Split observations into time-based train/test sets
#'
#' Implements the monorepo's backtesting-hygiene rule: splits are
#' **time-based, never random**. The first `floor(n * train_frac)`
#' observations become the training set; the remainder become the test
#' set. The result is checked to be a clean partition.
#'
#' @param n Positive integer, total number of observations.
#' @param train_frac Fraction of observations for the training set,
#'   in (0, 1).
#'
#' @return A list with integer vectors `train` and `test` of indices.
#'
#' @examples
#' time_split(n = 10, train_frac = 0.7)
#'
#' @export
time_split <- function(n, train_frac = 0.7) {
  checkmate::assert_int(n, lower = 3L)
  checkmate::assert_number(train_frac, lower = 0, upper = 1)

  k <- floor(n * train_frac)
  if (k < 1L || n - k < 1L) {
    stop("`train_frac` must leave at least one observation in each set.",
      call. = FALSE
    )
  }
  split <- list(train = seq_len(k), test = seq.int(k + 1L, n))
  stopifnot(!any(split$train %in% split$test), max(split$train) < min(split$test))
  split
}
