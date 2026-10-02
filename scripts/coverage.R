#!/usr/bin/env Rscript

# Compute per-package test coverage for every package in this monorepo.
#
# Usage (from anywhere):
#   Rscript scripts/coverage.R

options(warn = 1)

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

for (path in pkg_paths) {
  pkg <- basename(path)
  message("==== coverage: ", pkg, " ====")
  coverage <- covr::package_coverage(path, quiet = TRUE)
  print(covr::percent_coverage(coverage),
        digits = 2)
  message("---- percentage covered ----")
  print(coverage)
}
