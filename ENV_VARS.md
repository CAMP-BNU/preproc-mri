# Environment variables used by the Python port

This documents environment variables used by the converted Python code and their defaults (where applicable).

- PROJECT_ROOT: Root of the project. If unset, the current working directory is used.
- FMRIPREP_CONTAINER: Container image for fmriprep (default: `/opt/fmritools/containers/fmriprep-v23.1.4.sif`)
- SINGULARITY_CMD: Singulariy command to run containers (default `singularity`)
- FMRIPREP_CMD: If you use a command wrapper (e.g., with singularity) set it here.
- INPUT_DIR: Root raw data directory (default `${PROJECT_ROOT}/rawdata`).
- OUTPUT_DIR: Root outputs dir (default `${PROJECT_ROOT}/derivatives/fmriprep`).
- WORK_DIR: Work directory (default `${PROJECT_ROOT}/tmp`).
- BIDS_DATABASE_DIR: BIDS database path (default `${PROJECT_ROOT}/bids_db`).
- FS_SUBJECTS_DIR: FreeSurfer subjects dir (default `${PROJECT_ROOT}/derivatives/freesurfer`).

How to provide environment variables:

- Set variables in your shell before running the scripts.
- Or use a `.env` file at the repo root (python-dotenv is used to load it when available).

Example `.env` file content:

```sh
PROJECT_ROOT=C:/Users/liang/OneDrive/Documents/Research/CAMP/preproc-mri
FMRIPREP_CONTAINER=/opt/fmritools/containers/fmriprep-v23.1.4.sif
SINGULARITY_CMD=singularity
```

Notes:
- The Python port centralizes retrieving env vars using `preproc.env.get_env_settings()`.
- Qsub templates use `${VAR}` placeholders; `render_template` is used to replace them with env values.
