from .constants import *
from .utils import *
from pathlib import Path
import pandas as pd
import re


def list_jobs_whole_mriqc():
    # In R, this maps to fmriprep status.
    from .fmriprep import list_jobs_status_fmriprep
    df = list_jobs_status_fmriprep()
    return df[['subject', 'site', 'sid']]


def list_jobs_status_mriqc(check_file_sum=False):
    # collect files under derivatives/mriqc
    base = Path(path_derivatives) / 'mriqc'
    if not base.exists():
        return pd.DataFrame(columns=['subject', 'session', 'status'])
    files = list(base.glob('**/*sub-*'))
    rows = []
    # match sub-..._ses-1 etc
    for f in files:
        m = re.search(r'sub-([A-Za-z0-9]+)_ses-(\d)', f.name)
        if not m:
            continue
        subject = m.group(1)
        session = m.group(2)
        rows.append({'subject': subject, 'session': session})
    df = pd.DataFrame(rows)
    if df.empty:
        return pd.DataFrame(columns=['subject', 'session', 'status'])
    counts = df.groupby(['subject', 'session']).size().reset_index(name='n')
    if check_file_sum:
        counts['status'] = counts['n'].apply(lambda n: 'done' if n == 8 else ('todo' if n == 0 else 'incomplete'))
    else:
        counts['status'] = counts['n'].apply(lambda n: 'done' if n >= 1 else 'todo')
    return counts[['subject', 'session', 'status']]


def commit_mriqc(sublist, file_sublist=None, **kwargs):
    import datetime
    if file_sublist is None:
        dir_file_sublist = Path(path_tmp) / 'qsub' / 'mriqc'
        dir_file_sublist.mkdir(parents=True, exist_ok=True)
        file_sublist = dir_file_sublist / f"sublist-{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
    sublist[['subject', 'session']].to_csv(file_sublist, sep='\t', index=False, header=False)
    num_jobs = len(sublist)
    qsub_fn = Path(path_qsub) / 'mriqc.tmpl.qsub'
    tmpl = qsub_fn.read_text()
    from .utils import render_template
    from .env import get_env_settings
    mapping = get_env_settings()
    mapping.update({'PROJECT_ROOT': str(project_root)})
    cmd = render_template(tmpl, mapping)
    commit(cmd, 'mriqc', num_jobs=num_jobs, file_sublist=file_sublist)
