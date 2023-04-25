#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
walk(fs::dir_ls(here::here("R")), source)
argv <- arg_parser("Submitting jobs to do mriqc for bids data") |>
  add_argument(
    "--subject",
    "The subject identifier in bids. If specified, site and sid will be ignored.",
    short = "-s"
  ) |>
  add_argument("--site", "The site of data", short = "-t") |>
  add_argument("--sid", "The subject id", short = "-i") |>
  add_argument("--session", "The session number", short = "-e") |>
  add_argument(
    "--max-jobs",
    "The maximal jobs to submit. Set to 0 for unlimited jobs.",
    default = 5,
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
if (!is.na(subject)) {
  site <- str_extract(subject, "^[A-Z]+")
  sid <- str_extract(subject, "\\d{3}$")
} else if (is.na(argv$site)) {
  sid <- NA_character_
  session <- NA_character_
} else if (is.na(sid)) {
  session <- NA_character_
}
todo <- list_jobs_whole_mriqc()
done <- list_jobs_done_mriqc()
if (!isTRUE(argv$force)) {
  todo <- todo |>
    anti_join(
      done,
      by = c("subject", "session")
    )
}
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
    if (!is.na(session)) {
      if (!session %in% todo$session) {
        stop("No unchecked data from given site, sid and session")
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
    options(pillar.print_max = Inf)
    print(todo)
  } else {
    purrr::pwalk(todo, commit_mriqc)
  }
} else {
  message("All jobs are done! No jobs were commited.")
}
