#!/usr/bin/env Rscript

# Lint every R package in this monorepo with lintr.
#
# Configuration lives in the repository-root `.lintr` file, which lintr
# discovers automatically. Exits non-zero if any lints are found.
#
# Usage (from anywhere):
#   Rscript scripts/lint-all.R

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
if (length(pkg_paths) == 0L) {
  stop("No packages found under `packages/`.")
}

failed <- character()
for (path in pkg_paths) {
  pkg <- basename(path)
  message("==== linting ", pkg, " ====")
  lints <- lintr::lint_dir(path)
  if (length(lints) > 0L) {
    print(lints)
    failed <- c(failed, pkg)
  } else {
    message("clean")
  }
}

if (length(failed) > 0L) {
  message("\nLint findings in: ", paste(failed, collapse = ", "))
  quit(status = 1L)
}
message("\nAll packages lint clean.")
