# https://github.com/nipreps/mriqc/issues/879
# the main goal is to remove all `"\u0000"`
clean_json_embed <- function(file_origin,
                             file_corrected = NULL,
                             inplace = TRUE) {
  content_origin <- readr::read_file(file_origin)
  content_corrected <- stringr::str_remove_all(
    content_origin, stringr::fixed("\\u0000")
  )
  if (!identical(content_origin, content_corrected)) {
    # recommend to correct json files in place because there are too many files
    if (inplace) {
      file_corrected <- file_origin
      fs::file_chmod(file_origin, "644")
    }
    readr::write_file(content_corrected, file_corrected)
  }
}
