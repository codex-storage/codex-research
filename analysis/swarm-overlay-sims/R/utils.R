quantile_df <- function(x, probs = c(0.25, 0.5, 0.75)) {
  tibble(
    val = quantile(x, probs, na.rm = TRUE),
    quant = probs
  )
}

formatted_factor <- function(x, formatter) {
  values <- unique(x)
  levels <- formatter(values)[order(values)]
  factor(formatter(x), levels)
}

dataset <- function(symbol, block, storage = "csv", reload = FALSE) {
  varname <- deparse(substitute(symbol))
  env <- rlang::caller_env()
  if ((varname %in% names(env)) && !reload) {
    message("Dataset already loaded.")
    return()
  }
  fname <- glue('./data/{varname}.{storage}')
  env[[varname]] <- if (file.exists(fname)) {
    message(glue("Reading cached dataset from {fname}"))
    read_csv(fname, show_col_types = FALSE)
  } else {
    message("Evaluating dataset expression.")
    if (!dir.exists("./data")) dir.create("./data")
    contents <- block
    message(glue("Write dataset {fname}."))
    write_csv(contents, file = fname)
    contents
  }
}