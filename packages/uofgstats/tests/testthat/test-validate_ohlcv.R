ok <- data.frame(
  Open = c(100, 101),
  High = c(102, 103),
  Low = c(99, 100.5),
  Close = c(101, 102),
  Volume = c(1000, 1200)
)

test_that("validate_ohlcv() accepts consistent data invisibly", {
  expect_invisible(validate_ohlcv(ok))
  expect_identical(validate_ohlcv(ok), ok)
})

test_that("validate_ohlcv() supports custom column naming", {
  custom <- data.frame(O = 100, H = 102, L = 99, C = 101, V = 1000)
  expect_invisible(validate_ohlcv(
    custom,
    columns = c(open = "O", high = "H", low = "L", close = "C", volume = "V")
  ))
})

test_that("validate_ohlcv() rejects broken bars loudly", {
  expect_error(validate_ohlcv(transform(ok, High = c(102, 101))), "High < Close")
  # Low > Close but still <= Open and High: isolates the Close check.
  broken <- transform(ok, Open = c(100, 103), Low = c(99, 102.5))
  expect_error(validate_ohlcv(broken), "Low > Close")
  expect_error(validate_ohlcv(transform(ok, High = c(90, 103))), "High < Low")
  expect_error(validate_ohlcv(transform(ok, Volume = c(1000, -1))), "Volume")
  expect_error(validate_ohlcv(transform(ok, Close = c(101, NA))), "Close")
})

test_that("validate_ohlcv() enforces structure", {
  expect_error(validate_ohlcv(ok[, c("Open", "High")]), "must include")
  expect_error(validate_ohlcv(data.frame()), "at least 1 rows")
  expect_error(validate_ohlcv(ok[0, ]), "at least 1 rows")
})
