#' Draw repeated sample proportions from a population
#'
#' Simulates `reps` samples of size `size` from a categorical
#' population and returns the proportion of each sample that equals
#' `success`. The result is a draw from the sampling distribution of
#' p-hat: many samples of the same size from the same population show
#' how much the sample proportion varies from sample to sample.
#'
#' Sampling with replacement (the default) matches the lab setup,
#' where the population plays the role of the truth and each draw
#' should behave like an independent Bernoulli trial.
#'
#' @param data A data frame holding the population.
#' @param variable Name (string) of the categorical column to sample.
#' @param success Value (string) counted as a success.
#' @param size Positive integer, sample size per draw.
#' @param reps Positive integer, number of samples to draw.
#' @param replace Logical, sample with replacement. Default `TRUE`.
#' @param seed Integer seed. When supplied, the draws are
#'   deterministic and the global RNG state is left untouched (via
#'   `withr::with_seed()`), so vignettes and tests stay reproducible.
#'
#' @return A numeric vector of length `reps` holding the sample
#'   proportions.
#'
#' @examples
#' # One sample of 20 people, proportion who say scientists' work helps
#' sample_props(global_monitor, "scientist_work", "Benefits",
#'   size = 20, reps = 1, seed = 42
#' )
#'
#' # The sampling distribution of p-hat for n = 20
#' p_hat <- sample_props(global_monitor, "scientist_work", "Benefits",
#'   size = 20, reps = 2000, seed = 42
#' )
#' hist(p_hat)
#' @export
sample_props <- function(data, variable, success, size, reps,
                         replace = TRUE, seed = NULL) {
  checkmate::assert_data_frame(data)
  checkmate::assert_string(variable)
  checkmate::assert_choice(variable, colnames(data))
  checkmate::assert_string(success)
  checkmate::assert_subset(success, unique(as.character(data[[variable]])))
  checkmate::assert_int(size, lower = 1L)
  checkmate::assert_int(reps, lower = 1L)
  checkmate::assert_flag(replace)
  checkmate::assert_int(seed, lower = 0L, null.ok = TRUE)

  values <- data[[variable]]
  draw_p_hat <- function() {
    draw <- sample(values, size = size, replace = replace)
    mean(draw == success)
  }
  if (is.null(seed)) {
    vapply(seq_len(reps), function(i) draw_p_hat(), numeric(1))
  } else {
    withr::with_seed(
      seed,
      vapply(seq_len(reps), function(i) draw_p_hat(), numeric(1))
    )
  }
}
