#' Keeps list items that match a condition
#' 
#' List version of dplyr's filter verb.
#'
#' @export
filter.list <- function(x, pred, ...) {
  expr <- substitute(pred)
  caller <- rlang::caller_env()
  Filter(function(item) eval(expr, envir = list2env(item, parent = caller)), x)
}

#' Extract a single column from a list of lists
#' 
#' List version of dplyr's pull verb. Note that because not all objects define
#' their own object vectors and because vectors cannot have mixed types, we are
#' not always able to return a vector. So expect vectors only with simple types
#' or types that define their own version of the concatenation operator.
#' 
#' @export
pull.list <- function(x, col, ...) {
  colname <- deparse(substitute(col))
  do.call("c", lapply(x, function(element) {
    value <- element[[colname]]
    if (is.null(value)) NA else value
  }))
}