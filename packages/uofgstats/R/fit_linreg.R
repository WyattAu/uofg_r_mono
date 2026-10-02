#' Fit a linear model with a light S3 wrapper
#'
#' Wraps [stats::lm()] to demonstrate the full S3 pattern the monorepo
#' recommends for model-like objects: a constructor that validates its
#' inputs, a compact `print()` method, and a `tidy_linreg()` accessor
#' that returns coefficients as a plain data frame (no tidyverse
#' dependencies required).
#'
#' @param formula A modeling `formula`, e.g. `y ~ x`.
#' @param data A data frame containing the variables in `formula`.
#' @param ... Additional arguments passed to [stats::lm()].
#'
#' @return An object of class `uofg_linreg` containing the fitted model,
#'   the formula, and the number of observations used.
#'
#' @export
#'
#' @examples
#' fit <- fit_linreg(y ~ x, data.frame(x = 1:5, y = c(2, 4, 6, 8, 10)))
#' fit
#' tidy_linreg(fit)
fit_linreg <- function(formula, data, ...) {
  if (!inherits(formula, "formula")) {
    stop("`formula` must be a formula.", call. = FALSE)
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (nrow(data) == 0L) {
    stop("`data` must not be empty.", call. = FALSE)
  }

  # Forward `...` with substitute()+eval(): stats::lm() uses non-standard
  # evaluation for arguments like `weights`, and forwarding dots directly
  # from a wrapper fails ("..1 used in an incorrect context") because the
  # expression `w` must be evaluated in the *caller's* frame. Building the
  # full call with substitute() and evaluating it there (a.k.a. base-R
  # injection) is the canonical wrapper pattern; rlang::inject() is the
  # tidyverse equivalent.
  fit <- eval(
    substitute(stats::lm(formula, data = data, ...)),
    parent.frame()
  )
  n_obs <- length(stats::fitted(fit))
  structure(
    list(fit = fit, formula = formula, n_obs = n_obs),
    class = "uofg_linreg"
  )
}

#' @rdname fit_linreg
#' @param x An object of class `uofg_linreg`.
#' @param digits Number of significant digits to print.
#' @export
print.uofg_linreg <- function(x, digits = max(3L, getOption("digits") - 3L), ...) {
  cat(sprintf("uofg_linreg fit on %d observations\n", x$n_obs))
  cat("Formula:", deparse(x$formula)[[1L]], "\n")
  cat("Coefficients:\n")
  print(round(stats::coef(x$fit), digits = digits))
  invisible(x)
}

#' @rdname fit_linreg
#' @param fit An object of class `uofg_linreg`.
#' @export
tidy_linreg <- function(fit) {
  if (!inherits(fit, "uofg_linreg")) {
    stop("`fit` must be a `uofg_linreg` object; call `fit_linreg()` first.", call. = FALSE)
  }
  s <- stats::summary.lm(fit$fit)$coefficients
  data.frame(
    term = rownames(s),
    estimate = s[, "Estimate"],
    std_error = s[, "Std. Error"],
    statistic = s[, "t value"],
    p_value = s[, "Pr(>|t|)"],
    row.names = NULL
  )
}
