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
      fs::path(path_raw, ".heudiconv"),
      type = "directory"
    )
  ) |>
    mutate(
      subject = fs::path_file(folder),
      site = str_extract(subject, "^[A-Z]+"),
      sid = str_extract(subject, "\\d{3}"),
      dir_ses = map(
        folder,
        ~ fs::dir_ls(., regexp = "ses")
      )
    ) |>
    unchop(dir_ses) |>
    mutate(
      session = str_extract(dir_ses, "\\d{1}$"),
      is_done = map2_lgl(
        subject, session,
        ~ is_done_heudiconv(
          subject = .x,
          session = .y,
          check_file_sum = check_file_sum
        )
      )
    ) |>
    filter(is_done) |>
    select(subject, site, sid, session)
}

is_done_heudiconv <- function(path = NULL, subject = NULL, session = NULL,
                              check_file_sum = FALSE) {
  rlang::check_exclusive(path, subject, .require = TRUE)
  rlang::check_exclusive(path, session, .require = TRUE)
  file_sum_min <- list(
    "1" = c(1, 4, 4, 14, 18),
    "2" = c(1, 2, 12, 21)
  )
  if (!is.null(path)) {
    session <- str_extract(path, "(?<=ses-)\\d{1}")
  } else {
    path <- fs::path(
      path_raw, str_glue("sub-{subject}"), str_glue("ses-{session}")
    )
  }
  # session number of 3 or more will not be checked
  if (session > 2) {
    return(TRUE)
  }
  # return `FALSE` early if data path not found
  if (!fs::dir_exists(path)) {
    return(FALSE)
  }
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

commit_heudiconv <- function(sublist, file_sublist = NULL, ...) {
  rlang::check_dots_empty()
  if (is.null(file_sublist)) {
    dir_file_sublist <- fs::path(path_tmp, "qsub", "heudiconv")
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
  script_content <- fs::path(path_template, "heudiconv.tmpl.qsub") |>
    read_file() |>
    str_glue()
  write_lines(script_content, script_qsub)
  message(str_glue("Commiting job array of { num_jobs } jobs."))
  message(str_glue("See file {file_sublist} for full list of subjects."))
  system(str_glue("qsub { script_qsub }"))
}
