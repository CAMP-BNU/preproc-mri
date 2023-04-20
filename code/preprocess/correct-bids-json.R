#!/usr/bin/env Rscript
# https://github.com/nipreps/mriqc/issues/879
# correct json files in place because there are too many files
# the main goal is to remove all `"\u0000"`
library(tidyverse)
walk(fs::dir_ls(here::here("R")), source)
clean_json_embed <- function(file_origin,
                             file_corrected = NULL,
                             inplace = TRUE) {
  content_origin <- read_file(file_origin)
  content_corrected <- str_remove_all(content_origin, fixed("\\u0000"))
  if (!identical(content_origin, content_corrected)) {
    if (inplace) {
      file_corrected <- file_origin
      fs::file_chmod(file_origin, "644")
    }
    write_file(content_corrected, file_corrected)
  }
}

files_json <- fs::dir_ls(path_raw, regexp = "json$", recurse = TRUE)
walk(files_json, clean_json_embed, .progress = TRUE)
