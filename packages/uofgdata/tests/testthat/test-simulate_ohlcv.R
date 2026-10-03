test_that("simulate_ohlcv() is deterministic given a seed", {
  a <- simulate_ohlcv(n_days = 30, seed = 7)
  b <- simulate_ohlcv(n_days = 30, seed = 7)
  expect_identical(a, b)

  c <- simulate_ohlcv(n_days = 30, seed = 8)
  expect_false(isTRUE(all.equal(a, c)))
})

test_that("simulate_ohlcv() output satisfies the data contract", {
  mkt <- simulate_ohlcv(n_days = 60)
  expect_s3_class(mkt, "xts")
  expect_identical(nrow(mkt), 60L)
  expect_identical(
    colnames(mkt), c("Open", "High", "Low", "Close", "Volume")
  )
  expect_no_error(uofgstats::validate_ohlcv(as.data.frame(mkt)))
})

test_that("simulate_ohlcv() leaves global RNG state untouched", {
  # Draw a reference value from a known RNG state; if simulate_ohlcv()
  # perturbed the global generator, the next draw would differ.
  withr::with_seed(99, reference <- sample.int(1e6, 1))
  set.seed(99)
  invisible(simulate_ohlcv(n_days = 10, seed = 3))
  expect_identical(sample.int(1e6, 1), reference)
})

test_that("simulate_ohlcv() validates its arguments", {
  expect_error(simulate_ohlcv(n_days = 1), "n_days")
  expect_error(simulate_ohlcv(start_price = -5), "start_price")
  expect_error(simulate_ohlcv(vol = -0.1), "vol")
  expect_error(simulate_ohlcv(seed = 1.5), "seed")
  expect_error(simulate_ohlcv(start = "2026-01-01"), "start")
})
