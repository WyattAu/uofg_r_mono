test_that("exact method matches 256-bit MPFR reference (random data)", {
  withr::with_seed(42, {
    x <- rnorm(200) * 1e6 + 5e5
  })
  for (w in c(2L, 13L, 64L)) {
    expect_equal(
      rolling_mean(x, w, method = "exact"),
      mpfr_window_means(x, w),
      tolerance = 1e-12
    )
  }
})

test_that("fast method matches MPFR reference on well-scaled data", {
  withr::with_seed(43, {
    x <- rnorm(400) * 100
  })
  for (w in c(2L, 21L)) {
    expect_equal(
      rolling_mean(x, w, method = "fast"),
      mpfr_window_means(x, w),
      tolerance = 1e-10
    )
  }
})

test_that("fast method stays accurate on adversarial magnitudes", {
  # data.table's online algorithm accumulates in extended precision, so
  # it matches the MPFR reference even here. This pins that behavior: if
  # a data.table upgrade ever introduces drift on extreme magnitudes,
  # this test fails and the roxygen accuracy section must be updated.
  x <- c(rep(1e16, 2), rep(1, 8))
  expect_equal(
    rolling_mean(x, 3, method = "fast"),
    mpfr_window_means(x, 3),
    tolerance = 1e-12
  )
})
