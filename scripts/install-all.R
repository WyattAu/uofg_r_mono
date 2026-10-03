#!/usr/bin/env Rscript

# Install every monorepo package into the project library, in internal
# dependency order (topological sort of Imports/Depends).
#
# Used by CI jobs that need the packages installed without the full
# build-all pipeline (e.g. lint), and by developers who want a quick
# install. For the complete document -> test -> check -> install
# pipeline, use scripts/build-all.R.
#
# Usage (from anywhere):
#   Rscript scripts/install-all.R

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
setwd(root)

pkg_paths <- sort(list.dirs("packages", recursive = FALSE))
if (length(pkg_paths) == 0L) {
  stop("No packages found under `packages/`.")
}
names(pkg_paths) <- basename(pkg_paths)

internal_deps <- function(path, known) {
  dcf <- read.dcf(file.path(path, "DESCRIPTION"))
  fields <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(dcf))
  if (length(fields) == 0L) {
    return(character())
  }
  raw <- paste(stats::na.omit(dcf[1L, fields, drop = TRUE]), collapse = ", ")
  found <- unlist(regmatches(raw, gregexpr("[A-Za-z][A-Za-z0-9.]*", raw)))
  intersect(unique(found), known)
}

deps <- lapply(pkg_paths, internal_deps, known = names(pkg_paths))

build_order <- character()
pending <- names(pkg_paths)
while (length(pending) > 0L) {
  ready <- pending[vapply(pending, function(p) all(deps[[p]] %in% build_order), logical(1))]
  if (length(ready) == 0L) {
    stop("Circular internal dependency among: ", paste(pending, collapse = ", "))
  }
  build_order <- c(build_order, ready)
  pending <- setdiff(pending, ready)
}
message("Install order: ", paste(build_order, collapse = " -> "))

for (pkg in build_order) {
  message("-- renv: installing ", pkg)
  renv::install(normalizePath(pkg_paths[[pkg]]), prompt = FALSE)
}
message("All packages installed.")
