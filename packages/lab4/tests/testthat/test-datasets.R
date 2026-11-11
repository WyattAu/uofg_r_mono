test_that("global_monitor matches the Wellcome population split", {
  expect_s3_class(global_monitor, "data.frame")
  expect_identical(nrow(global_monitor), 100000L)
  expect_identical(names(global_monitor), "scientist_work")
  props <- prop.table(table(global_monitor$scientist_work))
  expect_equal(unname(props[["Benefits"]]), 0.8)
  expect_equal(unname(props[["Doesn't benefit"]]), 0.2)
})

test_that("us_adults matches the Pew population split", {
  expect_s3_class(us_adults, "data.frame")
  expect_identical(nrow(us_adults), 100000L)
  expect_identical(names(us_adults), "climate_change_affects")
  props <- prop.table(table(us_adults$climate_change_affects))
  expect_equal(unname(props[["Yes"]]), 0.62)
  expect_equal(unname(props[["No"]]), 0.38)
})
