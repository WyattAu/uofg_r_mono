test_that("ma_signal() is flat until windows populate, then switches", {
  p <- c(1, 2, 3, 4, 5, 6)
  pos <- ma_signal(p, fast = 2, slow = 3)
  expect_identical(length(pos), length(p))
  expect_identical(pos[1], 0) # windows not populated yet
  expect_true(all(pos %in% c(0, 1)))
})

test_that("ma_signal() is strictly trailing (causal by construction)", {
  p <- cumprod(1 + rnorm(50, 0.001, 0.02))
  withr::with_seed(11, p <- cumprod(1 + rnorm(50, 0.001, 0.02)))
  expect_identical(
    ma_signal(p[1:30], fast = 2, slow = 5),
    ma_signal(p, fast = 2, slow = 5)[1:30]
  )
})

test_that("ma_signal() validates its arguments", {
  expect_error(ma_signal("a"), "numeric vector")
  expect_error(ma_signal(c(1, 2, 3), fast = 3, slow = 3), "smaller than")
  expect_error(ma_signal(c(1, 2, 3), fast = 0), "fast")
  expect_error(ma_signal(c(1, 2, 3), slow = 1), "slow")
})
