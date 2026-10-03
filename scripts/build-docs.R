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
  # Shared root config (_pkgdown.yml: mathjax, template, ...) merged with
  # per-package overrides.
  shared <- if (file.exists("_pkgdown.yml")) yaml::read_yaml("_pkgdown.yml") else list()
  shared$destination <- NULL
  override <- c(list(destination = dest), shared)
  pkgdown::build_site(path, override = override, preview = FALSE)
  titles[[pkg]] <- read.dcf(file.path(path, "DESCRIPTION"), "Title")[[1L]]
}

# --- landing page -----------------------------------------------------------
# A quiet coverage attempt: nice-to-have, never fatal.
coverage_note <- tryCatch({
  out <- vapply(pkg_paths, function(path) {
    pct <- covr::percent_coverage(covr::package_coverage(path, quiet = TRUE))
    sprintf("%s: %.1f%%", basename(path), pct)
  }, character(1))
  paste0("<p><strong>Coverage:</strong> ", paste(out, collapse = " &middot; "),
         "</p>")
}, error = function(e) "")

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
  coverage_note,
  cards,
  "</body></html>"
)
writeLines(landing, file.path(site_dir, "index.html"))

# --- inject MathJax into every built page -----------------------------------
# pkgdown 2.2.x's Bootstrap-5 template does not emit a math renderer
# (its BS3 template does), and its Handlebars rmd template cannot
# compile script tags containing backslashes. Post-processing the built
# HTML is version-proof. Single-$ delimiters are enabled so vignette
# prose can use standard LaTeX notation.
mathjax <- c(
  "<script>",
  "window.MathJax = window.MathJax || {};",
  "window.MathJax.tex = window.MathJax.tex || {};",
  "var bs = String.fromCharCode(92);",
  'window.MathJax.tex.inlineMath = [["$", "$"], [bs + "(", bs + ")"]];',
  'window.MathJax.tex.displayMath = [["$$", "$$"], [bs + "[", bs + "]"]];',
  "</script>",
  '<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>'
)
inject <- paste(mathjax, collapse = "\n")

pages <- list.files(site_dir, pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
for (page in pages) {
  txt <- readLines(page, warn = FALSE)
  hit <- grep("</head>", txt, fixed = TRUE)
  if (length(hit) > 0L && !any(grepl("MathJax-script", txt, fixed = TRUE))) {
    writeLines(append(txt, inject, after = hit[[1L]] - 1L), page, useBytes = TRUE)
  }
}

# --- coverage badge endpoint ------------------------------------------------
# shields.io endpoint JSON at docs/_site/coverage.json, refreshed on every
# docs deploy. Quiet failure: a coverage hiccup must not break the deploy.
coverage_json <- tryCatch({
  pct <- vapply(pkg_paths, function(path) {
    covr::percent_coverage(covr::package_coverage(path, quiet = TRUE))
  }, numeric(1))
  sprintf('{"schemaVersion":1,"label":"coverage","message":"%.1f%%"}', mean(pct))
}, error = function(e) {
  message("coverage badge skipped: ", conditionMessage(e))
  NULL
})
if (!is.null(coverage_json)) {
  writeLines(coverage_json, file.path(site_dir, "coverage.json"))
}

message("Site assembled under ", site_dir)
