Simple Block Discovery Simulator
================================

Simple simulator for understanding of block discovery dynamics.

## Hosted Version

You can access the block discovery simulator on [shinyapps](https://gmega.shinyapps.io/block-discovery-sim/)

## Running

You will need R 4.1.2 with [renv](https://rstudio.github.io/renv/) installed. I also strongly recommend you run this
from [RStudio](https://posit.co/products/open-source/rstudio/) as you will otherwise need to [install pandoc and set it up manually before running](https://stackoverflow.com/questions/28432607/pandoc-version-1-12-3-or-higher-is-required-and-was-not-found-r-shiny).

Once that's cared for and you are in the R terminal (Console in RStudio), you will need to first install deps:

```R
> renv::install()
```

If you are outside RStudio, then you will need to restart your R session. After that, you should load the package:

```R
devtools::load_all()
```

run the tests:

```R
testthat::test_package('blockdiscoverysim')
```

and, if all goes well, launch the simulator:

```R
run()
```
