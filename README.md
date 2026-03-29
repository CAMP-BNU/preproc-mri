# preproc-mri（Python 主力版）

本仓库用于 MRI 预处理流程管理，当前**推荐以 Python 工作流为主**，R 脚本作为历史兼容与参考实现保留。

## 1. 处理流程（推荐）

建议按以下阶段执行：

1. `heudiconv`：DICOM → BIDS
2. `mriqc`：质量评估
3. `fmriprep`：功能像预处理
4. `xcpd`：后处理与连接分析准备

你可以使用单阶段命令，也可以使用配置驱动的一键批处理（`batch`）。

## 2. Python 环境准备

```bash
python -m venv .venv
source .venv/bin/activate   # Windows 请使用对应激活命令
pip install -r requirements.txt
```

建议设置项目根目录：

```bash
export PROJECT_ROOT=$(pwd)
```

## 3. 单阶段执行示例

```bash
python -m preproc.cli heudiconv --site TJNU --sid 001 --session ses-1 --dry-run
python -m preproc.cli mriqc --subject sub-TJNU001 --dry-run
python -m preproc.cli fmriprep --site TJNU --sid 001 --dry-run
python -m preproc.cli xcpd --site TJNU --sid 001 --dry-run
```

## 4. 批处理（配置驱动，推荐）

使用 YAML 一次定义多个阶段：

```bash
python -m preproc.cli batch --config config/pipeline.example.yml --extra-args "--dry-run"
```

- `--only` 可只运行指定阶段（可重复传参）。
- `--extra-args` 会透传到每个阶段（如 `--dry-run`、`--queue` 等）。

## 5. 目录说明

- `preproc/`：Python 主实现（推荐）
- `scripts/`：Python 阶段脚本入口
- `config/`：配置样例（含 batch YAML）
- `template/`：qsub 与流程模板
- `R/`、`preprocess/*.R`：历史 R 实现（兼容/参考）
- `sourcedata/`、`rawdata/`、`derivatives/` 等：数据目录

## 6. 说明

- 本仓库流程与模板对当前数据组织有较强定制性。
- 集群提交依赖 `qsub` 及对应容器/环境（如 heudiconv、mriqc、fmriprep、xcp_d）。
- BIDS 规范参考：https://bids.neuroimaging.io/
