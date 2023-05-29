#!/usr/bin/env Rscript
project_root <- fs::path_dir(box::file())
context <- "fmriprep"
source(fs::path(project_root, "preprocess", "perform.R"))
