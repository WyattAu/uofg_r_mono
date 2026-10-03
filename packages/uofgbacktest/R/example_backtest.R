#' Run the built-in example backtest
#'
#' One-call demonstration of the full monorepo pipeline: synthetic
#' OHLCV data from `uofgdata`, the causal `ma_signal()` strategy, and
#' the backtesting engine. Deterministic via a fixed seed — running
#' this function always reproduces the same equity curve.
#'
#' @param n_days Positive integer, number of trading days to simulate.
#' @param seed Integer seed for the data generator.
#'
#' @return An object of class `uofg_backtest` (see [run_backtest()]).
#'
#' @examples
#' example_backtest(n_days = 250)
#'
#' @export
example_backtest <- function(n_days = 500L, seed = 42L) {
  mkt <- uofgdata::simulate_ohlcv(n_days = n_days, seed = seed, vol = 0.01)
  run_backtest(
    as.numeric(mkt$Close),
    ma_signal,
    cost_per_trade = 0.001
  )
}
