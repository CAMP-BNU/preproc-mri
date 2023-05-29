#!/usr/bin/env Rscript
project_root <- fs::path_dir(box::file())
context <- "heudiconv"
source(fs::path(project_root, "preprocess", "perform.R"))
