# data folders
path_src <- fs::path(project_root, "sourcedata")
path_raw <- fs::path(project_root, "rawdata")
path_bids_db <- fs::path(project_root, "bids_db")
path_derivatives <- fs::path(project_root, "derivatives")
path_backup <- fs::path(project_root, "backup")
path_tmp <- fs::path(project_root, "tmp")
path_log <- fs::path(project_root, "logs")
# code folders
path_template <- fs::path(project_root, "template")
path_qsub <- fs::path(path_template, "qsub")
# job status logs
file_fmriprep_jobs <- fs::path(path_log, "fmriprep_jobs.tsv")
# configurations
file_config_xcpd <- fs::path(project_root, "config", "xcpd.yml")
