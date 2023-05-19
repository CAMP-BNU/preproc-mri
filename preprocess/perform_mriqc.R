#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
project_root <- fs::path_dir(box::file())
walk(fs::dir_ls(fs::path(project_root, "R")), source)
argv <- parse_arguments("mriqc")
todo <- list_jobs_whole_mriqc()
done <- list_jobs_done_mriqc(argv$rerun_invalidate)
if (!isTRUE(argv$force)) {
  todo <- anti_join(
    todo, done,
    by = c("subject", "session")
  )
}
todo <- filter_subjects(todo, argv)
execute_jobs(todo, "mriqc", argv)
