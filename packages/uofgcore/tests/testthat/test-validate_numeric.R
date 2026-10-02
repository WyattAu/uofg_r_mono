test_that("validate_numeric() returns its input unchanged", {
  x <- c(1, 2, 3)
  expect_identical(validate_numeric(x), x)
  expect_identical(validate_numeric(c(1L, 2L)), c(1L, 2L))
})

test_that("validate_numeric() uses the argument name in errors", {
  expect_error(validate_numeric("a"), "must be a numeric vector")
  expect_error(validate_numeric(NULL), "must not be empty")
  y <- "oops"
  expect_error(validate_numeric(y), "`y` must be a numeric vector")
})
