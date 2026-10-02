# uofg_r_mono

[![CI](https://github.com/WyattAu/uofg_r_mono/actions/workflows/ci.yml/badge.svg)](https://github.com/WyattAu/uofg_r_mono/actions/workflows/ci.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

An R **monorepo** template: multiple R packages live in one repository, sharing a single
[`renv`](https://rstudio.github.io/renv/) lockfile, one CI pipeline, and one build script.

- License: [Apache-2.0](LICENSE)

## Using this template

To turn this repository into your own project:

1. **Rename the packages**: copy or rename folders under `packages/`, then
   update the `Package:` and `Title:` fields in each `DESCRIPTION`, the
   `useDynLib()`/`@useDynLib` references (only if you keep compiled code),
   and `library()` calls in `tests/testthat.R`.
2. **Point the metadata at your repository**: update the `URL:` and
   `BugReports:` fields in every `DESCRIPTION`.
3. **Reset the dependency lock** (optional, for a minimal toolchain):
   delete `renv.lock`, then run `renv::init(bare = TRUE)` and reinstall
   only the tools you need, e.g. `renv::install(c("devtools", "rcmdcheck"))`,
   followed by `renv::snapshot()`.
4. **Update this README** — everything between the badges and the
   Troubleshooting section describes the template itself.

## Repository layout

```
uofg_r_mono/
├── .github/workflows/ci.yml   # CI: restores renv, then builds/checks every package
├── .Rprofile                  # activates renv automatically in every R session
├── .Renviron                  # machine-local renv overrides (gitignored)
├── renv.lock                  # pinned package versions — commit this
├── renv/                      # renv internals; renv/library is machine-local
├── packages/
│   ├── uofgcore/              # base package (incl. compiled C code under src/)
│   └── uofgstats/             # depends on uofgcore (demos internal deps)
├── scripts/
│   └── build-all.R            # document → test → R CMD check → install, in dep order
└── README.md
```

## Packages

| Package      | Description                                                        |
|--------------|--------------------------------------------------------------------|
| `uofgcore`   | Shared helpers (`greet()`, `validate_numeric()`) and a compiled C routine (`fibonacci()`) proving the native-code toolchain. |
| `uofgstats`  | Statistical utilities (`rolling_mean()`); imports `uofgcore` to demonstrate intra-monorepo dependencies. |

## Prerequisites

- R >= 4.1 (developed against 4.6)
- A C compiler toolchain (gcc/clang + make) — only needed because `uofgcore` contains compiled code
- `git`

## Getting started

```r
# from the repository root (or after opening the folder in RStudio):
renv::restore()   # installs the exact toolchain recorded in renv.lock
```

The `.Rprofile` activates renv automatically, so any R session started inside the
repository already uses the project library — no `library()` bookkeeping needed.

## Day-to-day workflow

Build, test, check, and install **all** packages in dependency order:

```sh
Rscript scripts/build-all.R
```

> Note: `R CMD check --as-cran` reports a *"Strong dependencies not in the CRAN
> ... repositories: uofgcore"* warning for packages that depend on other
> monorepo packages. That is expected — internal dependencies are not on
> CRAN — and does not fail the build.

Or work on a single package interactively:

```r
roxygen2::roxygenise("packages/uofgcore")  # regenerate man/ + NAMESPACE
testthat::test_local("packages/uofgcore")  # run testthat suite
rcmdcheck::rcmdcheck("packages/uofgstats") # R CMD check --as-cran
renv::install("packages/uofgstats")        # install into the project library
```

> Prefer the `devtools`/`usethis` interactive toolkit? It is intentionally
> *not* locked in `renv.lock` (its dependency tree is heavy and drags in
> system libraries CI does not ship). Install it locally without locking
> it in: `renv::install("devtools")` — just don't `renv::snapshot()` it.

## Adding a new package

1. Create `packages/<yourpkg>/` with at least a `DESCRIPTION`, `R/` sources with
   roxygen comments, and `tests/`. The easiest way is to copy an existing package
   folder and adjust `DESCRIPTION`.
2. To depend on another package in this repo, list it under `Imports:` — the build
   script topologically sorts packages, so internal dependencies resolve in the
   right order automatically.
3. Add the package name to `renv::settings$ignored.packages(...)` (one-time, in
   your session) so renv never tries to fetch it from CRAN, then run
   `renv::snapshot()` to record the toolchain state in `renv.lock`.

## How renv works in this repo

- `renv.lock` is committed and pins every dependency, including the toolchain
  (`roxygen2`, `testthat`, `rcmdcheck`, `lintr`, `styler`, `covr`).
- `renv/library/` is machine-local and gitignored; recreate it with `renv::restore()`.
- The monorepo's own packages are registered as *ignored packages*, so renv never
  tries to install them from CRAN — `scripts/build-all.R` installs them from source.
- CRAN is proxied through Posit Public Package Manager (see `.Rprofile`) so CI
  installs fast binary packages; unsupported platforms transparently fall back to
  building from source.
- New dependencies: `renv::install("pkg")`, then `renv::snapshot()` and commit
  `renv.lock`.

## Installing the packages

Clone and build (recommended — runs the full pipeline):

```sh
git clone https://github.com/WyattAu/uofg_r_mono && cd uofg_r_mono
Rscript -e 'renv::restore()'
Rscript scripts/build-all.R
```

Or install directly from GitHub (install `uofgcore` first — it is not on
CRAN, so dependency resolution cannot fetch it for you):

```r
# install.packages("remotes")
remotes::install_github("WyattAu/uofg_r_mono/packages/uofgcore")
remotes::install_github("WyattAu/uofg_r_mono/packages/uofgstats")
```

## Maintenance

The lockfile pins dependency versions and will rot slowly as CRAN moves.
Once a month (or before important work):

```r
renv::update()     # move every locked package to its latest allowed version
Rscript scripts/build-all.R
Rscript scripts/lint-all.R
renv::snapshot()   # record the new state, then commit renv.lock
```

CI also runs on a monthly schedule against the current CRAN/R ecosystem,
so bitrot is surfaced even when nobody touches the repository.

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push/PR
(and monthly on a schedule):

1. `r-lib/actions/setup-r` — matrix over R `release` and `oldrel-1`,
2. `r-lib/actions/setup-renv` restoring `renv.lock` (with caching),
3. `Rscript scripts/build-all.R` — documents, tests, `R CMD check --as-cran`, and
   installs every package; the job fails on any error or test failure.

A separate `lint` job runs `scripts/lint-all.R` on `release`.

## Troubleshooting

- **`libuv.so.1: cannot open shared object file`** when installing packages on
  CachyOS/Arch with a nix-provided R: renv downloaded Ubuntu binaries from the
  Posit mirror, whose shared-library dependencies the nix loader cannot resolve.
  The gitignored `.Renviron` in this repo already sets
  `RENV_CONFIG_PPM_ENABLED=false` to force source builds; recreate it if missing.
- **`fatal error: curl/curl.h` (or other system headers) during package installs**
  with a nix-provided R: R's baked-in nix compilers do not search `/usr/include`.
  The gitignored `Makevars.local` (referenced via `R_MAKEVARS_USER` in `.Renviron`)
  redirects R to the system compilers; recreate it if missing.
- **Missing system libraries during source installs** (`libcurl`, `libgit2`,
  `openssl`, ...): install the corresponding development packages with your
  system package manager.
