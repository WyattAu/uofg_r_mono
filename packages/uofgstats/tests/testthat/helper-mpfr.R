# High-precision verification harness.
#
# Rmpfr computes reference values in arbitrary precision, so numerical
# routines can be validated against something better than themselves —
# the gold standard for numeric code review. Requires libmpfr (system).

mpfr_window_means <- function(x, window) {
  mx <- Rmpfr::mpfr(x, precBits = 256)
  n <- length(x) - window + 1L
  vapply(seq_len(n), function(i) {
    as.numeric(sum(mx[i:(i + window - 1L)]) / window)
  }, numeric(1))
}
