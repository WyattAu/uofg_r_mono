#!/usr/bin/env Rscript

# Build, test, check, and install every R package in this monorepo.
#
# Packages live under `packages/`. This script:
#   1. discovers them,
#   2. topologically sorts them by their internal Dependencies/Imports,
#   3. for each one (dependencies first):
#        - generates docs/NAMESPACE/man with roxygen2,
#        - runs the testthat suite,
#        - runs `R CMD check --as-cran` (via rcmdcheck),
#        - installs the package into the renv project library,
#   4. exits non-zero if anything failed.
#
# Usage (from anywhere):
#   Rscript scripts/build-all.R
#
# Requirements: the renv project library must be active. Running with
# `Rscript` from inside the repository is enough, because `.Rprofile`
# activates renv automatically. To (re)install the toolchain first:
#   renv::restore()

options(warn = 1)

# ---------------------------------------------------------------------------
# Locate the repository root, regardless of the caller's working directory.
# ---------------------------------------------------------------------------
find_root <- function() {
  args <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(args) == 1L) {
    script <- normalizePath(sub("^--file=", "", args[[1]]), mustWork = FALSE)
    root <- dirname(dirname(script))
  } else {
    root <- getwd()
  }
  if (!dir.exists(file.path(root, "packages"))) {
    stop("Could not locate the monorepo root (expected a `packages/` directory).")
  }
  root
}

root <- find_root()
setwd(root)

pkg_paths <- sort(list.dirs("packages", recursive = FALSE))
if (length(pkg_paths) == 0L) {
  stop("No packages found under `packages/`.")
}
names(pkg_paths) <- basename(pkg_paths)
message("Found ", length(pkg_paths), " package(s): ",
        paste(names(pkg_paths), collapse = ", "))

# ---------------------------------------------------------------------------
# Internal dependency graph + topological sort (dependencies install first).
# ---------------------------------------------------------------------------
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
message("Build order: ", paste(build_order, collapse = " -> "))

# ---------------------------------------------------------------------------
# Per-package pipeline.
# ---------------------------------------------------------------------------
failed <- character()

for (pkg in build_order) {
  path <- pkg_paths[[pkg]]
  message("\n==== ", pkg, " ==========================================")

  # 1. Generate NAMESPACE, man/, and the Collate field from roxygen comments.
  message("-- roxygen2: documenting")
  roxygen2::roxygenise(path, roclets = c("collate", "namespace", "rd"))

  # 2. Unit tests.
  message("-- testthat: running tests")
  testthat::test_local(path, stop_on_failure = TRUE, stop_on_warning = FALSE)

  # 3. Full `R CMD check --as-cran`.
  message("-- R CMD check (as CRAN)")
  check <- rcmdcheck::rcmdcheck(
    path,
    args = c("--no-manual", "--as-cran"),
    error_on = "never"
  )
  print(check)

  # 4. Install into the renv project library so other packages (and the
  #    user's scripts) can use the freshly built version. The absolute
  #    path matters: renv would otherwise parse a relative path like
  #    "packages/uofgcore" as a GitHub remote (user/repo) and try to
  #    download it.
  message("-- renv: installing into project library")
  renv::install(normalizePath(path), prompt = FALSE)

  if (length(check$errors) > 0L) {
    failed <- c(failed, pkg)
  }
}

# ---------------------------------------------------------------------------
# Summary.
# ---------------------------------------------------------------------------
message("\n==== Summary =========================================")
if (length(failed) > 0L) {
  message("FAILED: ", paste(failed, collapse = ", "))
  quit(status = 1L)
}
message("All ", length(build_order), " package(s) built, tested, checked, and installed successfully.")
