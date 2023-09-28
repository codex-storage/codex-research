test_that(
  "should partition into linearly scaled buckets", {
    samples <- c(1, 100, 500, 800, 850)
        
    partitions <- partition(
      block_array = 1:5, 
      network_size = 4,
      distribution = function(n) samples[1:n]
    )
    
    expect_equal(partitions, list(
      c(1, 2), 
      c(3),
      c(4), 
      c(5))
    )
  }
)
