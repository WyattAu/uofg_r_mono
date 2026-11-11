#!/usr/bin/env Rscript

# Regenerate the lazy-loaded lab4 datasets (data/*.rda) from the
# population definitions used in Lab 4. Deterministic: the populations
# are built by ordered replication, no RNG is involved, so the same
# script always produces identical datasets.
#
# Usage (from anywhere):
#   Rscript packages/lab4/data-raw/generate-data.R

options(warn = 1)

script_args <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_args) == 1L) {
  pkg_dir <- dirname(dirname(normalizePath(
    sub("^--file=", "", script_args[[1L]]),
    mustWork = FALSE
  )))
} else {
  pkg_dir <- getwd()
}

global_monitor <- data.frame(
  scientist_work = factor(
    rep(c("Benefits", "Doesn't benefit"), times = c(80000L, 20000L)),
    levels = c("Benefits", "Doesn't benefit")
  )
)

us_adults <- data.frame(
  climate_change_affects = factor(
    rep(c("Yes", "No"), times = c(62000L, 38000L)),
    levels = c("Yes", "No")
  )
)

stopifnot(
  all.equal(
    as.numeric(prop.table(table(global_monitor$scientist_work))),
    c(0.8, 0.2)
  ),
  all.equal(
    as.numeric(prop.table(table(us_adults$climate_change_affects))),
    c(0.62, 0.38)
  )
)

data_dir <- file.path(pkg_dir, "data")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
save(global_monitor,
  file = file.path(data_dir, "global_monitor.rda"),
  compress = "bzip2"
)
save(us_adults,
  file = file.path(data_dir, "us_adults.rda"),
  compress = "bzip2"
)
message("wrote ", file.path(data_dir, "global_monitor.rda"))
message("wrote ", file.path(data_dir, "us_adults.rda"))
