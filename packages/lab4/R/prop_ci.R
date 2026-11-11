#' Wald confidence interval for a proportion
#'
#' Computes the classical (Wald) confidence interval for a population
#' proportion: `estimate +/- z* sqrt(estimate * (1 - estimate) / size)`,
#' where `z*` is the critical value with `conf_level` central mass
#' (1.96 at 95% confidence, 1.64 at 90%).
#'
#' @param x Sample proportion, a number between 0 and 1.
#' @param size Positive integer, sample size the proportion was
#'   computed from.
#' @param conf_level Confidence level, a number between 0 and 1.
#'   Default 0.95.
#'
#' @return A one-row data frame with columns `estimate`, `conf_level`,
#'   `critical_value`, `lower`, and `upper`.
#'
#' @examples
#' # 90% interval for a sample proportion of 0.75 from n = 20
#' prop_ci(0.75, size = 20, conf_level = 0.90)
#' @export
prop_ci <- function(x, size, conf_level = 0.95) {
  checkmate::assert_number(x, lower = 0, upper = 1, finite = TRUE)
  checkmate::assert_int(size, lower = 1L)
  checkmate::assert_number(conf_level, lower = 0, upper = 1)
  checkmate::assert_true(conf_level < 1)

  z_star <- stats::qnorm((1 + conf_level) / 2)
  se <- sqrt(x * (1 - x) / size)
  data.frame(
    estimate = x,
    conf_level = conf_level,
    critical_value = z_star,
    lower = x - z_star * se,
    upper = x + z_star * se
  )
}
