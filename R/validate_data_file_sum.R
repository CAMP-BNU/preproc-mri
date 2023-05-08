#' Validate data based on file counts
#'
#' Used for generated data validation.
#'
#' @param type The type of data to be checked. Currently supported are
#'   `"heudiconv"` and `"fmriprep"`.
#' @param path,subject The path or subject to check. Note only one of these two
#'   parameters could be specified.
#' @param session The session to check. When `path` is specified, you can omit
#'   this if that can be inferred from `path`. Can be [integer()] or
#'   [character()].
#' @param check A logical value indicating if count of files should be checked.
validate_data_file_sum <- function(type,
                                   path = NULL, subject = NULL,
                                   session = NULL,
                                   check = FALSE) {
  rlang::check_exclusive(path, subject, .require = TRUE)
  file_sum_min <- switch(
    type,
    heudiconv = list(
      "1" = c(1, 4, 4, 14, 18),
      "2" = c(1, 2, 12, 21)
    ),
    fmriprep = list(
      "1" = c(37, 12, 120),
      "2" = c(12, 140)
    ),
    stop("Unsupported data type")
  )
  if (!is.null(path) && is.null(session)) {
    session <- str_extract(path, "(?<=ses-)\\d{1}")
  } else {
    path <- switch(
      type,
      heudiconv = path_raw,
      fmriprep = fs::path(path_derivatives, "fmriprep"),
      stop("Unsupported data type")
    ) |> fs::path(
      str_glue("sub-{subject}"), str_glue("ses-{session}")
    )
  }
  # session number of 3 or more will not be checked
  if (session > 2) {
    return(TRUE)
  }
  # return `FALSE` early if data path not found
  if (!fs::dir_exists(path)) {
    return(FALSE)
  }
  if (!check) {
    return(TRUE)
  }
  file_sum <- fs::dir_ls(
    path,
    recurse = TRUE,
    type = "file"
  ) |>
    fs::path_dir() |>
    table()
  file_sum_target <- file_sum_min[[session]]
  length(file_sum) == length(file_sum_target) &&
    all(file_sum == file_sum_target)
}
