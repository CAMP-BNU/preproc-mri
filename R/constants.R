path_src <- fs::path(project_root, "sourcedata")
path_raw <- fs::path(project_root, "rawdata")
path_derivative <- fs::path(project_root, "derivatives")
path_temp <- fs::path(project_root, "temp")
path_tmpl <- fs::path(project_root, "code", "template")
tjnu_scanner <- read_csv(
  fs::path(path_src, "tjnu-scanner.csv"),
  show_col_types = FALSE
)
