#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
p <- arg_parser("Submitting jobs to convert dicom to bids format")
p <- add_argument(
  p,
  c("--site", "--sid", "--session", "--force"),
  help = c(
    "The site of data to convert",
    "The subject id",
    "The session number",
    "Force conversion?"
  ),
  flag = c(FALSE, FALSE, FALSE, TRUE),
  short = c("-t", "-s", "-e", "-f")
)
p <- add_argument(
  p, "--max-jobs",
  help = "The maximal jobs to submit. Set to 0 for unlimited jobs.",
  default = 5,
  short = "-n"
)
p <- add_argument(
  p, "--dry-run",
  help = "Do not execute the jobs?",
  flag = TRUE
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
walk(fs::dir_ls(here::here("R")), source)
jobs <- list_jobs_whole()
done <- list_jobs_done()
if (isTRUE(argv$force)) {
  todo <- jobs
} else {
  todo <- jobs |>
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
