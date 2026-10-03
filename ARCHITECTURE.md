# Architecture

This document explains *why* the monorepo is shaped the way it is. For
day-to-day commands, see the [README](README.md); for contribution rules,
see [CONTRIBUTING](CONTRIBUTING.md).

## Principles

1. **One source of truth per concern.** One `renv.lock` pins the
   toolchain for every package; one script (`scripts/build-all.R`) knows
   how to build; one CI workflow gates merges. Nothing important is
   duplicated per package.
2. **Packages are the unit of reuse, the repo is the unit of
   consistency.** Each package under `packages/` installs, tests, and
   checks independently; renv keeps them all reproducible.
3. **Everything is CLI-first.** `Rscript scripts/...` works identically
   in a terminal, VSCode, Neovim, RStudio, and CI. IDE integrations are
   conveniences layered on top, never requirements.
4. **The pipeline is the contract.** If `Rscript scripts/build-all.R`
   passes locally, CI passes remotely. CI runs exactly what the script
   runs — no special CI-only steps.

## Layout

```
uofg_r_mono/
├── renv.lock                  # THE dependency pin (toolchain, not local pkgs)
├── .Rprofile                  # renv auto-activation + PPM mirror (source URL)
├── .Renviron                  # machine-local overrides (gitignored)
├── .lintr                     # shared lint policy
├── .editorconfig              # shared formatting policy (all editors)
├── .vscode/                   # LSP multi-server, tasks, debug configs
├── .github/workflows/ci.yml   # matrix CI + monthly scheduled run
├── packages/
│   ├── uofgcore/              # no internal dependencies
│   │   ├── .Rprofile          # activates the ROOT renv when opened here
│   │   └── uofgcore.Rproj     # RStudio project (Build tab wired up)
│   └── uofgstats/             # Imports: uofgcore (internal dep demo)
└── scripts/
    ├── build-all.R            # document → test → check → install
    ├── lint-all.R             # lintr gate
    └── coverage.R             # per-package covr report
```

## Dependency graph

```
                renv.lock (roxygen2, testthat, rcmdcheck, lintr, styler, covr)
                                     |
                                     v
  scripts/build-all.R ──topo-sorts──> packages/
                                     |
  uofgbacktest ──> uofgdata ──> uofgstats ──> uofgcore
  (backtesting      (synthetic     (statistics,   (validation,
   engine)           markets)       S3 models)     C interop)
              \______________________________________
                        consumers (your scripts, downstream repos)
```

Internal dependencies are declared with plain `Imports:` in each
package's `DESCRIPTION`. The build script parses those declarations and
topologically sorts the packages, so internal dependencies are always
built and installed before their dependents — no manual ordering, ever.

## Build pipeline

For each package, in dependency order:

| Step | Tool | Fails the build when |
|------|------|----------------------|
| Document | `roxygen2::roxygenise()` | roxygen/markdown errors |
| Test | `testthat::test_local()` | any test failure |
| Check | `rcmdcheck::rcmdcheck(--as-cran)` | any `R CMD check` **error** |
| Install | `renv::install(<abs path>)` | install or load test fails |

Deliberate choices:

- **`NAMESPACE` and `man/` are committed.** Real packages do this; it
  also breaks the chicken-and-egg where `pkgload` refuses to compile a
  package that has no `NAMESPACE` yet.
- **Check errors fail, warnings/notes don't.** The `--as-cran` warning
  about `uofgcore` "not in the CRAN repositories" is inherent to
  monorepos and must not mask real regressions.
- **Local packages are renv-ignored** (`renv/settings.json`), so renv
  never tries to fetch them from CRAN; the pipeline installs them from
  source in dependency order.

## Dependency strategy

- CRAN is proxied through **Posit Package Manager** via its *source*
  URL (`.Rprofile`). renv transforms that URL per platform: binary
  packages where supported (Ubuntu CI), source builds elsewhere.
- The toolchain is intentionally **slim** (58 packages): the pipeline
  needs `roxygen2`, `testthat`, `rcmdcheck`, `lintr`, `styler`, `covr`
  — not the `devtools` meta-tree, whose heavy system-library
  dependencies (e.g. `gert` → `libgit2`) fail on minimal CI runners.
- **Binary vs source is decided by renv**, not us: PPM binaries must
  never be force-installed on machines whose dynamic loader cannot
  resolve their Ubuntu libraries (see README Troubleshooting).

## CI topology

- **`build-and-check`** — matrix over R `release` and `oldrel-1`
  (public templates get users on older R), `fail-fast: false`. After the
  pipeline, `git diff --exit-code` verifies generated files (NAMESPACE,
  man/, Collate) were committed fresh.
- **`lint`** — lintr *and* spelling (`spelling::spell_check_package`,
  project terms in each package's `inst/WORDLIST`).
- **`style`** — runs styler, then fails if `git diff` is non-empty:
  formatting belongs in the commit, not the review.
- **`coverage`** — covr with a hard threshold (90%, set in
  `scripts/coverage.R`); a coverage regression blocks merge.
- **`docs`** — builds the pkgdown sites (one sub-site per package) and
  deploys them to GitHub Pages. `pkgdown` is installed into an isolated
  throwaway library by `scripts/build-docs.R`, keeping the lockfile slim.
- **`release`** — on a `v*` tag, builds every package's source tarball
  and attaches them to a GitHub release.
- **Monthly cron** — runs the full pipeline against the current
  CRAN/R ecosystem, surfacing bitrot between human pushes.
- Required status checks on `main` use the job context names
  (`CI / build-and-check (release)`, `CI / style`, `CI / coverage`, ...),
  so every supported R version and every gate must pass before merge.

## IDE strategy

| Editor | Integration | Key file(s) |
|--------|-------------|-------------|
| Any | CLI tasks, EditorConfig formatting | `scripts/`, `.editorconfig` |
| RStudio | Per-package projects, Build tab, shared renv | `packages/*/*.Rproj`, `packages/*/.Rprofile` |
| VSCode | R LSP (multi-server), tasks, debug configs, extension recommendations | `.vscode/` |
| Neovim | `r_language_server` via any LSP client, treesitter-r; uses the same locked `languageserver` package | `.editorconfig`, `renv.lock` |

The R `languageserver` package (used by both VSCode and Neovim) is
locked in `renv.lock`, so all editors share one LSP version per
project. The per-package `.Rprofile` files source the root
`renv/activate.R`, so opening a package subdirectory anywhere still
activates the monorepo library.

## Decision log

| Decision | Rationale |
|----------|-----------|
| Monorepo over per-package repos | Atomic cross-package changes; one pipeline; one review surface |
| Single shared lockfile | One toolchain truth; per-package lockfiles would drift |
| Slim toolchain, no `devtools` | CI runners lack `libgit2`; 58 vs 161 packages; CI minutes |
| `roxygen2`/`testthat` called directly | Same behavior as devtools wrappers without the tree |
| Coverage threshold as a CI gate | Coverage that isn't enforced only trends downward |
| Style gate via "styler + git diff" | Zero-config (no style config file to maintain), byte-exact enforcement |
| Spelling via `inst/WORDLIST` | Project vocabulary is code-reviewable next to the docs it appears in |
| Defensive per-package `.Rprofile` | R subprocesses during checks start in temp trees; activation must be conditional |
| `rolling_mean` exact-by-default | Cumulative-sum implementations cancel catastrophically at financial magnitudes (verified); correctness outranks O(n) |
| `checkmate` for data contracts | Backtesting demands exhaustive, actionable validation; `validate_numeric` stays as the zero-dep teaching example |
| `Rmpfr` verification harness | Numerical code must be checked against something better than itself |
| MathJax injected post-build | pkgdown 2.2.x BS5 drops math config and its Handlebars template rejects script tags with backslashes |
| Apache-2.0 | Permissive with explicit patent grant; matches repo LICENSE |
| C code in the demo package | Proves the compiled-code toolchain in every CI leg |
