# Python 使用说明（主力工作流）

当前仓库已经支持完整的 Python 端流程组织，建议将 Python 作为日常预处理主入口。

## 核心能力

- 按阶段执行：`heudiconv` / `mriqc` / `fmriprep` / `xcpd`
- 配置驱动批处理：`batch`
- 参数透传与阶段筛选：`--extra-args`、`--only`

## 快速开始

### 1) 安装依赖

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2) 设置项目根目录（推荐）

```bash
export PROJECT_ROOT=$(pwd)
```

### 3) 单阶段命令示例

```bash
python -m preproc.cli fmriprep --site TJNU --sid 001 --dry-run
```

## 批处理（借鉴 preproc-fmri 的配置化思路）

为了更贴近 `preproc-fmri` 这类“配置驱动 + 多阶段串行”工作方式，新增 `batch` 命令：

```bash
python -m preproc.cli batch --config config/pipeline.example.yml --extra-args "--dry-run"
```

### YAML 设计要点

- `pipeline.stages`：定义阶段顺序（如 `heudiconv -> mriqc -> fmriprep -> xcpd`）
- `args`：共享参数（应用到所有阶段）
- `stage_args.<stage>`：阶段覆盖参数

示例配置见：`config/pipeline.example.yml`。

## 与 R 的关系

- `R/` 与 `preprocess/*.R` 仍保留，便于回溯与兼容旧流程。
- 新增功能与后续维护建议优先在 Python 端进行。
