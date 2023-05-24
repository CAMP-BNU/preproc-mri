#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
project_root <- fs::path_dir(box::file())
walk(fs::dir_ls(fs::path(project_root, "R")), source)
argv <- parse_arguments("heudiconv")
jobs <- list_jobs_whole_heudiconv() |>
  left_join(
    list_jobs_status_heudiconv(argv$rerun_invalidate),
    by = c("site", "sid", "session"),
    suffix = c(".orig", ".anon")
  ) |>
  mutate(status = coalesce(status, "todo")) |>
  extract_todo(argv)
execute_jobs(jobs, "heudiconv", argv)
