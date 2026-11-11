#' Synthetic Wellcome Global Monitor population
#'
#' A simulated population of 100,000 people mirroring the Wellcome
#' Global Monitor finding that 20% of people worldwide do not believe
#' the work scientists do benefits people like them. Because the whole
#' population is in hand, the sampling-distribution tasks of Lab 4 can
#' show how sample proportions vary from sample to sample, and how
#' close they sit to the known truth of 80% "Benefits".
#'
#' @format A data frame with 100,000 rows and 1 variable:
#' \describe{
#'   \item{scientist_work}{Response to the question "Do you believe
#'   that the work scientists do benefit people like you?", one of
#'   `"Benefits"` (80,000 people) or `"Doesn't benefit"` (20,000
#'   people).}
#' }
#' @source Deterministic synthetic recreation of the OpenIntro
#'   `global_monitor` teaching dataset (OpenIntro Labs, "Sampling
#'   distributions"); regenerate with
#'   `Rscript data-raw/generate-data.R`.
"global_monitor"

#' Synthetic US adults climate-change population
#'
#' A simulated population of 100,000 US adults mirroring the Pew
#' Research Center finding that roughly 62% of US adults say climate
#' change is currently affecting their local community either a great
#' deal or some. Used for the confidence-interval tasks of Lab 4,
#' where a sample of size 60 must estimate the known truth of 62%
#' "Yes".
#'
#' @format A data frame with 100,000 rows and 1 variable:
#' \describe{
#'   \item{climate_change_affects}{Response to the question "Do you
#'   think climate change is affecting your local community?", one of
#'   `"Yes"` (62,000 people) or `"No"` (38,000 people).}
#' }
#' @source Deterministic synthetic recreation of the OpenIntro
#'   `us_adults` teaching dataset (OpenIntro Labs, "Confidence
#'   intervals"); regenerate with `Rscript data-raw/generate-data.R`.
"us_adults"
