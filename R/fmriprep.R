list_jobs_whole_fmriprep <- function(skip_session_check = FALSE) {
  jobs <- list_jobs_status_heudiconv()
  if (!skip_session_check) {
    jobs <- filter(jobs, n() >= 2, .by = subject)
  }
  distinct(jobs, subject, site, sid)
}

list_jobs_status_fmriprep <- function() {
  if (!file.exists(file_fmriprep_jobs)) {
    return(
      tibble(
        subject = "",
        site = "",
        sid = "",
        status = "",
        .rows = 0
      )
    )
  }
  read_tsv(
    file_fmriprep_jobs,
    col_names = c("subject", "job", "status", "start_time", "finish_time"),
    col_select = c(subject, status),
    show_col_types = FALSE
  ) |>
    slice_tail(n = 1, by = subject) |>
    mutate(
      site = str_extract(subject, "^[A-Z]+"),
      sid = str_extract(subject, "\\d{3}"),
      status = if_else(status == 0, "done", "incomplete")
    )
}

commit_fmriprep <- function(sublist, file_sublist = NULL, ...) {
  rlang::check_dots_empty()
  if (is.null(file_sublist)) {
    dir_file_sublist <- fs::path(path_tmp, "qsub", "fmriprep")
    if (!fs::dir_exists(dir_file_sublist)) {
      fs::dir_create(dir_file_sublist)
    }
    file_sublist <- fs::path(
      dir_file_sublist,
      format(now(), "sublist-%Y%m%d_%H%M%S")
    )
  }
  write_lines(sublist$subject, file_sublist)
  # jobs for main fmriprep
  main_qsub <- tempfile()
  use_pe <- ""
  if (!is.na(nthreads) && nthreads > 1) {
    use_pe <- str_glue("#$ -pe { pe } { nthreads }")
  }
  main_cmd <- fs::path(path_qsub, "fmriprep.tmpl.qsub") |>
    read_file() |>
    str_glue()
  write_lines(main_cmd, main_qsub)
  message(str_glue("Commiting main job array of { num_jobs } jobs."))
  message(str_glue("See file { file_sublist } for full list of subjects."))
  job_main <- system(
    str_glue("qsub -terse { main_qsub }"),
    intern = TRUE
  )
  message(str_glue("Commiting main fmriprep job array { job_main } succeeded."))
  # jobs to clean temporary files
  job_main_id <- str_extract(job_main, "^\\d+")
  clean_qsub <- tempfile()
  clean_cmd <- fs::path(path_qsub, "clean_fmriprep.tmpl.qsub") |>
    read_file() |>
    str_glue()
  write_lines(clean_cmd, clean_qsub)
  job_clean <- system(
    str_glue("qsub -terse { clean_qsub }"),
    intern = TRUE
  )
  message(str_glue("Commiting clean job array { job_clean } succeeded."))
}
