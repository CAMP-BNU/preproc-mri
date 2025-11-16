import os
import sys
from pathlib import Path
from typing import List

from .cli import run_context


def _find_repo_root() -> Path:
    p = Path(__file__).resolve()
    # look for repo markers upwards
    for parent in p.parents:
        if (parent / '.git').exists() or (parent / 'pyproject.toml').exists() or (parent / 'CAMP.Rproj').exists():
            return parent
    return Path.cwd()


def run_pipeline(pipeline: str, extra_args: List[str] | None = None, project_root: str | None = None):
    """Central runner used by scripts.

    - Ensures PROJECT_ROOT is set.
    - Forwards args to the existing run_context function that uses argparse internally.
    """
    if project_root:
        os.environ['PROJECT_ROOT'] = str(project_root)
    else:
        if not os.environ.get('PROJECT_ROOT'):
            # set to project root detected from the package location
            os.environ['PROJECT_ROOT'] = str(_find_repo_root())
    # run
    # run_context expects a context name and args_list (list of strings)
    if extra_args is None:
        extra_args = []
    run_context(pipeline, extra_args)


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Run a preproc pipeline (fmriprep, heudiconv, mriqc, xcpd)')
    parser.add_argument('pipeline', choices=['fmriprep', 'heudiconv', 'mriqc', 'xcpd'])
    parser.add_argument('--project-root', help='Specify the repository project root override')
    parser.add_argument('rest', nargs=argparse.REMAINDER, help='Pipeline args forwarded to preproc')
    args = parser.parse_args()
    run_pipeline(args.pipeline, args.rest, project_root=args.project_root)


if __name__ == '__main__':
    main()
