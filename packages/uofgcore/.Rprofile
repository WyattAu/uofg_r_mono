# IDEs (RStudio, VSCode single-package windows, Neovim) may open a package
# subdirectory directly. renv would treat the package as its own project;
# point it at the monorepo root instead so every package shares the ONE
# locked library defined by the root renv.lock, then run the autoloader.
local({
  root <- normalizePath(file.path(getwd(), "..", ".."), mustWork = TRUE)
  Sys.setenv(RENV_PROJECT = root)
  source(file.path(root, "renv", "activate.R"), local = TRUE)
})
