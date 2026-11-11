test_that("prop_ci() matches the closed-form Wald interval", {
  ci <- prop_ci(0.5, size = 100, conf_level = 0.95)
  expect_s3_class(ci, "data.frame")
  expect_identical(nrow(ci), 1L)
  expect_named(
    ci, c("estimate", "conf_level", "critical_value", "lower", "upper")
  )
  expect_equal(ci$estimate, 0.5)
  expect_equal(ci$critical_value, stats::qnorm(0.975))
  half_width <- sqrt(0.5 * 0.5 / 100)
  expect_equal(ci$lower, 0.5 - 1.959963985 * half_width, tolerance = 1e-6)
  expect_equal(ci$upper, 0.5 + 1.959963985 * half_width, tolerance = 1e-6)
})

test_that("prop_ci() critical value at 90% confidence rounds to 1.64", {
  ci90 <- prop_ci(0.6, size = 60, conf_level = 0.90)
  expect_equal(round(ci90$critical_value, 2), 1.64)
})

test_that("higher confidence widens the interval", {
  ci90 <- prop_ci(0.6, size = 60, conf_level = 0.90)
  ci95 <- prop_ci(0.6, size = 60, conf_level = 0.95)
  expect_gt(ci95$upper - ci95$lower, ci90$upper - ci90$lower)
})

test_that("prop_ci() validates its arguments", {
  expect_error(prop_ci(1.5, size = 10), "x")
  expect_error(prop_ci(-0.1, size = 10), "x")
  expect_error(prop_ci(0.5, size = 0), "size")
  expect_error(prop_ci(0.5, size = 10, conf_level = 1.2), "conf_level")
  expect_error(prop_ci(0.5, size = 10, conf_level = 1), "conf_level")
})
