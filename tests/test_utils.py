import os
import sys
from pathlib import Path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from preproc import env, utils


def test_get_env_settings():
    os.environ['PROJECT_ROOT'] = '/tmp/project'
    s = env.get_env_settings()
    assert Path(s['INPUT_DIR']).exists() or str(Path(s['INPUT_DIR'])).endswith('rawdata')
    assert 'PROJECT_ROOT' in s or os.environ.get('PROJECT_ROOT')


def test_parse_arguments():
    # Simulate CL args
    sys.argv = ['perform_fmriprep.py', '--site', 'TJNU', '--sid', '001']
    args = utils.parse_arguments('fmriprep')
    assert args.site == 'TJNU'
    assert 'sid' in args and '001' in args.sid
