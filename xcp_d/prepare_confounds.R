# please use this in RStudio and set a proper conda environment
library(tidyverse)
reticulate::use_condaenv("bids")
bids <- reticulate::import("bids")
layout_confounds <- bids$BIDSLayout(
  fs::path("derivatives/fmriprep"),
  validate = FALSE,
  database_path = fs::path("derivatives/layout_fmriprep")
)$get(desc = "confounds", extension = "tsv")
path_new <- "xcp_d/custom_confounds"
walk(
  layout_confounds,
  \(layout) {
    cur_path <- layout$path
  read_tsv(cur_path, show_col_types = FALSE, na = "n/a") |>
    select(
      # global signals for CSF and WM
      (starts_with("csf") | starts_with("white_matter")) & !contains("wm")
    ) |>
    mutate(across(everything(), \(x) replace_na(x, 0))) |>
    write_tsv(fs::path(path_new, fs::path_file(cur_path)), na = "")
  },
  .progress = TRUE
)
