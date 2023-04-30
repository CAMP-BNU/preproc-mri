#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
project_root <- box::file()
walk(fs::dir_ls(fs::path(project_root, "R")), source)
argv <- arg_parser("Submitting jobs to do mriqc for bids data") |>
  add_argument(
    "--subject",
    paste("The subject identifier in bids.",
          "If specified, `site` and `sid` will be ignored."),
    short = "-s"
  ) |>
  add_argument("--site", "The site of data", short = "-t") |>
  add_argument("--sid", "The subject id", short = "-i") |>
  add_argument("--session", "The session number", short = "-e") |>
  add_argument(
    "--max-jobs",
    "The maximal running jobs.",
    default = 10,
    short = "-n"
  ) |>
  add_argument(
    "--force",
    "Force run mriqc even if done? [default: FALSE]",
    flag = TRUE
  ) |>
  add_argument(
    "--rerun-invalidate",
    "Try to re-run all invalidated subjects? [default: FALSE]",
    flag = TRUE
  ) |>
  add_argument(
    "--dry-run",
    "Skip really executing the jobs? [default: FALSE]",
    flag = TRUE
  ) |>
  parse_args()
subject <- argv$subject
site <- argv$site
sid <- argv$sid
session <- argv$session
max_jobs <- argv$max_jobs
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
todo <- list_jobs_whole_mriqc()
done <- list_jobs_done_mriqc(argv$rerun_invalidate)
if (!isTRUE(argv$force)) {
  todo <- todo |>
    anti_join(
      done,
      by = c("subject", "session")
    )
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
if (!is.na(session)) {
  if (!session %in% todo$session) {
    stop("No unchecked data from given subject and session")
  }
  todo <- filter(todo, session == .env$session)
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
    commit_mriqc(todo)
  }
} else {
  message("All jobs are done! No jobs were commited.")
}
