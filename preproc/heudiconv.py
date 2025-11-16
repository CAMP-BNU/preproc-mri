from .constants import *
from .utils import *
from pathlib import Path
import pandas as pd
import re


def list_jobs_whole_heudiconv():
    folders = [p.name for p in Path(path_src).iterdir() if p.is_dir()]
    rows = []
    for folder in folders:
        m = re.search(r"(.+SUB\d{3})", folder)
        sub_dcm = m.group(1) if m else folder
        site = re.match(r"^[A-Z]+", sub_dcm).group(0) if re.match(r"^[A-Z]+", sub_dcm) else ''
        sid_m = re.search(r"\d{3}$", sub_dcm)
        sid = sid_m.group(0) if sid_m else ''
        session_m = re.search(r"(\d)$", folder)
        session = session_m.group(1) if session_m else ''
        rows.append({"sub_dcm": sub_dcm, "site": site, "sid": sid, "session": session})
    return pd.DataFrame(rows)


def list_jobs_status_heudiconv(check_file_sum=False):
    base = Path(path_raw) / '.heudiconv'
    if not base.exists():
        return pd.DataFrame(columns=["subject", "site", "sid", "session", "status"])
    folders = [p for p in base.iterdir() if p.is_dir()]
    rows = []
    for folder in folders:
        subject = folder.name
        site = re.match(r"^[A-Z]+", subject).group(0) if re.match(r"^[A-Z]+", subject) else ''
        sid = re.search(r"\d{3}", subject).group(0) if re.search(r"\d{3}", subject) else ''
        ses_dirs = [p for p in folder.glob('*') if p.is_dir() and re.search(r'ses', p.name)]
        if not ses_dirs:
            continue
        for d in ses_dirs:
            part = d.name
            session = re.search(r"(\d)$", part).group(1) if re.search(r"(\d)$", part) else ''
            status = validate_data_file_sum('heudiconv', subject=subject, part=part, check=check_file_sum)
            rows.append({"subject": subject, "site": site, "sid": sid, "session": session, "status": status})
    return pd.DataFrame(rows)


def commit_heudiconv(sublist, file_sublist=None, **kwargs):
    import datetime
    if file_sublist is None:
        dir_file_sublist = Path(path_tmp) / 'qsub' / 'heudiconv'
        dir_file_sublist.mkdir(parents=True, exist_ok=True)
        file_sublist = dir_file_sublist / f"sublist-{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
    # heudiconv expects sub_dcm and session
    sublist[ ['sub_dcm', 'session'] ].to_csv(file_sublist, sep='\t', index=False, header=False)
    num_jobs = len(sublist)
    qsub_fn = Path(path_qsub) / 'heudiconv.tmpl.qsub'
    tmpl = qsub_fn.read_text()
    from .utils import render_template
    from .env import get_env_settings
    mapping = get_env_settings()
    mapping.update({'PROJECT_ROOT': str(project_root)})
    cmd = render_template(tmpl, mapping)
    job_main = commit(cmd, 'heudiconv', num_jobs=num_jobs, file_sublist=file_sublist)
    # build bids db
    qsub_build = Path(path_qsub) / 'build_bidsdb.tmpl.qsub'
    cmd_build = render_template(qsub_build.read_text(), mapping)
    commit(cmd_build, 'build_bidsdb')
    return job_main
