#include <R.h>
#include <Rinternals.h>

/*
 * Iteratively compute the n-th Fibonacci number.
 *
 * The R wrapper validates the input; this layer only re-checks the
 * bounds as a defensive measure. Results are exact for n <= 78.
 */
SEXP uofgcore_fibonacci(SEXP n_sexp) {
    if (!isReal(n_sexp) || length(n_sexp) != 1) {
        error("`n` must be a single double.");
    }

    const int n = (int) REAL(n_sexp)[0];
    if (n < 0 || n > 78) {
        error("`n` must be between 0 and 78.");
    }

    double a = 0.0;
    double b = 1.0;
    for (int i = 0; i < n; i++) {
        const double next = a + b;
        a = b;
        b = next;
    }

    SEXP out = PROTECT(Rf_ScalarReal(a));
    UNPROTECT(1);
    return out;
}
