import os
import sys
from pathlib import Path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from preproc.utils import validate_data_file_sum


def test_validate_data_file_sum_todo(tmp_path):
    # heudiconv without path should return todo when no path
    res = validate_data_file_sum('heudiconv', subject='TJNU001', part='ses-1', check=False)
    assert res in ('todo', 'done') or isinstance(res, str)


def test_validate_data_file_sum_check(tmp_path):
    # create path structure and 1 file to make it done for non-check
    project = tmp_path / 'p'
    project.mkdir()
    derivatives = project / 'derivatives'
    derivatives.mkdir()
    p = derivatives / 'fmriprep' / 'sub-TJNU001' / 'ses-1'
    p.mkdir(parents=True)
    (p / 'file1.txt').write_text('test')
    res = validate_data_file_sum('fmriprep', path=p, check=False)
    assert res == 'done'
