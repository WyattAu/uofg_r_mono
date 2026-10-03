# IDEs (RStudio, VSCode single-package windows, Neovim) may open a package
# subdirectory directly. renv would treat the package as its own project;
# point it at the monorepo root instead so every package shares the ONE
# locked library defined by the root renv.lock, then run the autoloader.
#
# The existence check matters: R subprocesses spawned by `R CMD build`
# and `R CMD INSTALL` (vignette building) also start in directories two
# levels below their working root -- which is a tempdir during checks,
# where `renv/activate.R` does not exist. Skipping activation there is
# correct: those subprocesses inherit the library paths via R_LIBS.
local({
  root <- normalizePath(file.path(getwd(), "..", ".."), mustWork = FALSE)
  if (file.exists(file.path(root, "renv", "activate.R"))) {
    Sys.setenv(RENV_PROJECT = root)
    source(file.path(root, "renv", "activate.R"), local = TRUE)
  }
})
