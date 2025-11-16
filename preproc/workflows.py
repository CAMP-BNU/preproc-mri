"""
Workflows translated from R: prepare_jobs, extract_todo, execute_jobs.
"""
from .constants import *
from .utils import *
from .logutil import get_logger
from .fmriprep import list_jobs_whole_fmriprep, list_jobs_status_fmriprep, commit_fmriprep
from .heudiconv import list_jobs_status_heudiconv, list_jobs_whole_heudiconv
from .mriqc import list_jobs_whole_mriqc, list_jobs_status_mriqc
from .xcpd import list_jobs_whole_xcpd, list_jobs_status_xcpd

import pandas as pd


def prepare_jobs(context: str, argv: argparse.Namespace):
    keys_map = {
        "heudiconv": ["site", "sid", "session"],
        "fmriprep": ["subject", "site", "sid"],
        "xcpd": ["subject", "site", "sid"],
        "mriqc": ["subject", "session"],
    }
    keys = keys_map[context]
    if context == "heudiconv":
        jobs_list = list_jobs_whole_heudiconv()
        jobs_status = list_jobs_status_heudiconv(argv.rerun >= 2)
    if context == "fmriprep":
        jobs_list = list_jobs_whole_fmriprep(argv.skip_session_check)
        jobs_status = list_jobs_status_fmriprep()
    if context == "mriqc":
        jobs_list = list_jobs_whole_mriqc()
        jobs_status = list_jobs_status_mriqc(argv.rerun >= 2)
    if context == "xcpd":
        jobs_list = list_jobs_whole_xcpd()
        jobs_status = list_jobs_status_xcpd()
    df = pd.merge(jobs_list, jobs_status, how="left", on=keys)
    df["status"] = df["status"].fillna("todo")
    return df


def extract_todo(context: str, jobs: pd.DataFrame, argv: argparse.Namespace) -> pd.DataFrame:
    def filter_field(df: pd.DataFrame, field: str):
        val = getattr(argv, field, None)
        if not val:
            return df
        df2 = df[df[field].isin(val if isinstance(val, (list, tuple)) else [val])]
        if df2.shape[0] == 0:
            raise ValueError("No suitable data found based on your specification.")
        if all(df2.status == "done") and argv.rerun < 3:
            raise ValueError("Given data have been finished. Try adding `--rerun all` if insisted.")
        return df2
    df = jobs.copy()
    for field in ["subject", "site", "sid", "session"]:
        df = filter_field(df, field)
    # filter by rerun
    status_rank = {"todo": 1, "incomplete": 2, "done": 3}
    df = df[df["status"].map(status_rank).fillna(1) <= argv.rerun]
    return df


def execute_jobs(context: str, jobs: pd.DataFrame, argv: argparse.Namespace):
    num_jobs = jobs.shape[0]
    logger = get_logger(__name__)
    if num_jobs > 0:
        if argv.dry_run:
            logger.info(f"There are {num_jobs} jobs to be committed. As follows:")
            pd.set_option('display.max_rows', None)
            logger.info('\n' + jobs.to_string(index=False))
        else:
            # Inject environment vars
            env = args_to_env(argv)
            if context == 'fmriprep':
                from .fmriprep import commit_fmriprep
                return commit_fmriprep(jobs, **env)
            if context == 'heudiconv':
                from .heudiconv import commit_heudiconv
                return commit_heudiconv(jobs, **env)
            if context == 'mriqc':
                from .mriqc import commit_mriqc
                return commit_mriqc(jobs, **env)
            if context == 'xcpd':
                from .xcpd import commit_xcpd
                return commit_xcpd(jobs, **env)
    else:
        logger.info("All jobs are done! No jobs were committed.")
    return None
