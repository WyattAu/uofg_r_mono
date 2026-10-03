#!/usr/bin/env Rscript

# Build the pkgdown documentation site for every package in this monorepo
# and assemble them under docs/_site/ with a small landing page.
#
# pkgdown (and its heavy dependency tree) is installed into an ISOLATED
# throwaway library instead of the renv project library, so the committed
# renv.lock stays slim -- see ARCHITECTURE.md, "Dependency strategy".
#
# Expects the monorepo packages to be installed already (the Docs CI
# workflow runs scripts/build-all.R first; locally, just run it yourself).
#
# Usage (from anywhere):
#   Rscript scripts/build-docs.R

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

site_dir <- file.path("docs", "_site")
unlink(site_dir, recursive = TRUE)
dir.create(site_dir, recursive = TRUE, showWarnings = FALSE)

# --- install pkgdown into an isolated, disposable library ------------------
doc_lib <- file.path(tempdir(), "doclib")
dir.create(doc_lib, recursive = TRUE, showWarnings = FALSE)
message("Installing pkgdown into isolated library: ", doc_lib)
renv::install("pkgdown", library = doc_lib, prompt = FALSE)
.libPaths(c(doc_lib, .libPaths()))

# --- build one site per package --------------------------------------------
pkg_paths <- sort(list.dirs("packages", recursive = FALSE))
if (length(pkg_paths) == 0L) {
  stop("No packages found under `packages/`.")
}
titles <- character()

for (path in pkg_paths) {
  pkg <- basename(path)
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package `", pkg, "` is not installed; run scripts/build-all.R first.")
  }
  message("==== pkgdown: ", pkg, " ====")
  # Absolute destination: pkgdown resolves relative paths against the
  # *package* directory, not the current working directory.
  dest <- file.path(root, "docs", "_site", pkg)
  pkgdown::build_site(path, override = list(destination = dest), preview = FALSE)
  titles[[pkg]] <- read.dcf(file.path(path, "DESCRIPTION"), "Title")[[1L]]
}

# --- landing page -----------------------------------------------------------
cards <- vapply(names(titles), function(pkg) {
  sprintf(
    '<a class="card" href="%s/"><h2>%s</h2><p>%s</p></a>\n',
    pkg, pkg, htmltools::htmlEscape(titles[[pkg]])
  )
}, character(1))

landing <- c(
  "<!DOCTYPE html>",
  '<html lang="en"><head><meta charset="utf-8">',
  "<title>uofg_r_mono documentation</title>",
  "<style>",
  "  body { font-family: system-ui, sans-serif; max-width: 46rem; margin: 3rem auto; padding: 0 1rem; }",
  "  .card { display: block; border: 1px solid #d0d7de; border-radius: 8px; padding: 1rem 1.25rem; margin: 1rem 0; text-decoration: none; color: inherit; }",
  "  .card:hover { border-color: #0969da; }",
  "  .card h2 { margin: 0 0 0.25rem; color: #0969da; }",
  "  .card p { margin: 0; color: #57606a; }",
  "</style></head><body>",
  "<h1>uofg_r_mono</h1>",
  "<p>Reference documentation for the packages in this monorepo.</p>",
  cards,
  "</body></html>"
)
writeLines(landing, file.path(site_dir, "index.html"))

message("Site assembled under ", site_dir)
