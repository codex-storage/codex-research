quantile_df <- function(x, probs = c(0.25, 0.5, 0.75)) {
  tibble(
    val = quantile(x, probs, na.rm = TRUE),
    quant = formatted_factor(probs, function(x) glue('{x*100}'))
  )
}

formatted_factor <- function(x, formatter) {
  values <- unique(x)
  levels <- formatter(values)[order(values)]
  factor(formatter(x), levels)
}

.CODEC = list(
  csv = list(
    read = function(file) read_csv(file = file, show_col_types = FALSE),
    write = write_csv
  ),
  rds = list(
    read = read_rds,
    write = write_rds
  )
)

.CODEC$csv.bz2 = .CODEC$csv

dataset <- function(symbol, block, storage = "csv", reload = FALSE, recalc = FALSE) {
  varname <- deparse(substitute(symbol))
  env <- rlang::caller_env()
  if ((varname %in% names(env)) && !reload) {
    message("Dataset already loaded.")
    return()
  }
  fname <- glue('./data/{varname}.{storage}')
  env[[varname]] <- if (file.exists(fname) && !recalc) {
    message(glue("Reading cached dataset from {fname}"))
    .CODEC[[storage]]$read(file = fname)
  } else {
    message("Evaluating dataset expression.")
    if (!dir.exists("./data")) dir.create("./data")
    contents <- block
    message(glue("Write dataset {fname}."))
    .CODEC[[storage]]$write(content, file = fname)
    contents
  }
}

timeit <- function(block) {
  start <- Sys.time()
  result <- block
  print(glue('Took {Sys.time() - start} seconds.'))
  result
}