#!/usr/bin/env Rscript
project_root <- fs::path_dir(box::file())
options(tidyverse.quiet = TRUE)
devtools::load_all(project_root)
context <- "mriqc"
perform_workflow()
