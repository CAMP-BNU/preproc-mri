#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
project_root <- fs::path_dir(box::file())
walk(fs::dir_ls(fs::path(project_root, "R")), source)
argv <- parse_arguments("heudiconv")
todo <- list_jobs_whole_heudiconv()
done <- list_jobs_done_heudiconv(argv$rerun_invalidate)
if (!isTRUE(argv$force)) {
  todo <- anti_join(
    todo, done,
    by = c("site", "sid", "session")
  )
}
todo <- filter_subjects(todo, argv)
execute_jobs(todo, "heudiconv", argv)
