from .constants import *
from .utils import *
from pathlib import Path
import pandas as pd
import re
import yaml


def list_jobs_whole_xcpd():
    from .fmriprep import list_jobs_status_fmriprep
    df = list_jobs_status_fmriprep()
    df2 = df[df['status'] == 'done']
    return df2.drop(columns=['status'])


def list_jobs_status_xcpd():
    file_xcpd_jobs = Path(path_log) / 'xcpd_jobs.tsv'
    if not file_xcpd_jobs.exists():
        return pd.DataFrame(columns=['subject', 'site', 'sid', 'status'])
    df = pd.read_csv(file_xcpd_jobs, sep='\t', header=None, usecols=[0, 2], names=['subject', 'status'])
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


def commit_xcpd(sublist, file_sublist=None, nthreads=None, pe=None, config_params='default', **kwargs):
    import datetime
    if file_sublist is None:
        dir_file_sublist = Path(path_tmp) / 'qsub' / 'xcpd'
        dir_file_sublist.mkdir(parents=True, exist_ok=True)
        file_sublist = dir_file_sublist / f"sublist-{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
    file_sublist.write_text('\n'.join(sublist['subject'].astype(str).tolist()))
    use_pe = ''
    if nthreads and nthreads > 1 and pe:
        use_pe = f"#$ -pe {pe} {nthreads}"
    num_jobs = len(sublist)
    # Parse config file for params
    from re import sub
    raw = Path(file_config_xcpd).read_text()
    raw = sub(r"!expr fs::path\(Sys.getenv\(\"PROJECT_ROOT\"\),\s*\"([^\"]+)\"\)",
              lambda m: f"{project_root}/{m.group(1)}", raw)
    cfg = yaml.safe_load(raw)
    params = cfg.get('params', {}).get(config_params, {})
    params_post = clize_list(params)
    qsub_fn = Path(path_qsub) / 'xcpd.tmpl.qsub'
    tmpl = qsub_fn.read_text()
    from .utils import render_template
    from .env import get_env_settings
    mapping = get_env_settings()
    mapping.update({'PROJECT_ROOT': str(project_root), 'PARAMS': params_post})
    cmd = render_template(tmpl, mapping)
    job_main = commit(cmd, 'xcpd', num_jobs=num_jobs, file_sublist=file_sublist)
    qsub_clean_fn = Path(path_qsub) / 'clean_xcpd.tmpl.qsub'
    cmd_clean = render_template(qsub_clean_fn.read_text(), {'PROJECT_ROOT': str(project_root)})
    commit(cmd_clean, 'clean_xcpd')
    return job_main
