test_that("print method output is stable (snapshot demo)", {
  fit <- fit_linreg(y ~ x, data.frame(x = 1:5, y = c(2.1, 3.9, 6.2, 8.1, 9.8)))
  expect_snapshot(fit)

  # Error snapshots document the exact user-facing failure style; the
  # snapshotter normalizes differences that don't matter.
  expect_snapshot(tidy_linreg(fit$fit), error = TRUE)
})
