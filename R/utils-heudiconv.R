list_jobs_whole_heudiconv <- function() {
  folders <- path_src |>
    fs::dir_ls(type = "directory") |>
    fs::path_file()
  tibble(
    subject = str_extract(folders, ".+SUB\\d{3}"),
    site = str_extract(subject, "^[A-Z]+"),
    sid = str_extract(subject, "\\d{3}$"),
    session = str_extract(folders, "\\d{1}$")
  )
}

list_jobs_done_heudiconv <- function(check_file_sum = FALSE) {
  tibble(
    folder = fs::dir_ls(
      path_raw,
      regexp = "sub", type = "directory"
    )
  ) |>
    mutate(
      subject = str_extract(fs::path_file(folder), "(?<=sub-).+"),
      site = str_extract(subject, "^[A-Z]+"),
      sid = str_extract(subject, "\\d{3}"),
      dir_ses = map(
        folder,
        ~ fs::dir_ls(., regexp = "sub")
      )
    ) |>
    unchop(dir_ses) |>
    mutate(
      session = str_extract(dir_ses, "\\d{1}$"),
      is_done = map2_lgl(
        dir_ses, session,
        ~ is_done_heudiconv(.x, .y, check_file_sum)
      )
    ) |>
    filter(is_done) |>
    select(subject, site, sid, session)
}

is_done_heudiconv <- function(path, session, check_file_sum = FALSE) {
  file_sum_min <- list(
    "1" = c(1, 4, 4, 14, 18),
    "2" = c(1, 2, 12, 21)
  )
  if (!check_file_sum) {
    return(TRUE)
  }
  file_sum <- fs::dir_ls(
    path,
    recurse = TRUE,
    type = "file"
  ) |>
    fs::path_dir() |>
    table()
  file_sum_target <- file_sum_min[[session]]
  length(file_sum) == length(file_sum_target) &&
    all(file_sum == file_sum_target)
}

commit_heudiconv <- function(subject, session, ...) {
  tmpl_heudiconv <- fs::path(path_template, "fsl_sub_heudiconv.sh")
  env <- list(
    PROJECT_ROOT = project_root,
    SUBJECT = subject,
    SESSION = session
  )
  message(
    stringr::str_glue(
      "Commiting job with:",
      "SUBJECT={subject}, SESSION={session}",
      .sep = " "
    )
  )
  remove_heudiconv_cache(subject, session)
  system_with_env(tmpl_heudiconv, env)
}

remove_heudiconv_cache <- function(subject, session) {
  site <- str_extract(subject, "^[A-Z]+")
  sid <- str_extract(subject, "(?<=SUB)\\d{3}")
  suffix <- match_scanner_suffix(site, sid)
  if (length(suffix) == 0) {
    return(invisible())
  }
  heudiconv_cache <- fs::path(
    path_raw,
    ".heudiconv",
    str_glue("{site}{sid}{suffix}"),
    str_glue("ses-{session}"),
    "info"
  )
  if (fs::dir_exists(heudiconv_cache)) {
    fs::dir_delete(heudiconv_cache)
  }
}
