from __future__ import annotations

from pathlib import Path
import shlex
from typing import Any
import yaml

VALID_STAGES = {"heudiconv", "mriqc", "fmriprep", "xcpd"}


def _normalize_option_name(name: str) -> str:
    return name.replace("_", "-")


def _to_cli_args(options: dict[str, Any]) -> list[str]:
    args: list[str] = []
    for key, value in options.items():
        flag = f"--{_normalize_option_name(key)}"
        if value is None:
            continue
        if isinstance(value, bool):
            if value:
                args.append(flag)
            continue
        if isinstance(value, list):
            if len(value) == 0:
                continue
            args.append(flag)
            args.extend([str(v) for v in value])
            continue
        args.extend([flag, str(value)])
    return args


def _load_plan(config_path: str | Path) -> dict[str, Any]:
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Pipeline config not found: {path}")
    with path.open("r", encoding="utf-8") as f:
        plan = yaml.safe_load(f)
    return plan or {}


def _select_stages(plan: dict[str, Any], only: list[str] | None = None) -> list[str]:
    stages = plan.get("pipeline", {}).get("stages", [])
    if not stages:
        raise ValueError("No pipeline stages configured. Add pipeline.stages in YAML.")
    invalid = [s for s in stages if s not in VALID_STAGES]
    if invalid:
        raise ValueError(f"Unknown stages in pipeline.stages: {', '.join(invalid)}")
    if only:
        missing = [s for s in only if s not in stages]
        if missing:
            raise ValueError(f"Stages not present in configured pipeline: {', '.join(missing)}")
        return [s for s in stages if s in only]
    return stages


def run_pipeline_plan(config_path: str | Path, only: list[str] | None = None, extra_args: str | None = None):
    """Run a multi-stage pipeline from a YAML plan.

    The plan supports:
    - pipeline.stages: [heudiconv, mriqc, fmriprep, xcpd]
    - args: shared options applied to all stages
    - stage_args.<stage>: stage-specific options merged over args
    """
    plan = _load_plan(config_path)
    stages = _select_stages(plan, only=only)
    shared = plan.get("args", {})
    stage_args = plan.get("stage_args", {})
    extra = shlex.split(extra_args) if extra_args else []

    for stage in stages:
        merged = dict(shared)
        merged.update(stage_args.get(stage, {}))
        args = _to_cli_args(merged) + extra
        _run_context(stage, args)


def _run_context(context: str, args_list: list[str] | None = None):
    """Delegate to the canonical CLI execution path to avoid logic drift."""
    from .cli import run_context

    run_context(context, args_list)
