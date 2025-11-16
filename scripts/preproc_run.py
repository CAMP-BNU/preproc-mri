#!/usr/bin/env python3
"""Script entrypoint that wraps `preproc.runner.run_pipeline`.

This lets you call any of the pipelines with one script, e.g.
  python scripts/preproc_run.py fmriprep --site TJNU --sid 001

It automatically sets `PROJECT_ROOT` to the repository root if not set.
"""
from __future__ import annotations
import sys
from preproc.runner import run_pipeline


def main():
    if len(sys.argv) < 2:
        print("Usage: preproc_run.py <pipeline> [--project-root ...] [pipeline args...]")
        sys.exit(2)
    pipeline = sys.argv[1]
    run_pipeline(pipeline, extra_args=sys.argv[2:])


if __name__ == '__main__':
    main()
