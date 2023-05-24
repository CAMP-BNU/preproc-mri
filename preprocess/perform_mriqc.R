#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
project_root <- fs::path_dir(box::file())
walk(fs::dir_ls(fs::path(project_root, "R")), source)
argv <- parse_arguments("mriqc")
jobs <- list_jobs_whole_mriqc() |>
  left_join(
    list_jobs_status_mriqc(argv$rerun_invalidate),
    by = c("subject", "session")
  ) |>
  mutate(status = coalesce(status, "todo")) |>
  extract_todo(argv)
execute_jobs(jobs, "mriqc", argv)
