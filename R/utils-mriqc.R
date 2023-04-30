list_jobs_whole_mriqc <- list_jobs_done_heudiconv

list_jobs_done_mriqc <- function(check_file_sum = FALSE) {
  # 8 files are generated for each session
  num_files_ses <- 8L
  col_names_chk <- c("subject", "session")
  files_mriqc <- fs::path(path_derivatives, "mriqc") |>
    fs::dir_ls(type = "file", regexp = "sub") |>
    str_match("sub-([:alnum:]+)_ses-(\\d)") |>
    as_tibble(.name_repair = ~ c("whole", col_names_chk)) |>
    count(pick(all_of(col_names_chk)))
  if (check_file_sum) {
    files_mriqc |>
      filter(n == num_files_ses) |>
      select(all_of(col_names_chk))
  } else {
    files_mriqc |>
      filter(n >= 1L) |>
      select(all_of(col_names_chk))
  }
}

commit_mriqc <- function(sublist, file_sublist = NULL, ...) {
  rlang::check_dots_empty()
  if (is.null(file_sublist)) {
    dir_file_sublist <- fs::path(path_tmp, "mriqc", "qsub")
    if (!fs::dir_exists(dir_file_sublist)) {
      fs::dir_create(dir_file_sublist)
    }
    file_sublist <- fs::path(
      dir_file_sublist,
      format(now(), "sublist-%Y%m%d_%H%M%S")
    )
  }
  sublist |>
    select(subject, session) |>
    write_delim(file_sublist, col_names = FALSE)
  script_qsub <- tempfile()
  script_content <- fs::path(path_template, "mriqc.tmpl.qsub") |>
    read_file() |>
    str_glue()
  write_lines(script_content, script_qsub)
  message(str_glue("Commiting job array of { num_jobs } jobs."))
  message(str_glue("See file {file_sublist} for full list of subjects."))
  system(str_glue("qsub { script_qsub }"))
}
