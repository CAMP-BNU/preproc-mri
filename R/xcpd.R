list_jobs_whole_xcpd <- function() {
  list_jobs_status_fmriprep() |>
    filter(status == "done") |>
    select(-status)
}

list_jobs_status_xcpd <- function() {
  if (!file.exists(file_xcpd_jobs)) {
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
    file_xcpd_jobs,
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

commit_xcpd <- function(sublist, file_sublist = NULL, ...) {
  rlang::check_dots_empty()
  if (is.null(file_sublist)) {
    dir_file_sublist <- fs::path(path_tmp, "qsub", "xcpd")
    if (!fs::dir_exists(dir_file_sublist)) {
      fs::dir_create(dir_file_sublist)
    }
    file_sublist <- fs::path(
      dir_file_sublist,
      format(now(), "sublist-%Y%m%d_%H%M%S")
    )
  }
  write_lines(sublist$subject, file_sublist)
  # jobs for main xcpd
  use_pe <- ""
  if (!is.na(nthreads) && nthreads > 1) {
    use_pe <- str_glue("#$ -pe { pe } { nthreads }")
  }
  num_jobs <- nrow(sublist)
  params_post <- clize_list(
    withr::with_envvar(
      c(PROJECT_ROOT = project_root),
      config::get(
        "params",
        config = config_params,
        file = file_config_xcpd
      )
    )
  )
  job_main <- fs::path(path_qsub, "xcpd.tmpl.qsub") |>
    read_file() |>
    str_glue() |>
    commit(
      "xcpd",
      num_jobs = num_jobs,
      file_sublist = file_sublist
    )
  # jobs to clean temporary files
  job_main_id <- str_extract(job_main, "^\\d+")
  fs::path(path_qsub, "clean_xcpd.tmpl.qsub") |>
    read_file() |>
    str_glue() |>
    commit("clean_xcpd")
  invisible()
}
