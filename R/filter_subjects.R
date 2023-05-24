#' Filter subjects from jobs based on parsed command line arguments
#'
#' @param jobs A `data.frame()` of the required jobs.
#' @param argv Parsed command line arguments.
#' @returns The filtered out jobs.
filter_subjects <- function(jobs, argv) {
  filter_field <- function(jobs, field) {
    if (hasName(argv, field)) {
      if (!hasName(jobs, field)) {
        stop(str_glue("`{field}` is not supported."))
      }
      if (!is.na(argv[[field]])) {
        if (!argv[[field]] %in% jobs[[field]]) {
          stop("Given unprocessed data not found. Try adding `-f` if insisted.")
        }
        jobs <- filter(jobs, .data[[field]] == argv[[field]])
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
  jobs |>
    filter_field("subject") |>
    filter_field("site") |>
    filter_field("sid") |>
    filter_field("session")
}
