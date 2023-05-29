#' Validate data based on file counts
#'
#' Used for generated data validation.
#'
#' @param type The type of data to be checked. Currently supported are
#'   `"heudiconv"` and `"fmriprep"`.
#' @param path,subject The path or subject to check. Note only one of these two
#'   parameters could be specified.
#' @param part The part of data to be checked, typically the last element of
#'   `path`. If not specified, will extract from `path`.
#' @param check A logical value indicating if count of files should be checked.
#' @returns A character scalar. Possible values are: `"done"`, "`todo`",
#'   "`incomplete`".
validate_data_file_sum <- function(type,
                                   path = NULL, subject = NULL,
                                   part = NULL,
                                   check = FALSE) {
  rlang::check_exclusive(path, subject, .require = TRUE)
  file_sum_min <- switch(type,
    heudiconv = list(
      "ses-1" = c(1, 4, 4, 14, 18),
      "ses-2" = c(1, 2, 12, 21)
    ),
    fmriprep = list(
      "anat" = 2,
      "figures" = 116,
      "ses-1" = c(37, 12, 120),
      "ses-2" = c(12, 140)
    ),
    stop("Unsupported data type")
  )
  if (!is.null(path) && is.null(part)) {
    part <- fs::path_file(path)
  } else {
    path <- switch(type,
      heudiconv = path_raw,
      fmriprep = fs::path(path_derivatives, "fmriprep"),
      stop("Unsupported data type")
    ) |> fs::path(str_glue("sub-{subject}"), part)
  }
  # do not check unknown parts
  if (!part %in% names(file_sum_min)) {
    return("done")
  }
  if (!check) {
    # in this case return done if path found
    if (fs::dir_exists(path)) {
      return("done")
    } else {
      return("todo ")
    }
  }
  file_sum <- fs::dir_ls(path, recurse = TRUE, type = "file") |>
    fs::path_dir() |>
    table()
  file_sum_target <- file_sum_min[[part]]
  if (length(file_sum) == length(file_sum_target) &&
    all(file_sum == file_sum_target)) {
    return("done")
  } else {
    return("incomplete")
  }
}
