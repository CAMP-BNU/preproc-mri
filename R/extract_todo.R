#' Extract todo jobs based on parsed command line arguments
#'
#' @param jobs A `data.frame()` of the required jobs.
#' @param argv Parsed command line arguments.
#' @returns The extracted jobs to be done.
extract_todo <- function(jobs, argv) {
  filter_field <- function(jobs, field) {
    if (hasName(argv, field)) {
      if (!hasName(jobs, field)) {
        stop(str_glue("`{field}` is not supported."))
      }
      if (!is.na(argv[[field]])) {
        jobs <- filter(jobs, .data[[field]] == argv[[field]])
        if (nrow(jobs) == 0) {
          stop("Cannot found given data.")
        }
        if (all(jobs$status == "done") && !argv$force) {
          stop("Given data have been finished. Try adding `-f` if insisted.")
        }
      }
    }
    jobs
  }
  if (hasName(argv, "subject") && !is.na(argv$subject)) {
    argv$site <- argv$sid <- NA_character_
  } else {
    if (hasName(argv, "site") && is.na(argv$site)) {
      argv$sid <- NA_character_
    }
    if (hasName(argv, "session") &&
        anyNA(argv[c("site", "sid")])) {
      argv$session <- NA_character_
    }
  }
  jobs_for_sub <- jobs |>
    filter_field("subject") |>
    filter_field("site") |>
    filter_field("sid") |>
    filter_field("session")
  bind_rows(
    filter(jobs_for_sub, status == "todo"),
    if (argv$rerun_invalidate) {
      filter(jobs_for_sub, status == "incomplete")
    },
    if (argv$force) {
      filter(jobs_for_sub, status == "done")
    }
  )
}
