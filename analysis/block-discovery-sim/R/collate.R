# We do this hack because rsconnect doesn't seem to like us bundling the app
# as a package.

order <- c(
  'R/partition.R',
  'R/stats.R',
  'R/node.R',
  'R/sim.R'
)

library(R6)
library(purrr)
library(tidyverse)

lapply(order, source)

run <- function() {
  rmarkdown::run('./block-discovery-sim.Rmd')
}