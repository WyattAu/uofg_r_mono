# uofgstats 0.2.0

## Behavior

* `rolling_mean()` gains a `method` argument. The new default,
  `"exact"`, evaluates each window through R's extended-precision
  `sum()`, fixing catastrophic cancellation drift that
  cumulative-sum implementations exhibit on large-magnitude series
  (e.g. financial prices). `"fast"` delegates to
  `data.table::frollmean()` for O(n) C-speed on well-scaled data.

## New

* `to_returns()`: price series to simple or log returns, with an S3
  method for `xts` objects preserving the time index and column names.
* `validate_ohlcv()`: checkmate-based OHLCV data contract (bar
  consistency, missingness, sign requirements) for backtesting
  pipelines.
* Backtesting hygiene vignette: look-ahead bias, time-based splits,
  transaction costs, and reproducible randomness.

# uofgstats 0.1.0

* Initial release: `rolling_mean()` with shared validation from
  `uofgcore`.
