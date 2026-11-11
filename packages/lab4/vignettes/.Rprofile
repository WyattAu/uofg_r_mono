# The R extension's "Knit Rmd" command spawns R with its working
# directory set to THIS folder, so the monorepo-root and package-level
# .Rprofile files never load and renv stays inactive. Activate the
# root renv here too (three levels up from vignettes/), so knit
# subprocesses see the locked library (rmarkdown, knitr, lab4).
#
# Hidden dotfiles are excluded from R builds via .Rbuildignore.
local({
  root <- normalizePath(file.path(getwd(), "..", "..", ".."), mustWork = FALSE)
  if (file.exists(file.path(root, "renv", "activate.R"))) {
    Sys.setenv(RENV_PROJECT = root)
    source(file.path(root, "renv", "activate.R"), local = TRUE)
  }
})
