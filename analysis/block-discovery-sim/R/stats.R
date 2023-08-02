Stats <- R6Class(
  'Stats',
  public = list(
    stats = NULL,
    
    initialize = function() {
      self$stats = list(list())
    },
    
    add_stat = function(...) {
      self$stats <- c(self$stats, list(rlang::dots_list(...)))
      self
    },
    
    as_tibble = function() purrr::map_df(self$stats, as_tibble)
  )
)