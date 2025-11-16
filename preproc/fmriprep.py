from .constants import *
from .utils import *
from pathlib import Path
import pandas as pd
import re


def list_jobs_whole_fmriprep(skip_session_check=False):
    # For now, we use the heudiconv status list as a base (includes 'subject')
    from .heudiconv import list_jobs_status_heudiconv
    jobs = list_jobs_status_heudiconv()
    if not skip_session_check:
        # require at least 2 sessions per subject
        counts = jobs.groupby('subject').size()
        valid_subjects = counts[counts >= 2].index.tolist()
        jobs = jobs[jobs['subject'].isin(valid_subjects)]
    return jobs[['subject', 'site', 'sid']].drop_duplicates()


def list_jobs_status_fmriprep():
    if not Path(file_fmriprep_jobs).exists():
        return pd.DataFrame(columns=['subject', 'site', 'sid', 'status'])
    # Assume file has columns subject, job, status, start_time, finish_time
    df = pd.read_csv(file_fmriprep_jobs, sep='\t', header=None, usecols=[0, 2], names=['subject', 'status'])
    # Keep the latest by subject
    # R: slice_tail(n=1, by = subject) -> in pandas, groupby tail
    df = df.groupby('subject').tail(1)
    def _site(x):
        m = re.match(r'^([A-Z]+)', x)
        return m.group(1) if m else ''
    def _sid(x):
        m = re.search(r'\d{3}', x)
        return m.group(0) if m else ''
    df['site'] = df['subject'].map(_site)
    df['sid'] = df['subject'].map(_sid)
    df['status'] = df['status'].apply(lambda s: 'done' if s == 0 else 'incomplete')
    return df[['subject', 'site', 'sid', 'status']]


def commit_fmriprep(sublist, file_sublist=None, nthreads=None, pe=None, **kwargs):
    # create sublist file
    import datetime
    if file_sublist is None:
        dir_file_sublist = Path(path_tmp) / 'qsub' / 'fmriprep'
        dir_file_sublist.mkdir(parents=True, exist_ok=True)
        file_sublist = dir_file_sublist / f"sublist-{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
    file_sublist.write_text('\n'.join(sublist['subject'].astype(str).tolist()))
    use_pe = ''
    if nthreads and nthreads > 1 and pe:
        use_pe = f"#$ -pe {pe} {nthreads}"
    num_jobs = len(sublist)
    # prepare job template
    qsub_fn = Path(path_qsub) / 'fmriprep.tmpl.qsub'
    with qsub_fn.open('r') as f:
        tmpl = f.read()
    # Basic template substitution: minimal implementation
    from .env import get_env_settings
    mapping = get_env_settings()
    mapping.update({
        'PROJECT_ROOT': str(project_root),
        'INPUT_DIR': str(path_raw),
        'OUTPUT_DIR': str(path_derivatives / 'fmriprep'),
        'BIDS_DATABASE_DIR': str(path_bids_db),
        'WORK_DIR': str(path_tmp),
        'PE': use_pe,
        'NTHREADS': nthreads or '',
        'FILE_SUBLIST': str(file_sublist),
    })
    from .utils import render_template
    cmd = render_template(tmpl, mapping)
    job_main = commit(cmd, 'fmriprep', num_jobs=num_jobs, file_sublist=file_sublist)
    # clean job
    qsub_clean_fn = Path(path_qsub) / 'clean_fmriprep.tmpl.qsub'
    with qsub_clean_fn.open('r') as f:
        tmpl_clean = f.read()
    cmd_clean = render_template(tmpl_clean, {'PROJECT_ROOT': str(project_root)})
    job_clean = commit(cmd_clean, 'clean_fmriprep')
    return job_main
