from pathlib import Path
from .env import get_project_root

project_root = get_project_root()
# data folders
path_src = project_root / "sourcedata"
path_raw = project_root / "rawdata"
path_bids_db = project_root / "bids_db"
path_derivatives = project_root / "derivatives"
path_backup = project_root / "backup"
path_tmp = project_root / "tmp"
path_log = project_root / "logs"
# code folders
path_template = project_root / "template"
path_qsub = path_template / "qsub"
# job status logs
file_fmriprep_jobs = path_log / "fmriprep_jobs.tsv"
# configurations
file_config_xcpd = project_root / "config" / "xcpd.yml"
