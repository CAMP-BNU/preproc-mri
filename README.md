# preproc-mri (Python-first)

This repository manages MRI preprocessing workflows. **Python is now the recommended primary implementation**, while R scripts are retained for backward compatibility and reference.

## 1. Recommended processing stages

Use the following stage order:

1. `heudiconv`: DICOM → BIDS
2. `mriqc`: quality control
3. `fmriprep`: functional preprocessing
4. `xcpd`: post-processing for connectivity workflows

You can run stages individually or use the YAML-driven `batch` command.

## 2. Python environment setup

```bash
python -m venv .venv
source .venv/bin/activate   # Use the matching activation command on Windows
pip install -r requirements.txt
```

Recommended environment variable:

```bash
export PROJECT_ROOT=$(pwd)
```

## 3. Single-stage examples

```bash
python -m preproc.cli heudiconv --site TJNU --sid 001 --session ses-1 --dry-run
python -m preproc.cli mriqc --subject sub-TJNU001 --dry-run
python -m preproc.cli fmriprep --site TJNU --sid 001 --dry-run
python -m preproc.cli xcpd --site TJNU --sid 001 --dry-run
```

## 4. Batch mode (config-driven, recommended)

Run all configured stages from one YAML file:

```bash
python -m preproc.cli batch --config config/pipeline.example.yml --extra-args "--dry-run"
```

- `--only` runs only selected stages (repeatable flag).
- `--extra-args` forwards additional args to every stage (e.g., `--dry-run`, `--queue`).

## 5. Repository layout

- `preproc/`: primary Python implementation
- `scripts/`: Python entry scripts per stage
- `config/`: configuration examples (including batch YAML)
- `template/`: qsub and workflow templates
- `R/`, `preprocess/*.R`: legacy R implementation (compatibility/reference)
- `sourcedata/`, `rawdata/`, `derivatives/`, etc.: data folders

## 6. Notes

- The workflow and templates are customized to this project's data conventions.
- Cluster submission depends on `qsub` and corresponding runtime/container images (e.g., heudiconv, mriqc, fmriprep, xcp_d).
- BIDS reference: https://bids.neuroimaging.io/
