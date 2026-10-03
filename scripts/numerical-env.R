#!/usr/bin/env Rscript

# Report the numerical environment: R version, BLAS/LAPACK providers,
# threading-related environment variables, and a quick matmul benchmark.
#
# Why: BLAS/LAPACK backends differ in speed AND in rounding behavior
# (thread count changes reduction order). When a numerical result is
# questioned, "which numerical environment produced it" must be
# answerable. CI logs this; run it locally before publishing analyses.
#
# Informational only: always exits 0.

fmt <- function(x) format(x, digits = 3)

message("== R ==            ", R.version$version.string)
message("== Platform ==     ", R.version$platform)

ev <- extSoftVersion()
blas <- if ("BLAS" %in% names(ev)) ev[["BLAS"]] else ""
# R >= 4.6 removed LAPACK from extSoftVersion(); La_library() reports the
# library actually serving LAPACK routines.
lapack <- tryCatch(La_library(), error = function(e) "")
message("== BLAS ==         ", if (nzchar(blas)) blas else "(R internal)")
message("== LAPACK ==       ", if (nzchar(lapack)) lapack else "(R internal)")

for (var in c(
  "OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS",
  "OMP_THREAD_LIMIT", "GOTO_NUM_THREADS"
)) {
  val <- Sys.getenv(var, unset = "(unset)")
  message("== ", var, " ==", strrep(" ", max(0, 24 - nchar(var))), val)
}

message("== Capabilities ==")
for (cap in c("long.double", "ICU", "iconv", "NLS")) {
  message("  ", cap, ": ", capabilities()[[cap]])
}

# Throughput probe: 1000x1000 matmul, ~2 GFLOP.
set.seed(1)
a <- matrix(rnorm(1e6), 1000)
b <- matrix(rnorm(1e6), 1000)
t0 <- proc.time()[["elapsed"]]
invisible(a %*% b)
elapsed <- proc.time()[["elapsed"]] - t0
gflops <- 2e9 / max(elapsed, 1e-9) / 1e9
message("== matmul 1000^2 == ", fmt(elapsed), " s (~", fmt(gflops), " GFLOPS)")
message("numerical environment report complete.")
