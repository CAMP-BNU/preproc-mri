list_jobs_whole_fmriprep <- function(skip_session_check = FALSE) {
  jobs <- list_jobs_status_heudiconv()
  if (!skip_session_check) {
    jobs <- filter(jobs, n() >= 2, .by = subject)
  }
  distinct(jobs, subject, site, sid)
}

list_jobs_status_fmriprep <- function() {
  read_tsv(
    path_fmriprep_jobs,
    col_names = c("subject", "job", "status"),
    show_col_types = FALSE
  ) |>
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
  script_qsub <- tempfile()
  use_pe <- ""
  if (!is.na(nthreads) && nthreads > 1) {
    use_pe <- str_glue("#$ -pe { pe } { nthreads }")
  }
  script_content <- fs::path(path_template, "fmriprep.tmpl.qsub") |>
    read_file() |>
    str_glue()
  write_lines(script_content, script_qsub)
  message(str_glue("Commiting job array of { num_jobs } jobs."))
  message(str_glue("See file { file_sublist } for full list of subjects."))
  system(str_glue("qsub { script_qsub }"))
}
