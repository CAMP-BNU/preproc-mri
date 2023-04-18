#!/usr/bin/env Rscript
options(tidyverse.quiet = TRUE)
library(argparser)
library(tidyverse)
p <- arg_parser("Submitting jobs to convert dicom to bids format")
p <- add_argument(
  p,
  c("--site", "--subject", "--session", "--force"),
  help = c(
    "The site of data to convert",
    "The subject id",
    "The session number",
    "Force conversion?"
  ),
  flag = c(FALSE, FALSE, FALSE, TRUE)
)
p <- add_argument(
  p, "--max-jobs",
  help = "The maximal jobs to submit. Set to 0 for unlimited jobs.",
  default = 5,
  short = "-n"
)
argv <- parse_args(p)
site <- argv$site
subject <- argv$subject
session <- argv$session
if (is.na(argv$site)) {
  subject <- NA_character_
  session <- NA_character_
} else if (is.na(subject)) {
  session <- NA_character_
}
walk(fs::dir_ls(here::here("R")), source)
jobs <- tibble(site = sites) |>
  reframe(
    list_subjects_src(site),
    .by = site
  )
done <- tibble(site = sites) |>
  reframe(
    list_subjects_raw(site),
    .by = site
  )
if (isTRUE(argv$force)) {
  todo <- jobs
} else {
  todo <- dplyr::setdiff(jobs, done)
}
if (!is.na(site) && site %in% todo$site) {
  todo <- filter(todo, site == .env$site)
  if (!is.na(subject) && subject %in% todo$subject) {
    todo <- filter(todo, subject == .env$subject)
    if (!is.na(session) && session %in% todo$session) {
      todo <- filter(todo, session == .env$session)
    }
  }
}
if (argv$max_jobs != 0 && nrow(todo) > argv$max_jobs) {
  message(
    str_glue(
      "The required jobs number exceeding maximal allowed.",
      "Only the first {argv$max_jobs} commited.",
      .sep = " "
    )
  )
  todo <- slice_head(todo, n = argv$max_jobs)
}
purrr::pwalk(todo, commit_heudiconv)
