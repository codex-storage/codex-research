# ---- disseminate-broadcast ----
disseminate_broadcast <- function(overlay, sources) {
  dissemination_paths <- lapply(
    sources,
    function(source) bfs(
      overlay, 
      root = V(overlay)[name == source], 
      dist = TRUE
    )$dist
  )
  do.call(pmin, dissemination_paths)
}