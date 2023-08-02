run_download_simulation <- function(swarm, max_steps, coding_rate) {
  total_blocks <- sum(sapply(swarm, function(node) length(node$storage)))
  required_blocks <- round(total_blocks * coding_rate)
  completed_blocks <- 0
  storage <- c()

  step <- 1  
  stats <- Stats$new()
  while ((step < max_steps) && (completed_blocks < required_blocks)){
    neighbor <- swarm |> select_neighbor()
    storage <- neighbor |> download_blocks(storage)
    
    completed_blocks <- length(storage)
    stats$add_stat(
      step = step,
      selected_neighbor = neighbor$node_id,
      total_blocks = total_blocks,
      required_blocks = required_blocks,
      completed_blocks = completed_blocks
    )
    
    step <- step + 1
  }
  
  stats$as_tibble()
}

select_neighbor <- function(neighborhood) neighborhood[[sample(1:length(neighborhood), size = 1)]]

download_blocks <- function(neighbor, storage) unique(c(neighbor$storage, storage))
