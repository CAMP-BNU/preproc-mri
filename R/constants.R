path_src <- fs::path(project_root, "sourcedata")
path_raw <- fs::path(project_root, "rawdata")
path_derivatives <- fs::path(project_root, "derivatives")
path_tmp <- fs::path(project_root, "tmp")
path_template <- fs::path(project_root, "template")
tjnu_scanner <- read_csv(
  fs::path(path_src, "tjnu-scanner.csv"),
  show_col_types = FALSE
)
