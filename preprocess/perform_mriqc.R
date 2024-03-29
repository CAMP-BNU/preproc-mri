#!/usr/bin/env Rscript
project_root <- fs::path_dir(box::file())
options(tidyverse.quiet = TRUE)
devtools::load_all(project_root, quiet = TRUE)
context <- "mriqc"
argv <- parse_arguments()
prepare_jobs() |> extract_todo() |> execute_jobs()
