"""
Utilities: argument parsing, commit, and a few other helpers.
"""
from pathlib import Path
import argparse
import os
import subprocess
import tempfile
from typing import List, Dict, Any
import sys
from .logutil import get_logger
from .constants import *

# Load .env if present
try:
    from dotenv import load_dotenv
    load_dotenv(dotenv_path=Path.cwd() / ".env")
except Exception:
    # python-dotenv optional; if not available we still proceed
    pass


def parse_arguments(context: str, args_list: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description={
            "heudiconv": "Submitting jobs to convert dicom to bids format",
            "mriqc": "Submitting jobs to do mriqc for bids data",
            "fmriprep": "Submitting jobs to do fmriprep for bids data",
            "xcpd": "Submitting jobs to do post-processing steps for connectivity",
        }[context]
    )
    # shared arguments
    parser.add_argument("--site", "-t", help="The site", required=False)
    parser.add_argument("--sid", "-i", nargs="*", help="The subject id", required=False)
    parser.add_argument(
        "--rerun",
        default="unprocessed",
        choices=["unprocessed", "invalid", "all"],
        help="Specify the level of analysis re-run",
    )
    parser.add_argument("--max-jobs", "-n", type=int, default=10, help="Maximal jobs to submit")
    parser.add_argument("--queue", default="long.q", help="Specify which queue to run")
    parser.add_argument("--dry-run", action="store_true", help="Skip really executing the jobs?")
    parser.add_argument("--nthreads", "-u", type=int, help="Number of threads in processing.")
    parser.add_argument("--omp-nthreads", type=int, help="Maximum number of threads per-process.")
    parser.add_argument("--pe", default="ompi", help="parallel environment")
    if context in ("heudiconv", "mriqc"):
        parser.add_argument("--session", "-e", help="The session number")
    if context in ("mriqc", "fmriprep", "xcpd"):
        parser.add_argument("--subject", "-s", nargs="*", help="The subject identifier in bids.")
    if context == "fmriprep":
        parser.add_argument("--skip-session-check", "-p", action="store_true", help="Do not check if data exist for both sessions?")
        parser.add_argument("--clean-last", default="none", choices=["none", "results", "freesurfer", "all"], help="Clean results from last run?")
    if context == "xcpd":
        parser.add_argument("--config-params", "-g", default="default", help="Name of configuration for xcp_d post processing parameters.")
    args = parser.parse_args(args_list)
    # normalize rerun to an integer in line with R implementation if needed
    rerun_map = {"unprocessed": 1, "invalid": 2, "all": 3}
    args.rerun = rerun_map.get(args.rerun, 1)
    return args


def clize_list(kwargs: Dict[str, Any]) -> str:
    parts = []
    for k, v in kwargs.items():
        if isinstance(v, bool):
            if v:
                parts.append(f"--{k}")
        elif v is None:
            continue
        elif isinstance(v, (list, tuple)):
            parts.append(f"--{k} {' '.join(map(str, v))}")
        else:
            parts.append(f"--{k} {v}")
    return " ".join(parts)


from .logutil import get_logger
logger = get_logger()


def commit(command: str, disp_name: str, num_jobs: int = None, file_sublist: Path = None) -> str:
    """Commit a job script into cluster using qsub. Returns jobid."""
    with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".sh") as script:
        script.write(command)
        script_fn = script.name
    if num_jobs is None:
        logger.info(f"Committing job: {disp_name}.")
    else:
        logger.info(f"Committing array job: {disp_name}, job count: {num_jobs}.")
        if file_sublist:
            logger.info(f"See file {file_sublist} for full list of subjects.")
    try:
        proc = subprocess.run(["qsub", "-terse", script_fn], capture_output=True, check=True, text=True)
        job_id = proc.stdout.strip()
        logger.info(f"Committing job succeeded as ({job_id}).")
        return job_id
    except subprocess.CalledProcessError as e:
        logger.error("qsub failed:" + (e.stderr or ""))
        raise


def render_template(template: str, mapping: dict, required=True) -> str:
    """Replace occurrences of ${VAR} or ${VAR:-default} in templates with mapping values.
    This mirrors basic shell substitution used in the R templates.
    """
    import re

    def repl(m):
        expr = m.group(1)
        if ':-' in expr:
            name, default = expr.split(':-', 1)
        else:
            name, default = expr, None
        val = mapping.get(name)
        if val is None:
            val = os.environ.get(name)
        if val is None:
            val = default
        if val is None:
            if default:
                return str(default)
            if required:
                raise KeyError(f"Template variable '{name}' not found in mapping or environment and has no default.")
            return ''
        return str(val)

    return re.sub(r"\$\{([^}]+)\}", repl, template)


def validate_argv(context: str, args: argparse.Namespace):
    if context in ("mriqc", "fmriprep"):
        if getattr(args, "subject", None) and (getattr(args, "site", None) or getattr(args, "sid", None)):
            raise ValueError("Cannot specify --site or --sid when --subject is specified")
    if not getattr(args, "site", None) and getattr(args, "sid", None):
        raise ValueError("Cannot specify --sid without --site specified")
    if context == "heudiconv":
        if getattr(args, "session", None) and (not getattr(args, "site") or not getattr(args, "sid")):
            raise ValueError("Cannot specify --session without --site and --sid specified")
    return args


def args_to_env(args: argparse.Namespace) -> Dict[str, str]:
    d = {k: str(v) for k, v in vars(args).items() if v is not None}
    return d


def validate_data_file_sum(kind: str, path: Path = None, subject: str = None, part: str = None, check: bool = False) -> str:
    file_sum_min = {
        'heudiconv': {
            'ses-1': [1, 4, 4, 14, 18],
            'ses-2': [1, 2, 12, 21],
        },
        'fmriprep': {
            'anat': 2,
            'figures': 116,
            'ses-1': [48, 12, 252],
            'ses-2': [12, 294],
        }
    }
    if not path and subject:
        if kind == 'heudiconv':
            path = Path(path_raw) / subject / part
        elif kind == 'fmriprep':
            path = Path(path_derivatives) / 'fmriprep' / f"sub-{subject}" / part
    if part not in file_sum_min.get(kind, {}):
        return 'done'
    if not check:
        return 'done' if path.exists() else 'todo'
    files = [p for p in path.rglob('*') if p.is_file()]
    dirs = {p.parent.name: 0 for p in files}
    for p in files:
        dirs[p.parent.name] += 1
    counts = list(dirs.values())
    expected = file_sum_min[kind][part]
    if isinstance(expected, list):
        if len(counts) == len(expected) and all(c == e for c, e in zip(counts, expected)):
            return 'done'
        return 'incomplete'
    return 'done' if sum(counts) >= expected else 'incomplete'


def clean_json_embed(file_origin: Path, file_corrected: Path = None, inplace: bool = True):
    content_origin = Path(file_origin).read_text()
    content_corrected = content_origin.replace("\\u0000", "")
    if content_origin != content_corrected:
        if inplace:
            file_corrected = file_origin
        if file_corrected:
            Path(file_corrected).write_text(content_corrected)
