test_that("rolling_mean() computes trailing means", {
  expect_identical(rolling_mean(c(1, 2, 3, 4, 5), 1), c(1, 2, 3, 4, 5))
  expect_identical(rolling_mean(c(1, 2, 3, 4, 5), 2), c(1.5, 2.5, 3.5, 4.5))
  expect_identical(rolling_mean(c(1, 2, 3, 4, 5), 5), 3)
})

test_that("rolling_mean() handles floating point input", {
  x <- c(0.5, 1.5, 2.5)
  expect_identical(rolling_mean(x, 3), 1.5)
})

test_that("rolling_mean() propagates NAs", {
  expect_identical(rolling_mean(c(1, NA, 3), 2), c(NA_real_, NA_real_))
})

test_that("rolling_mean() is exact on adversarial magnitudes (regression)", {
  # Cumulative-sum implementations drift here: window sums of a series
  # mixing 1e16 with 1 lose the small addend entirely. The exact method
  # must not. See Higham (2002), ch. 4.
  x <- c(rep(1e16, 2), rep(1, 8))
  w <- 3L
  n <- length(x) - w + 1L
  exact <- vapply(seq_len(n), function(i) mean(x[i:(i + w - 1L)]), numeric(1))
  expect_identical(rolling_mean(x, w, method = "exact"), exact)
})

test_that("rolling_mean() methods agree on well-scaled random data", {
  withr::with_seed(2026, {
    x <- rnorm(500) * 100 + 1e4
  })
  for (w in c(2L, 7L, 50L)) {
    expect_equal(
      rolling_mean(x, w, method = "exact"),
      rolling_mean(x, w, method = "fast"),
      tolerance = 1e-10
    )
  }
})

test_that("rolling_mean() validates its inputs", {
  # The error below comes from uofgcore::validate_numeric(): proof that
  # the intra-monorepo dependency is wired up correctly.
  expect_error(rolling_mean("a", 1), "must be a numeric vector")
  expect_error(rolling_mean(numeric(), 1), "must not be empty")
  expect_error(rolling_mean(1:5, 0), "`window` must be")
  expect_error(rolling_mean(1:5, 2.5), "`window` must be")
  expect_error(rolling_mean(1:5, 6), "must not exceed")
  expect_error(rolling_mean(1:5, 2, method = "nope"), "should be one of")
})
