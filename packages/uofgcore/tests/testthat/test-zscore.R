test_that("zscore() standardizes to mean 0, sd 1", {
  z <- zscore(c(1, 2, 3, 4, 5))
  expect_equal(mean(z), 0, tolerance = 1e-12)
  expect_equal(stats::sd(z), 1, tolerance = 1e-12)
  expect_identical(z[1], (1 - 3) / sqrt(2.5))
})

test_that("zscore() preserves NAs by default", {
  x <- c(1, 2, NA, 4)
  expect_true(all(is.na(zscore(x))))
})

test_that("zscore(na_rm = TRUE) imputes nothing but rescales cleanly", {
  x <- c(1, 2, NA, 4)
  z <- zscore(x, na_rm = TRUE)
  expect_identical(which(is.na(z)), 3L)
  expect_equal(mean(z, na.rm = TRUE), 0, tolerance = 1e-12)
  expect_equal(stats::sd(z, na.rm = TRUE), 1, tolerance = 1e-12)
})

test_that("zscore() rejects undefined input", {
  expect_error(zscore("a"), "must be a numeric vector")
  expect_error(zscore(numeric()), "must not be empty")
  expect_error(zscore(c(2, 2, 2)), "non-zero variance")
  expect_error(zscore(c(NA_real_, NA_real_), na_rm = TRUE), "at least two non-missing")
  expect_error(zscore(1, na_rm = "yes"), "`na_rm` must be")
})
