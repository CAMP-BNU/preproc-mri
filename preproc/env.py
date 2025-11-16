from pathlib import Path
import os
from dotenv import load_dotenv


def load_dotenv_if_present():
    dotenv_path = Path.cwd() / '.env'
    if dotenv_path.exists():
        load_dotenv(dotenv_path=dotenv_path)


def get_project_root() -> Path:
    # prefer env var; if not set, use cwd or repository root
    p = os.environ.get('PROJECT_ROOT')
    if p:
        return Path(p)
    # fallback to cwd
    return Path.cwd()


def get_env_settings():
    """Returns mapping of environment settings and sensible defaults mirroring exec scripts."""
    from os import environ
    DEF = {
        'FMRIPREP_CONTAINER': '/opt/fmritools/containers/fmriprep-v23.1.4.sif',
        'SINGULARITY_CMD': 'singularity',
        'FMRIPREP_CMD': environ.get('FMRIPREP_CMD', None),
        'INPUT_DIR': environ.get('INPUT_DIR', f"{get_project_root()}/rawdata"),
        'OUTPUT_DIR': environ.get('OUTPUT_DIR', f"{get_project_root()}/derivatives/fmriprep"),
        'BIDS_DATABASE_DIR': environ.get('BIDS_DATABASE_DIR', f"{get_project_root()}/bids_db"),
        'WORK_DIR': environ.get('WORK_DIR', f"{get_project_root()}/tmp"),
        'FS_SUBJECTS_DIR': environ.get('FS_SUBJECTS_DIR', f"{get_project_root()}/derivatives/freesurfer"),
    }
    # fallback to environment values
    for k in list(DEF.keys()):
        d_val = environ.get(k)
        if d_val is not None:
            DEF[k] = d_val
    return DEF


# call on import to load .env
load_dotenv_if_present()
