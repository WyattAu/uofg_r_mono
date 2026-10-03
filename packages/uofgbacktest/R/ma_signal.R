#' Example signal: moving-average crossover
#'
#' A worked example of a causal signal: long when the trailing fast
#' moving average is at or above the trailing slow moving average, flat
#' otherwise. Positions are `0` until both windows are populated. The
#' function is strictly trailing — it passes [run_backtest()]'s
#' causality enforcement by construction.
#'
#' @param prices A numeric price vector.
#' @param fast Positive integer, fast window (must be < `slow`).
#' @param slow Positive integer, slow window.
#'
#' @return A numeric vector of positions (1 = long, 0 = flat), same
#'   length as `prices`.
#'
#' @examples
#' ma_signal(c(100, 101, 103, 102, 104, 106, 105), fast = 2, slow = 3)
#'
#' @export
ma_signal <- function(prices, fast = 5L, slow = 20L) {
  p <- uofgcore::validate_numeric(prices)
  checkmate::assert_int(fast, lower = 1L)
  checkmate::assert_int(slow, lower = 2L)
  if (fast >= slow) {
    stop("`fast` must be smaller than `slow`.", call. = FALSE)
  }

  # stats::filter(..., sides = 1) is a trailing (causal) moving average,
  # but we reuse the monorepo's numerically robust rolling_mean(): the
  # engine consumes the uofgstats layer, and well-scaled prices keep the
  # "fast" method's O(n) algorithm within tolerance. Leading windows are
  # padded with NAs, mapping to flat positions.
  pad <- function(ma, w) c(rep(NA_real_, w - 1L), ma)
  fast_ma <- pad(uofgstats::rolling_mean(p, fast, method = "fast"), fast)
  slow_ma <- pad(uofgstats::rolling_mean(p, slow, method = "fast"), slow)

  positions <- as.numeric(fast_ma >= slow_ma)
  positions[is.na(positions)] <- 0
  positions
}
