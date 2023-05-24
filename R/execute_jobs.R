#' Execute jobs according the type and command line arguments
#'
#' @param jobs A data frame of jobs to be executed.
#' @param type A character string of the type of jobs to be executed.
#' @param argv A list of command line arguments.
#' @return Invisible `NULL`. The function is used for its side effects.
execute_jobs <- function(jobs, type, argv) {
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
        rlang::exec(
          paste0("commit_", type),
          jobs
        )
      )
    }
  } else {
    message("All jobs are done! No jobs were commited.")
  }
  invisible()
}
