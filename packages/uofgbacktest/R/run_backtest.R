#' Run a causal backtest
#'
#' Backtests a position signal against a price series with transaction
#' costs, enforcing the monorepo's backtesting-hygiene rules *in code*:
#'
#' * **Causality enforcement** (default): the signal is re-evaluated on
#'   a truncated history; any difference means the signal looks ahead,
#'   and the backtest is refused.
#' * **One-period lag**: the position returned by the signal for period
#'   `t` is applied to the return from `t` to `t+1` — the signal never
#'   earns the return it was computed on.
#' * **Costs per position change**: `|diff(position)| * cost_per_trade`
#'   is deducted from each period's return.
#'
#' @param prices A numeric vector of prices, or an `xts` series (first
#'   column is used). At least three observations.
#' @param signal A function taking the (truncated) price vector and
#'   returning a numeric position vector of the same length — e.g. `1`
#'   (long) or `0` (flat). The position returned for period `t` is held
#'   over the *next* return.
#' @param initial_capital Non-negative starting capital.
#' @param cost_per_trade Proportional cost charged on the absolute
#'   change in position each period (0.001 = 10 bps).
#' @param check_causality If `TRUE` (default), refuses signals that
#'   change when the future is truncated.
#'
#' @return An object of class `uofg_backtest` with the equity curve,
#'   net returns, positions, costs, and performance metrics.
#'
#' @examples
#' prices <- c(100, 102, 101, 104, 107, 106)
#' always_long <- function(p) rep(1, length(p))
#' bt <- run_backtest(prices, always_long, cost_per_trade = 0)
#' bt
#'
#' @export
run_backtest <- function(prices, signal,
                         initial_capital = 1e5,
                         cost_per_trade = 0.001,
                         check_causality = TRUE) {
  if (xts::is.xts(prices)) {
    # Equity aligns with returns, so the first index point is consumed.
    idx <- zoo::index(prices)[-1L]
    p <- as.numeric(prices[, 1L])
  } else {
    idx <- NULL
    p <- uofgcore::validate_numeric(prices)
  }
  checkmate::assert_function(signal)
  checkmate::assert_number(initial_capital, lower = 0, finite = TRUE)
  checkmate::assert_number(cost_per_trade, lower = 0, finite = TRUE)
  checkmate::assert_flag(check_causality)
  if (length(p) < 3L) {
    stop("`prices` must contain at least three observations.", call. = FALSE)
  }

  positions <- signal(p)
  positions_ok <- is.numeric(positions) && length(positions) == length(p) &&
    all(is.finite(positions))
  if (!positions_ok) {
    stop(
      "`signal` must return a finite numeric vector of length ",
      "length(prices).",
      call. = FALSE
    )
  }

  if (check_causality) {
    positions_trunc <- signal(p[-length(p)])
    trunc_ok <- is.numeric(positions_trunc) &&
      length(positions_trunc) == length(positions) - 1L &&
      isTRUE(all.equal(
        positions_trunc, positions[-length(positions)],
        tolerance = 0
      ))
    if (!trunc_ok) {
      stop(
        "`signal` is not causal: it returns different positions when the ",
        "future is truncated (look-ahead detected).",
        call. = FALSE
      )
    }
  }

  returns <- p[-1L] / p[-length(p)] - 1
  held <- positions[-length(positions)] # position held over each return
  turnover <- abs(diff(positions)) # rebalances at each period start
  costs <- turnover * cost_per_trade
  net <- held * returns - costs

  equity <- initial_capital * cumprod(1 + net)
  drawdown <- equity / cummax(equity) - 1
  sd_net <- stats::sd(net)
  metrics <- list(
    total_return = utils::tail(equity, 1) / initial_capital - 1,
    ann_vol = if (is.na(sd_net)) NA_real_ else sd_net * sqrt(252),
    sharpe = if (is.na(sd_net) || sd_net == 0) {
      NA_real_
    } else {
      mean(net) / sd_net * sqrt(252)
    },
    max_drawdown = min(drawdown),
    n_trades = sum(turnover != 0)
  )

  structure(
    list(
      equity = equity,
      returns = net,
      positions = positions,
      costs = costs,
      index = idx,
      metrics = metrics
    ),
    class = "uofg_backtest"
  )
}

#' @rdname run_backtest
#' @param x An object of class `uofg_backtest`.
#' @param digits Number of digits for printed metrics.
#' @param ... Further arguments passed to or from other methods.
#' @export
print.uofg_backtest <- function(x, digits = 4, ...) {
  m <- x$metrics
  cat(sprintf(
    "uofg_backtest over %d periods (%d trade(s))\n",
    length(x$returns), m$n_trades
  ))
  cat(sprintf("Total return:    %+.2f%%\n", 100 * m$total_return))
  cat(sprintf(
    "Ann. volatility: %s\n",
    if (is.na(m$ann_vol)) "NA" else sprintf("%.2f%%", 100 * m$ann_vol)
  ))
  cat(sprintf(
    "Sharpe (rf=0):   %s\n",
    if (is.na(m$sharpe)) "NA" else format(round(m$sharpe, digits))
  ))
  cat(sprintf("Max drawdown:    %+.2f%%\n", 100 * m$max_drawdown))
  invisible(x)
}

#' @rdname run_backtest
#' @param object An object of class `uofg_backtest`.
#' @export
summary.uofg_backtest <- function(object, ...) {
  data.frame(
    metric = c(
      "total_return", "ann_vol", "sharpe", "max_drawdown",
      "n_trades", "total_costs"
    ),
    value = c(
      object$metrics$total_return,
      object$metrics$ann_vol,
      object$metrics$sharpe,
      object$metrics$max_drawdown,
      object$metrics$n_trades,
      sum(object$costs)
    )
  )
}
