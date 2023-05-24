#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
project_root <- fs::path_dir(box::file())
walk(fs::dir_ls(fs::path(project_root, "R")), source)
argv <- parse_arguments("fmriprep")
todo <- list_jobs_whole_fmriprep(argv$skip_session_check)
done <- list_jobs_done_fmriprep(argv$rerun_invalidate, argv$skip_session_check)
if (!isTRUE(argv$force)) {
  todo <- anti_join(todo, done, by = "subject")
}
todo <- filter_subjects(todo, argv)
execute_jobs(todo, "fmriprep", argv)
