list_jobs_whole_mriqc <- list_jobs_done_heudiconv

list_jobs_done_mriqc <- function() {
  fs::path(path_derivative, "mriqc") |>
    fs::dir_ls(type = "directory", regexp = "sub") |>
    map(~fs::dir_ls(., type = "directory", regexp = "ses")) |>
    enframe(name = "subject", value = "session") |>
    unchop(session) |>
    mutate(
      subject = str_extract(subject, "(?<=sub-).+"),
      session = str_extract(session, "(?<=ses-).+")
    )
}

commit_mriqc <- function(sublist, file_sublist = NULL, ...) {
  rlang::check_dots_empty()
  file_sublist <- file_sublist %||% fs::path(path_temp, "sublist")
  sublist |>
    select(subject, session) |>
    write_delim(file_sublist, col_names = FALSE)
  script_qsub <- tempfile()
  script_content <- fs::path(path_tmpl, "mriqc.tmpl.qsub") |>
    read_file() |>
    str_glue()
  write_lines(script_content, script_qsub)
  message(str_glue("Commiting job array of { num_jobs } jobs."))
  system(str_glue("qsub { script_qsub }"))
}
