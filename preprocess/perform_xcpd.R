#!/usr/bin/env Rscript
project_root <- fs::path_dir(box::file())
options(tidyverse.quiet = TRUE)
devtools::load_all(project_root, quiet = TRUE)
context <- "xcpd"
argv <- parse_arguments()
file_xcpd_jobs <- fs::path(
  path_log,
  str_glue("xcpd_{argv$config_params}.tsv")
)
prepare_jobs() |> extract_todo() |> execute_jobs()
