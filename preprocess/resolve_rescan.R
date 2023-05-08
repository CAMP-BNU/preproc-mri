#' This script is not designed for command line use. Please use it in RStudio
#' instead.
#'
#' This script is used to correct all those re-scans. Currently included is to
#' correct `"dwi"` images only.

library(tidyverse)

# DWI correction ----

#' * The `"dwi"` images are planned to be in the first session only, so if
#' additional `"dwi"` images are found in session 2 or more, move them and
#' replace those in session 1.
recipe_dwi_correction <- tibble(
  file = fs::dir_ls(
    "rawdata",
    regexp = "dwi",
    type = "file",
    recurse = TRUE
  )
) |>
  mutate(
    subject = str_extract(file, "(?<=sub-)[:alnum:]+"),
    session = str_extract(file, "(?<=ses-)\\d")
  ) |>
  filter(any(session > 1), .by = subject) |>
  mutate(
    file_new = if_else(
      session == 1,
      fs::path("backup", file),
      str_replace_all(file, "(?<=ses-)\\d", "1")
    )
  )
pwalk(
  recipe_dwi_correction,
  \(file, file_new, ...) {
    dir_new <- fs::path_dir(file_new)
    if (!fs::dir_exists(dir_new)) fs::dir_create(dir_new)
    fs::file_move(file, file_new)
  }
)
