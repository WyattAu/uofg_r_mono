#' Compute a trailing rolling mean
#'
#' Computes the mean of `x` over trailing windows. **Strictly causal**:
#' window `i` uses only observations `i - window + 1` through `i`, so
#' the function is safe for backtesting (no look-ahead).
#'
#' @section Numerical accuracy:
#' The `exact` method evaluates each window's mean through R's `sum()`,
#' which accumulates in extended (long double) precision. Each window is
#' therefore accurate independently of the others: no accumulated drift,
#' regardless of series length or magnitude. Cost is O(n * window).
#'
#' The `fast` method delegates to `data.table::frollmean()` (O(n),
#' C-optimized, online algorithm). It can lose precision on adversarial
#' inputs — long series mixing very large and very small magnitudes —
#' where the running-sum representation cancels catastrophically. Use
#' `exact` when correctness at extreme magnitudes matters (the default);
#' use `fast` for speed on well-scaled data.
#'
#' @param x A numeric vector.
#' @param window A single positive integer, the window size. Must not
#'   exceed `length(x)`.
#' @param method Character, one of `"exact"` (default) or `"fast"`.
#'   See *Numerical accuracy*.
#'
#' @return A numeric vector of length `length(x) - window + 1` where
#'   element `i` is `mean(x[seq.int(i, i + window - 1)])`.
#'
#' @references
#' Higham, N. J. (2002). *Accuracy and Stability of Numerical Algorithms*
#' (2nd ed.), SIAM — chapter 4 covers summation error bounds and the
#' catastrophic cancellation this function's `exact` method avoids.
#'
#' @export
#'
#' @examples
#' rolling_mean(c(1, 2, 3, 4, 5), 2)
#' rolling_mean(c(1, 2, 3, 4, 5), 5, method = "fast")
rolling_mean <- function(x, window, method = c("exact", "fast")) {
  method <- match.arg(method)
  x <- uofgcore::validate_numeric(x)
  is_bad_window <- !is.numeric(window) || length(window) != 1L ||
    is.na(window) || window < 1 || window != floor(window)
  if (is_bad_window) {
    stop("`window` must be a single positive integer.", call. = FALSE)
  }
  if (window > length(x)) {
    stop("`window` must not exceed `length(x)`.", call. = FALSE)
  }

  n <- length(x) - window + 1L
  if (method == "exact") {
    # Window-local evaluation: sum() accumulates in extended precision,
    # so there is no cross-window drift (see the accuracy section above).
    out <- vapply(seq_len(n), function(i) mean(x[i:(i + window - 1L)]), numeric(1))
  } else {
    # frollmean() returns a length(x) vector with leading NA padding;
    # trim it so both methods return identical-length results.
    out <- utils::tail(
      as.numeric(data.table::frollmean(x, n = window, algo = "fast", na.rm = FALSE)),
      n
    )
  }
  out
}
