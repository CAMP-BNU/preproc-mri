list_subjects_src <- function(site) {
  folders <- fs::dir_ls(
    path_src,
    regexp = site,
    type = "directory"
  )
  tibble::tibble(
    subject = stringr::str_extract(folders, "(?<=SUB)\\d{3}"),
    session = stringr::str_extract(folders, "\\d{1}$")
  )
}

list_subjects_raw <- function(site) {
  path_site <- fs::path(path_raw, site)
  if (!fs::dir_exists(path_site)) {
    return(tibble::tibble())
  }
  folders <- fs::dir_ls(path_site, regexp = "sub")
  tibble::tibble(
    subject = stringr::str_extract(folders, "\\d{3}$"),
    session = purrr::map(
      folders,
      ~ fs::dir_ls(.) |>
        stringr::str_extract("\\d{1}$")
    )
  ) |>
    tidyr::unchop(session)
}

commit_heudiconv <- function(site, subject, session, ...) {
  tmpl_heudiconv <- fs::path(path_tmpl, "fsl_sub_heudiconv.sh")
  env <- list(
    PROJECT_ROOT = project_root,
    SITE = site,
    SUBJECT = subject,
    SESSION = session
  )
  system_with_env(tmpl_heudiconv, env)
}
