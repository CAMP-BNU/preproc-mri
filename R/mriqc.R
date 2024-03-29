list_jobs_whole_mriqc <- list_jobs_status_fmriprep

list_jobs_status_mriqc <- function(check_file_sum = FALSE) {
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
      mutate(
        status = case_when(
          n == num_files_ses ~ "done",
          n == 0 ~ "todo",
          .default = "incomplete"
        )
      ) |>
      select(all_of(col_names_chk), status)
  } else {
    files_mriqc |>
      mutate(
        status = if_else(
          n >= 1,
          "done", "todo"
        )
      ) |>
      select(all_of(col_names_chk), status)
  }
}

commit_mriqc <- function(sublist, file_sublist = NULL, ...) {
  rlang::check_dots_empty()
  if (is.null(file_sublist)) {
    dir_file_sublist <- fs::path(path_tmp, "qsub", "mriqc")
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
  num_jobs <- nrow(sublist)
  fs::path(path_qsub, "mriqc.tmpl.qsub") |>
    read_file() |>
    str_glue() |>
    commit(
      "mriqc",
      num_jobs = num_jobs,
      file_sublist = file_sublist
    )
  invisible()
}
