# this is a helper script used to validate the status logged in the fmriprep job
# log file. Related resources:
# https://neurostars.org/t/exit-code-1-despite-no-error-in-logs/30164
# https://github.com/nipreps/fmriprep/issues/3426
project_root <- fs::path_dir(box::file())
devtools::load_all(project_root)
job_status <- read_tsv(
  file_fmriprep_jobs,
  col_names = c("subject", "job", "status", "start_time", "finish_time"),
  show_col_types = FALSE
) |>
  separate_wider_delim(job, "-", names = c("job_id", "job_subid")) |>
  slice_tail(n = 1, by = subject) |>
  mutate(
    log_failed = fs::path(
      path_log, "qsub",
      str_glue("fmriprep.o{job_id}.{job_subid}")
    ) |>
      map_lgl(
        \(file) str_detect(read_file(file), "crash"),
        .progress = TRUE
      )
  )
