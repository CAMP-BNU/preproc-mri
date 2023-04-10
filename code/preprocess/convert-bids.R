#!/usr/bin/env Rscript
library(argparser)
library(tidyverse)
p <- arg_parser("Submitting jobs to convert dicom to bids format")
p <- add_argument(
  p,
  c("--site", "--subject", "--session"),
  help = c(
    "The site of data to convert",
    "The subject id",
    "The session number"
  )
)
argv <- parse_args(p)
site <- argv$site
subject <- argv$subject
session <- argv$session
if (is.na(argv$site)) {
  site <- c("SICNU", "TJNU")
  subject <- NA_character_
  session <- NA_character_
} else if (is.na(subject)) {
  session <- NA_character_
}
walk(fs::dir_ls(here::here("R")), source)
jobs <- tibble(site = site) |>
  reframe(
    list_subjects_src(site),
    .by = site
  )
done <- tibble(site = site) |>
  reframe(
    list_subjects_raw(site),
    .by = site
  )
todo <- dplyr::setdiff(jobs, done)
if (!is.na(site) && site %in% todo$site) {
  todo <- filter(todo, site == .env$site)
  if (!is.na(subject) && subject %in% todo$subject) {
    todo <- filter(todo, subject == .env$subject)
    if (!is.na(session) && session %in% todo$session) {
      todo <- filter(todo, session == .env$session)
    }
  }
}
purrr::pwalk(todo, commit_heudiconv)
