# Python port of preproc

This is an initial port of the `preproc-mri` R package (renamed to `preproc` for the Python port). It includes basic translations of R scripts and core functions used to prepare and submit cluster jobs for fMRI preprocessing pipelines.

Key points:
- Environment variables: use `PROJECT_ROOT` to set root directory. If not set, repository root is used.
- CLI scripts: `scripts/perform_fmriprep.py`, `scripts/perform_mriqc.py`, `scripts/perform_heudiconv.py`, `scripts/perform_xcpd.py` replicate R scripts.
- Qsub templates are rendered using `${VAR}` placeholders with Python substitution.

Quick start:

1. Create a Python environment (recommended) and install dependencies. Example using venv and pip:

```pwsh
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Run the fmriprep script (example):

```pwsh
python scripts/perform_fmriprep.py --site TJNU --sid 001
```

Limitations and next steps:
- This is an initial conversion producing a Python skeleton; behavior should be verified on a real dataset and cluster environment.
- More detailed validation and unit tests are needed.
- Some R-specific template placeholders are converted conservatively and should be reviewed.

Feel free to ask for conversion of specific R files or deeper fidelity to the original R behavior.
