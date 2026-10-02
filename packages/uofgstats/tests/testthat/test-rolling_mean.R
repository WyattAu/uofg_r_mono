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

test_that("rolling_mean() validates its inputs", {
  # The error below comes from uofgcore::validate_numeric(): proof that
  # the intra-monorepo dependency is wired up correctly.
  expect_error(rolling_mean("a", 1), "must be a numeric vector")
  expect_error(rolling_mean(numeric(), 1), "must not be empty")
  expect_error(rolling_mean(1:5, 0), "`window` must be")
  expect_error(rolling_mean(1:5, 2.5), "`window` must be")
  expect_error(rolling_mean(1:5, 6), "must not exceed")
})
