
# ---- swarm-overlay ----
swarm_overlay <- function(n, d, names = FALSE, directed = FALSE) {
  swarm_overlay_edgelist(n, d) |> 
    as_overlay_graph(names = names, directed = directed)
}

as_overlay_graph <- function(edge_list, names = FALSE, directed = FALSE) {
  igraph::graph_from_data_frame(
    edge_list,
    directed = directed,
    vertices = if (names) tibble(name = 1:max(edge_list$from)) else NULL
  )
}

swarm_overlay_edgelist <- function(n, d) {
  map(2:n, function(i) node_edges(i, d)) |> bind_rows()
}

node_edges <- function(i, d) {
  # When i <= d, we have to connect everything we have.
  if (i <= d) {
    return(tibble(from = i, to = 1:(i - 1)))
  }
  
  tibble(
    from = i,
    to = sample(1:(i - 1), d, replace = FALSE)
  ) 
}

