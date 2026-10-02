#' Compute the n-th Fibonacci number
#'
#' Computes the n-th Fibonacci number using an iterative C routine.
#' This function exists to prove that the compiled code under `src/`
#' builds, links, and loads correctly on every supported platform.
#' Results are exact for `n <= 78` (the largest Fibonacci number that
#' fits exactly in a double precision float).
#'
#' @param n A single, non-negative integer, at most 78.
#'
#' @return The n-th Fibonacci number as a double.
#'
#' @export
#'
#' @examples
#' fibonacci(10)
#' fibonacci(20)
#'
#' @useDynLib uofgcore, .registration = TRUE
#' @export
fibonacci <- function(n) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 0 || n != floor(n)) {
    stop("`n` must be a single, non-negative integer.", call. = FALSE)
  }
  if (n > 78) {
    stop("`n` must be at most 78: larger results are not exactly representable as doubles.", call. = FALSE)
  }
  .Call(uofgcore_fibonacci, n)
}
