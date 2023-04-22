list_jobs_whole <- function() {
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

list_jobs_done <- function() {
  tibble(
    folder = fs::dir_ls(
      path_raw, regexp = "sub", type = "directory"
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
      map(dir_ses, is_done_session) |>
        list_rbind()
    ) |>
    filter(is_done) |>
    select(site, sid, session)
}

is_done_session <- function(path) {
  file_sum_min <- list(
    "1" = c(1, 4, 4, 14, 18),
    "2" = c(1, 2, 12, 21)
  )
  session <- str_extract(path, "\\d{1}$")
  file_sum <- fs::dir_ls(
    path,
    recurse = TRUE,
    type = "file"
  ) |>
    fs::path_dir() |>
    table()
  file_sum_target <- file_sum_min[[session]]
  tibble(
    session = session,
    is_done = length(file_sum) == length(file_sum_target) &&
      all(file_sum >= file_sum_target)
  )
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
  system_with_env(tmpl_heudiconv, env)
}
