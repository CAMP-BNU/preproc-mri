#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
walk(fs::dir_ls(here::here("R")), source)
p <- arg_parser("Submitting jobs to convert dicom to bids format")
p <- add_argument(
  p,
  c("--site", "--sid", "--session"),
  help = c(
    "The site of data to convert",
    "The subject id",
    "The session number"
  ),
  flag = c(FALSE, FALSE, FALSE),
  short = c("-t", "-s", "-e")
)
p <- add_argument(
  p, "--max-jobs",
  help = "The maximal jobs to submit. Set to 0 for unlimited jobs.",
  default = 5,
  short = "-n"
)
p <- add_argument(
  p, c("--force", "--rerun-invalidate", "--dry-run"),
  help = c(
    "Do not execute the jobs?",
    "Try to re-run all invalidated subjects?",
    "Force conversion?"
  ),
  flag = c(TRUE, TRUE, TRUE)
)
argv <- parse_args(p)
site <- argv$site
sid <- argv$sid
session <- argv$session
if (is.na(argv$site)) {
  sid <- NA_character_
  session <- NA_character_
} else if (is.na(sid)) {
  session <- NA_character_
}
todo <- list_jobs_whole_heudiconv()
done <- list_jobs_done_heudiconv(argv$rerun_invalidate)
if (!isTRUE(argv$force)) {
  todo <- todo |>
    anti_join(
      done,
      by = c("site", "sid", "session")
    )
}
if (!is.na(site)) {
  if (!site %in% todo$site) {
    stop("No unconverted data from given site")
  }
  todo <- filter(todo, site == .env$site)
  if (!is.na(sid)) {
    if (!sid %in% todo$sid) {
      stop("No unconverted data from given site and sid")
    }
    todo <- filter(todo, sid == .env$sid)
    if (!is.na(session)) {
      if (!session %in% todo$session) {
        stop("No unconverted data from given site, sid and session")
      }
      todo <- filter(todo, session == .env$session)
    }
  }
}
if (argv$max_jobs != 0 && nrow(todo) > argv$max_jobs) {
  message(
    str_glue(
      "The required jobs number ({nrow(todo)})",
      "exceeded maximal allowed.",
      "Only the first {argv$max_jobs} commited.",
      .sep = " "
    )
  )
  todo <- slice_head(todo, n = argv$max_jobs)
}
if (nrow(todo) > 0) {
  if (argv$dry_run) {
    message(
      str_glue(
        "There are {nrow(todo)} jobs to be commited.",
        "As follows:",
        .sep = " "
      )
    )
    print(todo)
  } else {
    purrr::pwalk(todo, commit_heudiconv)
  }
} else {
  message("All jobs are done! No jobs were commited.")
}
