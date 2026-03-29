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


## Python-first orchestration (借鉴 preproc-fmri 的流程)

为了更接近 `preproc-fmri` 这类“配置驱动 + 多阶段串行”的工作方式，仓库新增了 `batch` 命令：

```bash
python -m preproc.cli batch --config config/pipeline.example.yml --extra-args "--dry-run"
```

核心思路：
- 在一个 YAML 文件中定义阶段顺序（heudiconv → mriqc → fmriprep → xcpd）。
- 使用 `[args]` 定义共享参数。
- 使用 `[stage_args.<stage>]` 覆盖阶段特定参数。
- 支持 `--only` 只跑某几个阶段。

示例配置见：`config/pipeline.example.yml`。
