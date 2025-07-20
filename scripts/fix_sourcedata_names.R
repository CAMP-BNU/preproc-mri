#' This script is not designed for command line use. Please use it in RStudio
#' instead.
#'
#' This script is used to remove unnecessary G105 and G110 suffix from names of
#' source data.

library(tidyverse)

rename_with_backup <- function(
    path,
    new_path,
    backup_path = "backup/sourcedata"
) {
  stopifnot(fs::dir_exists(backup_path))
  fs::dir_copy(path, backup_path)
  fs::file_move(path, new_path)
}

pat_rm <- "_G110$|_G105$"

tibble(path = fs::dir_ls("sourcedata", type = "dir")) |>
  filter(str_detect(path, pat_rm)) |>
  mutate(new_path = str_remove(path, pat_rm)) |>
  pwalk(rename_with_backup)
