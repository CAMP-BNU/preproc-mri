#' Parse command line arguments for scripts
#'
#' @param type The type of data processing. Currently supported are
#'   `"heudiconv"`, `"mriqc"` and `"fmriprep"`.
#' @returns A list with argument values. The same as those from
#'   [argparser::parse_args()].
parse_arguments <- function(type) {
  name <- switch(
    type,
    heudiconv = "Submitting jobs to convert dicom to bids format",
    mriqc = "Submitting jobs to do mriqc for bids data",
    fmriprep = "Submitting jobs to do fmriprep for bids data",
    stop("Unsupported routine type.")
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
  if (type %in% c("heudiconv", "mriqc")) {
    parser <- parser |>
      add_argument("--session", "The session number", short = "-e")
  }
  if (type %in% c("mriqc", "fmriprep")) {
    parser <- parser |>
      add_argument(
        "--subject",
        paste("The subject identifier in bids.",
              "If specified, `site` and `sid` will be ignored."),
        short = "-s"
      )
  }
  parse_args(parser)
}
