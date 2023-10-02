#' Prepare jobs to submit to the cluster
prepare_jobs <- function() {
  keys <-  switch(context,
    heudiconv = c("site", "sid", "session"),
    fmriprep = c("subject", "site", "sid"),
    mriqc = c("subject", "session"),
    stop("Unknown context: ", context)
  )
  if (context == "heudiconv") {
    jobs_list <- list_jobs_whole_heudiconv()
    jobs_status <- list_jobs_status_heudiconv(argv$rerun_invalidate)
  }
  if (context == "fmriprep") {
    jobs_list <- list_jobs_whole_fmriprep(argv$skip_session_check)
    jobs_status <- list_jobs_status_fmriprep(argv$rerun_invalidate)
  }
  if (context == "mriqc") {
    jobs_list <- list_jobs_whole_mriqc()
    jobs_status <- list_jobs_status_mriqc(argv$rerun_invalidate)
  }
  jobs_list |>
    left_join(jobs_status, by = keys) |>
    mutate(status = coalesce(status, "todo"))
}

#' Extract todo jobs based on parsed command line arguments
#'
#' @param jobs A `data.frame()` of the required jobs.
#' @returns The extracted jobs to be done.
extract_todo <- function(jobs) {
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

#' Execute given jobs
#'
#' @param jobs A data frame of jobs to be executed.
#' @return Invisible `NULL`. The function is used for its side effects.
execute_jobs <- function(jobs) {
  num_jobs <- nrow(jobs)
  if (num_jobs > 0) {
    if (argv$dry_run) {
      message(
        str_glue(
          "There are {num_jobs} jobs to be commited.",
          "As follows:",
          .sep = " "
        )
      )
      options(pillar.print_max = Inf)
      print(jobs)
    } else {
      withr::with_environment(
        rlang::env(!!!lst(!!!argv[-1], num_jobs)),
        rlang::exec(paste0("commit_", context), jobs)
      )
    }
  } else {
    message("All jobs are done! No jobs were commited.")
  }
  invisible()
}
