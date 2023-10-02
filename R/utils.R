#' Parse command line arguments for scripts
#'
#' @returns A list with argument values. The same as those from
#'   [argparser::parse_args()].
parse_arguments <- function() {
  name <- switch(
    context,
    heudiconv = "Submitting jobs to convert dicom to bids format",
    mriqc = "Submitting jobs to do mriqc for bids data",
    fmriprep = "Submitting jobs to do fmriprep for bids data",
    stop("Unsupported routine context.")
  )
  parser <- arg_parser(name) |>
    add_argument("--site", "The site", short = "-t") |>
    add_argument("--sid", "The subject id", short = "-i") |>
    add_argument(
      "--force",
      "Force run even if it is done?",
      flag = TRUE
    ) |>
    add_argument(
      "--rerun-invalidate",
      "Try re-running all invalidated subjects?",
      flag = TRUE
    ) |>
    add_argument(
      "--max-jobs",
      "The maximal jobs to submit. Set to 0 for unlimited jobs.",
      default = 10,
      short = "-n"
    ) |>
    add_argument(
      "--queue",
      "Specify which queue to run.",
      default = "long.q"
    ) |>
    add_argument(
      "--dry-run",
      "Skip really executing the jobs?",
      flag = TRUE
    )
  if (context %in% c("heudiconv", "mriqc")) {
    parser <- parser |>
      add_argument("--session", "The session number", short = "-e")
  }
  if (context %in% c("mriqc", "fmriprep")) {
    parser <- parser |>
      add_argument(
        "--subject",
        paste("The subject identifier in bids.",
              "If specified, `site` and `sid` will be ignored."),
        short = "-s"
      )
  }
  if (context %in% c("fmriprep")) {
    parser <- parser |>
      add_argument(
        "--skip-session-check",
        "Do not check if data exist for both sessions? [default: FALSE]",
        short = "-p",
        flag = TRUE
      ) |>
      add_argument(
        "--clean-fs-files",
        "Clean existing freesurfer recon-all results? [default: FALSE]",
        flag = TRUE
      )
  }
  argv <- parse_args(parser)
  if (context == "fmriprep") {
    if (argv$skip_session_check && argv$rerun_invalidate) {
      warning("Enabling --skip-session-check will disable --rerun-invalidate")
      argv$rerun_invalidate <- FALSE
    }
  }
  argv
}

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
