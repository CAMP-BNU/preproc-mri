# Python Usage Guide (Primary Workflow)

The repository now supports a complete Python-side orchestration flow, and Python should be treated as the default entrypoint for daily preprocessing.

## Core capabilities

- Stage-level execution: `heudiconv` / `mriqc` / `fmriprep` / `xcpd`
- Config-driven batch execution via `batch`
- Shared and stage-specific argument control via YAML

## Quick start

### 1) Install dependencies

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2) Set project root (recommended)

```bash
export PROJECT_ROOT=$(pwd)
```

### 3) Single-stage example

```bash
python -m preproc.cli fmriprep --site TJNU --sid 001 --dry-run
```

## Batch mode (inspired by preproc-fmri's config-driven style)

```bash
python -m preproc.cli batch --config config/pipeline.example.yml --extra-args "--dry-run"
```

### YAML design

- `pipeline.stages`: defines stage order (for example `heudiconv -> mriqc -> fmriprep -> xcpd`)
- `args`: shared options applied to all stages
- `stage_args.<stage>`: stage-specific overrides

See `config/pipeline.example.yml` for a full example.

## Relationship with legacy R scripts

- `R/` and `preprocess/*.R` are still available for compatibility and historical reference.
- New features and ongoing maintenance should prioritize the Python implementation.
