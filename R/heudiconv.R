list_jobs_whole_heudiconv <- function() {
  folders <- path_src |>
    fs::dir_ls(type = "directory") |>
    fs::path_file()
  tibble(
    sub_dcm = str_extract(folders, ".+SUB\\d{3}"),
    site = str_extract(sub_dcm, "^[A-Z]+"),
    sid = str_extract(sub_dcm, "\\d{3}$"),
    session = str_extract(folders, "\\d{1}$")
  )
}

list_jobs_status_heudiconv <- function(check_file_sum = FALSE) {
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
    filter(!(site == "TJNU" & !str_ends(subject, "N|O"))) |>
    unchop(dir_ses) |>
    mutate(
      part = fs::path_file(dir_ses),
      session = str_extract(part, "\\d{1}$"),
      status = map2_chr(
        subject, part,
        ~ validate_data_file_sum(
          "heudiconv",
          subject = .x,
          part = .y,
          check = check_file_sum
        )
      )
    ) |>
    select(subject, site, sid, session, status)
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
    # we have two subject labels here, heudiconv used the original one
    select(sub_dcm, session) |>
    write_delim(file_sublist, col_names = FALSE)
  job_main <- fs::path(path_qsub, "heudiconv.tmpl.qsub") |>
    read_file() |>
    str_glue() |>
    commit(
      "heudiconv",
      num_jobs = nrow(file_sublist),
      file_sublist = file_sublist
    )
  job_main_id <- str_extract(job_main, "^\\d+")
  fs::path(path_qsub, "build_bidsdb.tmpl.qsub") |>
    read_file() |>
    str_glue() |>
    commit("build_bidsdb")
  invisible()
}
