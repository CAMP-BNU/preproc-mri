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
    mutate(status = coalesce(status, "todo")) |>
    extract_todo()
}
