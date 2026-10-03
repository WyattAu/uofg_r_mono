#!/usr/bin/env Rscript

# Spell-check every package's documentation with the spelling package.
#
# Project-specific terms (uofg, renv, pkgdown, ...) belong in each
# package's inst/WORDLIST, one word per line, sorted. Update it with:
#   spelling::update_wordlist(<package path>)
#
# Exits non-zero if any unknown words are found.
#
# Usage (from anywhere):
#   Rscript scripts/spellcheck-all.R

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

failed <- character()
for (path in sort(list.dirs(file.path(root, "packages"), recursive = FALSE))) {
  pkg <- basename(path)
  message("==== spellchecking ", pkg, " ====")
  typos <- spelling::spell_check_package(path, vignettes = TRUE)
  if (nrow(typos) > 0L) {
    print(typos)
    failed <- c(failed, pkg)
  } else {
    message("clean")
  }
}

if (length(failed) > 0L) {
  message("\nSpelling findings in: ", paste(failed, collapse = ", "))
  message("Add genuine terms to inst/WORDLIST (spelling::update_wordlist()); fix the rest.")
  quit(status = 1L)
}
message("\nAll packages spell-check clean.")
