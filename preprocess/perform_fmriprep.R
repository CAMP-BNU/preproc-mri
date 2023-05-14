#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
project_root <- fs::path_dir(box::file())
walk(fs::dir_ls(fs::path(project_root, "R")), source)
argv <- parse_arguments("fmriprep")
subject <- argv$subject
site <- argv$site
sid <- argv$sid
max_jobs <- argv$max_jobs
queue <- argv$queue
if (!is.na(subject)) {
  site <- NA_character_
  sid <- NA_character_
} else {
  if (is.na(argv$site)) {
    sid <- NA_character_
    session <- NA_character_
  } else if (is.na(sid)) {
    session <- NA_character_
  }
}
todo <- list_jobs_whole_fmriprep(argv$skip_session_check)
done <- list_jobs_done_fmriprep(argv$rerun_invalidate, argv$skip_session_check)
if (!isTRUE(argv$force)) {
  todo <- todo |>
    anti_join(done, by = "subject")
}
if (!is.na(subject)) {
  if (!subject %in% todo$subject) {
    stop("No unchecked data from given subject")
  }
  todo <- filter(todo, subject == .env$subject)
} else {
  if (!is.na(site)) {
    if (!site %in% todo$site) {
      stop("No unchecked data from given site")
    }
    todo <- filter(todo, site == .env$site)
    if (!is.na(sid)) {
      if (!sid %in% todo$sid) {
        stop("No unchecked data from given site and sid")
      }
      todo <- filter(todo, sid == .env$sid)
    }
  }
}
num_jobs <- nrow(todo)
if (num_jobs > 0) {
  if (argv$dry_run) {
    message(
      str_glue(
        "There are {num_jobs} jobs to be commited.",
        "As follows:",
        .sep = " "
      )
    )
    options(pillar.print_max = Inf)
    print(todo)
  } else {
    commit_fmriprep(todo)
  }
} else {
  message("All jobs are done! No jobs were commited.")
}
