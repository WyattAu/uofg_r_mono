data <- data.frame(x = 1:5, y = c(2.1, 3.9, 6.2, 8.1, 9.8))

test_that("fit_linreg() agrees with stats::lm and carries the class", {
  fit <- fit_linreg(y ~ x, data)
  expect_s3_class(fit, "uofg_linreg")
  expect_identical(fit$n_obs, 5L)
  ref <- stats::lm(y ~ x, data = data)
  expect_equal(stats::coef(fit$fit), stats::coef(ref))
})

test_that("print.uofg_linreg is quiet and returns its input invisibly", {
  fit <- fit_linreg(y ~ x, data)
  expect_invisible(print(fit))
  expect_output(print(fit), "uofg_linreg fit on 5 observations")
  expect_output(print(fit), "Formula: y ~ x")
})

test_that("tidy_linreg() returns a tidy coefficient table", {
  tidy <- tidy_linreg(fit_linreg(y ~ x, data))
  expect_s3_class(tidy, "data.frame")
  expect_identical(
    names(tidy),
    c("term", "estimate", "std_error", "statistic", "p_value")
  )
  expect_identical(tidy$term, c("(Intercept)", "x"))
  expect_equal(tidy$estimate, unname(stats::coef(stats::lm(y ~ x, data = data))))
  expect_true(all(tidy$p_value >= 0 & tidy$p_value <= 1))
})

test_that("fit_linreg() and tidy_linreg() validate their inputs", {
  expect_error(fit_linreg("y ~ x", data), "`formula` must be")
  expect_error(fit_linreg(y ~ x, "not a data frame"), "`data` must be")
  expect_error(fit_linreg(y ~ x, data.frame()), "must not be empty")
  expect_error(
    tidy_linreg(stats::lm(y ~ x, data = data)),
    "must be a `uofg_linreg` object"
  )
})

test_that("... passes arguments through to stats::lm", {
  weighted <- data.frame(x = 1:3, y = c(1, 2, 9), w = c(1, 1, 10))
  fit <- fit_linreg(y ~ x, weighted, weights = w)
  expect_equal(
    stats::coef(fit$fit),
    stats::coef(stats::lm(y ~ x, data = weighted, weights = w))
  )
})
