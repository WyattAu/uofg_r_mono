test_that("to_returns() computes simple and log returns", {
  p <- c(100, 101, 99.5, 103)
  expect_identical(to_returns(p), p[-1] / p[-4] - 1)
  expect_identical(to_returns(p, type = "log"), diff(log(p)))
  expect_length(to_returns(p), 3)
})

test_that("to_returns() preserves the xts structure", {
  px <- xts::xts(
    x = matrix(c(100, 101, 99.5, 103, 50, 51, 49, 52), ncol = 2),
    order.by = as.Date("2026-01-01") + 0:3
  )
  names(px) <- c("A", "B")
  r <- to_returns(px, type = "log")
  expect_s3_class(r, "xts")
  expect_equal(as.character(zoo::index(r)), as.character(zoo::index(px)[-1]))
  expect_identical(names(r), c("A", "B"))
  expect_equal(
    as.numeric(r[, "A"]),
    as.numeric(to_returns(as.numeric(px[, "A"]), type = "log"))
  )
})

test_that("to_returns() validates its inputs", {
  expect_error(to_returns("a"), "must be a numeric vector")
  expect_error(to_returns(100), "at least two prices")
  expect_error(to_returns(c(100, -1), type = "log"), "strictly positive")
  # Calling the xts method directly bypasses dispatch and hits the guard.
  expect_error(uofgstats:::to_returns.xts(1:3), "must be an xts object")
})

test_that("returns are strictly causal (no look-ahead)", {
  # Truncating the future must not change past returns: the property
  # backtesting depends on.
  p <- cumprod(1 + c(0.01, -0.02, 0.03, 0.01, -0.005))
  expect_identical(
    to_returns(p[1:4]),
    to_returns(p)[1:3]
  )
})
