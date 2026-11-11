test_that("sample_props() is deterministic given a seed", {
  a <- sample_props(global_monitor, "scientist_work", "Benefits",
    size = 20, reps = 100, seed = 7
  )
  b <- sample_props(global_monitor, "scientist_work", "Benefits",
    size = 20, reps = 100, seed = 7
  )
  expect_identical(a, b)

  c <- sample_props(global_monitor, "scientist_work", "Benefits",
    size = 20, reps = 100, seed = 8
  )
  expect_false(isTRUE(all.equal(a, c)))
})

test_that("sample_props() returns valid proportions", {
  props <- sample_props(global_monitor, "scientist_work", "Benefits",
    size = 20, reps = 2000, seed = 1
  )
  expect_type(props, "double")
  expect_identical(length(props), 2000L)
  expect_true(all(props >= 0 & props <= 1))
  # Proportions of size-20 samples are multiples of 1/20.
  expect_true(all(abs(props * 20 - round(props * 20)) < 1e-8))
})

test_that("sample_props() centres on the true population proportion", {
  props200 <- sample_props(global_monitor, "scientist_work", "Benefits",
    size = 200, reps = 2000, seed = 1
  )
  expect_lt(abs(mean(props200) - 0.8), 0.02)

  # Complementary successes partition each sample, so the two views
  # of the same draws must sum to exactly 1.
  comp200 <- sample_props(global_monitor, "scientist_work",
    "Doesn't benefit",
    size = 200, reps = 2000, seed = 1
  )
  expect_equal(mean(props200) + mean(comp200), 1)
})

test_that("larger sample size shrinks the spread of the distribution", {
  props20 <- sample_props(global_monitor, "scientist_work", "Benefits",
    size = 20, reps = 2000, seed = 1
  )
  props200 <- sample_props(global_monitor, "scientist_work", "Benefits",
    size = 200, reps = 2000, seed = 1
  )
  expect_lt(sd(props200), sd(props20))
})

test_that("sample_props() leaves global RNG state untouched", {
  # Draw a reference value from a known RNG state; if sample_props()
  # perturbed the global generator, the next draw would differ.
  withr::with_seed(99, reference <- sample.int(1e6, 1))
  set.seed(99)
  invisible(sample_props(global_monitor, "scientist_work", "Benefits",
    size = 20, reps = 5, seed = 3
  ))
  expect_identical(sample.int(1e6, 1), reference)
})

test_that("sample_props() validates its arguments", {
  mini <- data.frame(sw = factor(c("Benefits", "Doesn't")))
  expect_error(sample_props("not a df", "sw", "Benefits", size = 2, reps = 1), "data")
  expect_error(sample_props(mini, "nope", "Benefits", size = 2, reps = 1), "variable")
  expect_error(sample_props(mini, "sw", "Nope", size = 2, reps = 1), "success")
  expect_error(sample_props(mini, "sw", "Benefits", size = 0, reps = 1), "size")
  expect_error(sample_props(mini, "sw", "Benefits", size = 2, reps = -1), "reps")
  expect_error(sample_props(mini, "sw", "Benefits", size = 2, reps = 1, seed = 1.5), "seed")
})
