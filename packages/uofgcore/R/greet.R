#' Greet a person by name
#'
#' Returns a friendly greeting. Kept deliberately small: it is the
#' "hello world" of this monorepo template and shows the expected
#' structure of a documented, tested, exported function.
#'
#' @param name A single character string with the name of the person
#'   to greet.
#'
#' @return A character string of the form `"Hello, <name>!"`.
#'
#' @export
#'
#' @examples
#' greet("World")
greet <- function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name)) {
    stop("`name` must be a single, non-missing character string.", call. = FALSE)
  }
  paste0("Hello, ", name, "!")
}
