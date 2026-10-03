test_that("time_split() returns a clean, ordered time partition", {
  split <- time_split(n = 10, train_frac = 0.7)
  expect_identical(split$train, 1:7)
  expect_identical(split$test, 8:10)
  expect_true(max(split$train) < min(split$test))
})

test_that("time_split() validates its arguments", {
  expect_error(time_split(n = 2), "n")
  expect_error(time_split(n = 10, train_frac = 1), "at least one observation")
  expect_error(time_split(n = 10, train_frac = 0), "at least one observation")
  expect_error(time_split(n = 10, train_frac = 1.5), "train_frac")
})
