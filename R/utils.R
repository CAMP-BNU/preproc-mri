#' Parse command line arguments for scripts
#'
#' @returns A list with argument values. The same as those from
#'   [argparser::parse_args()].
parse_arguments <- function() {
  name <- switch(context,
    heudiconv = "Submitting jobs to convert dicom to bids format",
    mriqc = "Submitting jobs to do mriqc for bids data",
    fmriprep = "Submitting jobs to do fmriprep for bids data",
    xcpd = "Submmiting jobs to do post-processing steps for connectivity",
    stop("Unsupported routine context.")
  )
  parser <- arg_parser(name) |>
    add_argument("--site", "The site", short = "-t") |>
    add_argument("--sid", "The subject id", short = "-i", nargs = Inf) |>
    add_argument(
      "--rerun",
      paste(
        "Specify the level of analysis re-run.",
        "1: only unprocessed, 2: re-run invalidated, 3: re-run all."
      ),
      default = 1
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
    ) |>
    add_argument(
      "--nthreads",
      "Number of threads in processing.",
      short = "-u"
    ) |>
    add_argument(
      "--omp-nthreads",
      "Maximum number of threads per-process."
    ) |>
    add_argument(
      "--pe",
      paste(
        "The parallel environment.",
        "Used when `--nthreads` is set and larger than 1."
      ),
      default = "ompi"
    )
  if (context %in% c("heudiconv", "mriqc")) {
    parser <- parser |>
      add_argument("--session", "The session number", short = "-e")
  }
  if (context %in% c("mriqc", "fmriprep", "xcpd")) {
    parser <- parser |>
      add_argument(
        "--subject",
        paste(
          "The subject identifier in bids.",
          "If specified, `site` and `sid` will be ignored."
        ),
        short = "-s",
        nargs = Inf
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
        "--clean-last",
        paste(
          "Clean results from last run?",
          "Can be 'none', 'results', 'freesurfer' or 'all'."
        ),
        default = "none"
      )
  }
  if (context %in% "xcpd") {
    parser <- parser |>
      add_argument(
        "--config-params",
        "Name of configuration for xcp_d post processing parameters.",
        short = "-g",
        default = "default"
      )
  }
  parse_args(parser) |> validate_argv()
}

#' Commit command with qsub
#'
#' @param command The command to be committed.
#' @param disp_name The display name of the job.
#' @param num_jobs Number of jobs. It only affect the messages. If not `NULL`,
#'   the message will add `"array"` and show the number of jobs.
#' @param file_subjects The file storing all the subjects to be processed. If
#'   both `num_jobs` and `message` is no `NULL`, the message will show the file
#'   name.
#' @returns The job id of the committed job (invisible).
commit <- function(command, disp_name, num_jobs = NULL, file_sublist = NULL) {
  script <- tempfile()
  write_lines(command, script)
  if (is.null(num_jobs)) {
    message(str_glue("Commiting job: {disp_name}."))
  } else {
    message(
      str_glue("Commiting array job: {disp_name}, job count: { num_jobs }.")
    )
    if (!is.null(file_sublist)) {
      message(str_glue("See file { file_sublist } for full list of subjects."))
    }
  }
  job_id <- system(
    str_glue("qsub -terse { script }"),
    intern = TRUE
  )
  message(str_glue("Commiting job succeeded as ({ job_id })."))
  invisible(job_id)
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
      "ses-1" = c(48, 12, 252),
      "ses-2" = c(12, 294)
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

# helper functions
validate_argv <- function(argv) {
  if (context %in% c("mriqc", "fmriprep")) {
    stopifnot(
      "Cannot specify --site or --sid when --subject is specified" =
        all(is.na(argv$subject)) || all(is.na(argv[c("site", "sid")]))
    )
  }
  stopifnot(
    "Cannot specify --sid without --site specified" =
      all(is.na(argv$sid)) || !is.na(argv$site)
  )
  if (context == "heudiconv") {
    stopifnot(
      "Cannot specify --session without --site and --sid specified" =
        is.na(argv$session) || !(anyNA(argv[c("site", "sid")]))
    )
  }
  argv
}

clize_list <- function(l) {
  deparse_arg <- function(value, name) {
    if (is.logical(value)) {
      if (isTRUE(value)) {
        str_glue("--{name}")
      } else {
        ""
      }
    } else {
      str_glue("--{name} {value}")
    }
  }
  str_c(
    imap(l, deparse_arg),
    collapse = " "
  )
}
