list_jobs_whole_heudiconv <- function() {
  folders <- path_src |>
    fs::dir_ls(type = "directory") |>
    fs::path_file()
  tibble(
    site = str_extract(folders, "^[A-Z]+"),
    subject = str_extract(folders, ".+SUB\\d{3}"),
    sid = str_extract(folders, "(?<=SUB)\\d{3}"),
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
      site = str_extract(fs::path_file(folder), "(?<=-)[A-Z]+"),
      sid = str_extract(fs::path_file(folder), "\\d{3}$"),
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
    select(site, sid, session)
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
  tmpl_heudiconv <- fs::path(path_tmpl, "fsl_sub_heudiconv.sh")
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
  heudiconv_cache <- check_heudiconv_cache(subject, session)
  if (heudiconv_cache) {
    fs::dir_delete(names(heudiconv_cache))
  }
  system_with_env(tmpl_heudiconv, env)
}

check_heudiconv_cache <- function(subject, session) {
  site <- str_extract(subject, "^[A-Z]+")
  sid <- str_extract(subject, "(?<=SUB)\\d{3}")
  fs::dir_exists(
    fs::path(
      path_raw,
      ".heudiconv",
      str_glue("{site}{sid}"),
      str_glue("ses-{session}"),
      "info"
    )
  )
}
