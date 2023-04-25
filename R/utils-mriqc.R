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

commit_mriqc <- function(subject, session, ...) {
  tmpl_mriqc <- fs::path(path_tmpl, "fsl_sub_mriqc.sh")
  env <- list(
    PROJECT_ROOT = project_root,
    SUBJECT = subject,
    SESSION = session
  )
  remove_mriqc_cache(subject, session)
  message(
    stringr::str_glue(
      "Commiting job with:",
      "SUBJECT={subject}, SESSION={session}",
      .sep = " "
    )
  )
  system_with_env(tmpl_mriqc, env)
}

remove_mriqc_cache <- function(subject, session) {
  fs::path(path_temp, "mriqc") |>
    fs::dir_ls(
      type = "file",
      regexp = str_glue("sub-{subject}.*ses-{session}"),
      recurse = TRUE
    ) |>
    fs::file_delete()
}
