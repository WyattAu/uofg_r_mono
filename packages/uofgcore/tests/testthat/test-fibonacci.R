test_that("fibonacci() returns known values", {
  expect_identical(fibonacci(0), 0)
  expect_identical(fibonacci(1), 1)
  expect_identical(fibonacci(2), 1)
  expect_identical(fibonacci(10), 55)
  expect_identical(fibonacci(20), 6765)
  # The largest Fibonacci number exactly representable as a double.
  expect_identical(fibonacci(78), 8944394323791464)
})

test_that("fibonacci() validates its input", {
  expect_error(fibonacci(-1), "`n` must be")
  expect_error(fibonacci(2.5), "`n` must be")
  expect_error(fibonacci(c(1, 2)), "`n` must be")
  expect_error(fibonacci(79), "at most 78")
})
