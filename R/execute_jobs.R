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
