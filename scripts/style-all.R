#!/usr/bin/env Rscript

# Apply styler to every package in this monorepo (in place).
#
# CI enforces the same thing from the other direction: the `style` job
# styles the tree and fails if `git diff` is non-empty.
#
# Usage (from anywhere):
#   Rscript scripts/style-all.R

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

for (path in sort(list.dirs(file.path(root, "packages"), recursive = FALSE))) {
  message("==== styling ", basename(path), " ====")
  styler::style_pkg(path)
}
message("All packages styled.")
