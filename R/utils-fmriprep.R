list_jobs_whole_fmriprep <- function(..., skip_session_check = FALSE) {
  subjects <- list_jobs_done_heudiconv(...)
  if (!skip_session_check) {
    subjects <- subjects |>
      filter(n() >= 2, .by = subject)
  }
  distinct(subjects, subject, site, sid)
}

list_jobs_done_fmriprep <- function(check_file_sum = FALSE,
                                    skip_session_check = FALSE) {
  done <- tibble(
    folder = fs::path(path_derivatives, "fmriprep") |>
      fs::dir_ls(type = "directory", regexp = "sub")
  ) |>
    mutate(
      subject = str_extract(folder, "(?<=sub-).*"),
      site = str_extract(subject, "^[A-Z]+"),
      sid = str_extract(subject, "\\d{3}"),
      dir_ses = map(
        folder,
        ~ fs::dir_ls(., regexp = "ses")
      )
    ) |>
    unchop(dir_ses) |>
    mutate(
      is_done = map_lgl(
        dir_ses,
        ~ validate_data_file_sum(
          "fmriprep",
          path = .,
          check = check_file_sum
        )
      )
    ) |>
    filter(is_done)
  if (!skip_session_check) {
    done <- done |>
      filter(n() >= 2, .by = subject)
  }
  distinct(done, subject, site, sid)
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
  script_content <- fs::path(path_template, "fmriprep.tmpl.qsub") |>
    read_file() |>
    str_glue()
  write_lines(script_content, script_qsub)
  message(str_glue("Commiting job array of { num_jobs } jobs."))
  message(str_glue("See file { file_sublist } for full list of subjects."))
  system(str_glue("qsub { script_qsub }"))
}
