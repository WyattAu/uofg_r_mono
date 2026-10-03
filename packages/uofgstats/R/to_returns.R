#' Convert prices to returns
#'
#' Converts a price series to simple (arithmetic) or logarithmic returns.
#' Strictly causal: the first observation is consumed, never leaked into
#' an earlier return. Works on plain numeric vectors and on `xts` objects
#' (time index and column names are preserved).
#'
#' @param x A numeric vector or an `xts` object of prices.
#' @param type `"simple"` (default) for arithmetic returns
#'   `x[t] / x[t-1] - 1`, or `"log"` for `diff(log(x))`. Log returns
#'   require strictly positive prices.
#' @param ... Unused; included for S3 dispatch.
#'
#' @return Returns of length `length(x) - 1` (one fewer than prices).
#'   For `xts` input, an `xts` object with the same columns and the
#'   original first timestamp dropped.
#'
#' @examples
#' to_returns(c(100, 101, 99.5, 103))
#' to_returns(c(100, 101, 99.5, 103), type = "log")
#'
#' \dontrun{
#' # with an xts price series:
#' to_returns(xts_prices, type = "log")
#' }
#'
#' @export
to_returns <- function(x, type = c("simple", "log"), ...) {
  UseMethod("to_returns")
}

#' @rdname to_returns
#' @export
to_returns.default <- function(x, type = c("simple", "log"), ...) {
  type <- match.arg(type)
  x <- uofgcore::validate_numeric(x)
  if (length(x) < 2L) {
    stop("`x` must contain at least two prices.", call. = FALSE)
  }
  if (type == "log" && any(x <= 0)) {
    stop("`x` must be strictly positive for log returns.", call. = FALSE)
  }
  if (type == "log") {
    out <- diff(log(x))
  } else {
    out <- x[-1L] / x[-length(x)] - 1
  }
  out
}

#' @rdname to_returns
#' @export
to_returns.xts <- function(x, type = c("simple", "log"), ...) {
  type <- match.arg(type)
  if (!xts::is.xts(x)) {
    stop("`x` must be an xts object.", call. = FALSE)
  }
  # Column-wise: flattening the matrix first would compute a spurious
  # return from the last row of one column to the first of the next.
  core <- apply(as.matrix(x), 2L, function(col) to_returns.default(col, type = type))
  if (is.null(dim(core))) {
    core <- matrix(core, ncol = 1L)
  }
  out <- xts::xts(x = core, order.by = zoo::index(x)[-1L])
  names(out) <- colnames(x)
  out
}
