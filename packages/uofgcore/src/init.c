#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

/*
 * Register native routines as required by "Writing R Extensions",
 * section 5.4.1. Registration removes the corresponding `R CMD check`
 * NOTE and disables dynamic symbol lookup, so only routines listed
 * here can be called from R.
 */
extern SEXP uofgcore_fibonacci(SEXP);

static const R_CallMethodDef call_methods[] = {
    {"uofgcore_fibonacci", (DL_FUNC) &uofgcore_fibonacci, 1},
    {NULL, NULL, 0}
};

void R_init_uofgcore(DllInfo *dll) {
    R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
