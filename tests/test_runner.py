import os
import sys
import pytest
from pathlib import Path

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from preproc.runner import run_pipeline, _find_repo_root


def test_find_repo_root():
    root = _find_repo_root()
    assert (root / 'pyproject.toml').exists() or (root / '.git').exists() or (root / 'CAMP.Rproj').exists()


def test_run_pipeline_sets_project_root(tmp_path, monkeypatch):
    # ensure no PROJECT_ROOT in env
    monkeypatch.delenv('PROJECT_ROOT', raising=False)
    run_pipeline('fmriprep', extra_args=['--dry-run'])
    assert os.environ.get('PROJECT_ROOT') is not None
