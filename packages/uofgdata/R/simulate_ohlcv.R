#' Simulate reproducible OHLCV market data
#'
#' Generates a daily OHLCV series from a geometric Brownian motion for
#' closes, with intraday spans for highs/lows and lognormal volume.
#' The generator is **deterministic given `seed`**: the same arguments
#' always produce bit-identical data, so examples, tests, and vignettes
#' never depend on external sources.
#'
#' Output satisfies the monorepo data contract by construction —
#' [uofgstats::validate_ohlcv()] passes on every generated series
#' (high >= max(open, close), low <= min(open, close), positive
#' volume).
#'
#' @param n_days Positive integer, number of trading days to simulate.
#' @param start A `Date` (or coercible) for the first observation.
#' @param start_price Positive number, the day-one opening price.
#' @param drift Daily arithmetic drift of the log-price process.
#' @param vol Daily volatility of the log-price process.
#' @param seed Integer seed for the random number generator. The seed
#'   is applied with `withr::with_seed()` so the global RNG state is
#'   untouched.
#'
#' @return An `xts` object with columns `Open`, `High`, `Low`,
#'   `Close`, `Volume` and a daily date index.
#'
#' @examples
#' mkt <- simulate_ohlcv(n_days = 10)
#' uofgstats::validate_ohlcv(as.data.frame(mkt))
#'
#' @export
simulate_ohlcv <- function(n_days = 250L,
                           start = as.Date("2026-01-01"),
                           start_price = 100,
                           drift = 0.0003,
                           vol = 0.01,
                           seed = 1L) {
  checkmate::assert_int(n_days, lower = 2L)
  checkmate::assert_date(start, any.missing = FALSE, len = 1L)
  checkmate::assert_number(start_price, lower = 0, finite = TRUE)
  checkmate::assert_number(drift, finite = TRUE)
  checkmate::assert_number(vol, lower = 0, finite = TRUE)
  checkmate::assert_int(seed, lower = 0L)

  withr::with_seed(seed, {
    log_ret <- stats::rnorm(n_days - 1L, mean = drift - vol^2 / 2, sd = vol)
    close <- start_price * exp(cumsum(c(0, log_ret)))
    open <- c(start_price, utils::head(close, -1L))

    # Intraday spans keep High >= max(Open, Close) and Low <=
    # min(Open, Close) by construction: exp(span) >= 1.
    span <- abs(stats::rnorm(n_days, sd = vol / 2))
    high <- pmax(open, close) * exp(span)
    low <- pmin(open, close) * exp(-span)
    volume <- round(1e6 * exp(stats::rnorm(n_days, sd = 0.5)))

    out <- xts::xts(
      x = data.frame(
        Open = open, High = high, Low = low,
        Close = close, Volume = volume
      ),
      order.by = seq(start, by = "day", length.out = n_days)
    )
  })

  # Data contract holds by construction; assert it anyway so a change
  # to the generator can never silently produce invalid bars.
  uofgstats::validate_ohlcv(as.data.frame(out))
  out
}
