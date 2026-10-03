#' Validate an OHLCV price table
#'
#' Enforces the data contract a backtesting pipeline should require
#' *before* any analysis: required Open/High/Low/Close/Volume columns,
#' no missing values, non-negative prices and volumes, and internally
#' consistent bars (high >= low, high >= open/close, low <= open/close).
#'
#' This is deliberately strict: silent data corruption is the classic
#' source of bogus backtest results. Reject early, reject loudly.
#'
#' @param data A data frame with OHLCV columns (default names
#'   `"Open"`, `"High"`, `"Low"`, `"Close"`, `"Volume"`).
#' @param columns Named character vector mapping roles to column names,
#'   for data that uses different naming.
#'
#' @return `data`, invisibly. Stops with an actionable message on the
#'   first violation.
#'
#' @examples
#' ok <- data.frame(
#'   Open = c(100, 101), High = c(102, 103), Low = c(99, 100.5),
#'   Close = c(101, 102), Volume = c(1000, 1200)
#' )
#' validate_ohlcv(ok)
#'
#' \dontrun{
#' # inconsistent bar: High < Close
#' validate_ohlcv(transform(ok, High = c(102, 101)))
#' }
#'
#' @export
validate_ohlcv <- function(data,
                           columns = c(
                             open = "Open", high = "High", low = "Low",
                             close = "Close", volume = "Volume"
                           )) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_names(names(data), must.include = unname(columns))
  checkmate::assert_character(columns, len = 5L, unique = TRUE, any.missing = FALSE)

  get_col <- function(role) data[[columns[[role]]]]

  for (role in c("open", "high", "low", "close")) {
    col <- get_col(role)
    checkmate::assert_numeric(
      col,
      any.missing = FALSE, lower = 0, finite = TRUE,
      .var.name = columns[[role]]
    )
  }
  checkmate::assert_numeric(
    get_col("volume"),
    any.missing = FALSE, lower = 0, finite = TRUE,
    .var.name = columns[["volume"]]
  )

  high <- get_col("high")
  low <- get_col("low")

  if (any(high < low)) {
    stop("Some bars have High < Low.", call. = FALSE)
  }
  for (role in c("open", "close")) {
    col <- get_col(role)
    if (any(high < col)) {
      stop("Some bars have High < ", columns[[role]], ".", call. = FALSE)
    }
    if (any(low > col)) {
      stop("Some bars have Low > ", columns[[role]], ".", call. = FALSE)
    }
  }

  invisible(data)
}
