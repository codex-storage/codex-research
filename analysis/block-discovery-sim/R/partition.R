#' Generates a random partition of a block array among a set of nodes. The
#' partitioning follows the supplied distribution.
#' 
#' @param block_array a vector containing blocks
#' @param network_size the number of nodes in the network
#' @param distribution a sample generator which generates a vector of n 
#'    samples when called as distribution(n).
#' 
partition <- function(block_array, network_size, distribution) {
  buckets <- distribution(length(block_array))
  
  # We won't attempt to shift the data, instead just checking that it is 
  # positive.
  stopifnot(all(buckets >= 0))
  
  buckets <- trunc(buckets * (network_size - 1) / max(buckets)) + 1
  sapply(1:network_size, function(i) which(buckets == i))
}
