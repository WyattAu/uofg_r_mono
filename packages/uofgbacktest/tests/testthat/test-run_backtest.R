test_that("run_backtest() computes hand-checked equity and metrics", {
  p <- c(100, 110, 99)
  long <- function(pr) rep(1, length(pr))
  bt <- run_backtest(p, long, initial_capital = 1e5, cost_per_trade = 0)

  # returns: +10%, -10%; positions held: 1, 1; no costs
  expect_equal(bt$returns, c(0.10, -0.10))
  expect_equal(bt$equity, c(110000, 99000))
  expect_equal(bt$metrics$total_return, -0.01)
  expect_identical(bt$metrics$n_trades, 0L)

  # max drawdown of c(110000, 99000): -10%
  expect_equal(bt$metrics$max_drawdown, -0.10)
})

test_that("run_backtest() charges costs per position change", {
  p <- c(100, 110, 99)
  # flat at t=1, long from t=2 onward: one 1-unit entry at t=2
  enter <- function(pr) {
    out <- rep(0, length(pr))
    out[-1] <- 1
    out
  }
  bt <- run_backtest(p, enter, initial_capital = 1e5, cost_per_trade = 0.01)

  expect_identical(bt$positions, c(0, 1, 1))
  expect_identical(bt$costs, c(0.01, 0)) # entry charged at t=2, then flat
  # period 1: position 0 -> zero return, minus the entry cost
  expect_identical(bt$returns[1], -0.01)
  # period 2: position 1 * -10%, no further position change
  expect_equal(bt$returns[2], -0.10)
})

test_that("run_backtest() preserves the xts time index", {
  px <- xts::xts(c(100, 102, 101), order.by = as.Date("2026-01-01") + 0:2)
  bt <- run_backtest(px, function(pr) rep(1, length(pr)), cost_per_trade = 0)
  expect_s3_class(bt, "uofg_backtest")
  expect_length(bt$index, 2)
})

test_that("print and summary expose the metrics", {
  bt <- run_backtest(c(100, 110, 99), function(pr) rep(1, length(pr)))
  expect_output(print(bt), "uofg_backtest over 2 periods")
  expect_output(print(bt), "Total return:")
  s <- summary(bt)
  expect_s3_class(s, "data.frame")
  expect_identical(nrow(s), 6L)
  expect_true("sharpe" %in% s$metric)
})

test_that("run_backtest() rejects look-ahead signals", {
  p <- c(100, 110, 99, 105, 103)
  # peeking: the position for period t depends on the price at t+1.
  # With p = c(100, 90, 105), the peeking position at t=2 is long
  # (knowing 105 comes next) while the causal position is flat.
  p <- c(100, 90, 105)
  cheater <- function(pr) c(diff(pr) > 0, 0)
  expect_error(
    run_backtest(p, cheater, check_causality = TRUE),
    "not causal"
  )
  # the same signal is accepted when enforcement is off (documented out)
  expect_no_error(run_backtest(p, cheater, check_causality = FALSE))
})

test_that("run_backtest() validates signal shape and arguments", {
  p <- c(100, 110, 99)
  expect_error(run_backtest(p, function(pr) 1), "finite numeric vector")
  expect_error(run_backtest(p, function(pr) c(1, 1)), "finite numeric vector")
  expect_error(
    run_backtest(p, function(pr) rep(NA_real_, length(pr))),
    "finite numeric vector"
  )
  expect_error(
    run_backtest(c(100, 110), function(pr) rep(1, 2)),
    "at least three"
  )
  expect_error(
    run_backtest(p, function(pr) rep(1, 3), initial_capital = -1),
    "initial_capital"
  )
  expect_error(
    run_backtest(p, function(pr) rep(1, 3), cost_per_trade = -0.01),
    "cost_per_trade"
  )
})

test_that("the example signal passes the causality enforcement", {
  withr::with_seed(5, {
    p <- cumprod(1 + rnorm(60, 0.0004, 0.01))
  })
  expect_no_error(run_backtest(p, ma_signal, cost_per_trade = 0.001))
})
