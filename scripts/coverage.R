#!/usr/bin/env Rscript

# Compute per-package test coverage for every package in this monorepo
# and enforce a minimum threshold (CI uses this as a merge gate).
#
# Usage:
#   Rscript scripts/coverage.R [threshold]
#
# Arguments:
#   threshold  Minimum acceptable coverage percentage, 0-100.
#              Default: 90. CI calls this with no arguments.

options(warn = 1)

threshold <- 90
cli_args <- commandArgs(trailingOnly = TRUE)
if (length(cli_args) >= 1L) {
  threshold <- suppressWarnings(as.numeric(cli_args[[1L]]))
  if (is.na(threshold) || threshold < 0 || threshold > 100) {
    stop("threshold must be a number between 0 and 100.")
  }
}

script_args <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_args) == 1L) {
  root <- dirname(dirname(normalizePath(sub("^--file=", "", script_args[[1L]]), mustWork = FALSE)))
} else {
  root <- getwd()
}
if (!dir.exists(file.path(root, "packages"))) {
  stop("Could not locate the monorepo root (expected a `packages/` directory).")
}

pkg_paths <- sort(list.dirs(file.path(root, "packages"), recursive = FALSE))
if (length(pkg_paths) == 0L) {
  stop("No packages found under `packages/`.")
}

percentages <- c()
for (path in pkg_paths) {
  pkg <- basename(path)
  message("==== coverage: ", pkg, " ====")
  coverage <- covr::package_coverage(path, quiet = TRUE)
  pct <- covr::percent_coverage(coverage)
  message(sprintf("%s Coverage: %.2f%%", pkg, pct))
  percentages[pkg] <- pct
  print(coverage)
}

below <- names(percentages[percentages < threshold])
if (length(below) > 0L) {
  message(sprintf(
    "\nFAILED: coverage below %.0f%% threshold for: %s",
    threshold, paste(below, collapse = ", ")
  ))
  quit(status = 1L)
}
message(sprintf(
  "\nAll packages meet the %.0f%% coverage threshold.",
  threshold
))
