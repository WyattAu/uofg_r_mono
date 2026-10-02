test_that("greet() produces the expected greeting", {
  expect_identical(greet("World"), "Hello, World!")
  expect_identical(greet(""), "Hello, !")
})

test_that("greet() validates its input", {
  expect_error(greet(42), "`name` must be")
  expect_error(greet(c("a", "b")), "`name` must be")
  expect_error(greet(NA_character_), "`name` must be")
})
