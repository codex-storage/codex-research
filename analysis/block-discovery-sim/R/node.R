Node <- R6Class(
  'Node',
  public = list(
    node_id = NULL,
    storage = NULL,
    
    initialize = function(node_id, storage) {
      self$node_id = node_id
      self$storage = storage
    },
    
    name = function() paste0('node ', self$node_id)
  )
)