#!/usr/bin/env python3

from pathlib import Path

# following lines are based on
# https://github.com/nipreps/fmriprep/blob/a1974f706ce2250f0535b9f42af395e2fb227a82/fmriprep/config.py#L454-L481
def init_layout(bids_dir=Path("rawdata"), db_path=Path("bids_db"), reset=False):
    import re

    from bids.layout import BIDSLayout
    from bids.layout.index import BIDSLayoutIndexer

    db_path.mkdir(exist_ok=True, parents=True)
    _indexer = BIDSLayoutIndexer(
        validate=False,
        ignore=(
            "code",
            "stimuli",
            "sourcedata",
            "models",
            re.compile(r"^\."),
            re.compile(
                r"sub-[a-zA-Z0-9]+(/ses-[a-zA-Z0-9]+)?/(beh|dwi|eeg|ieeg|meg|perf)"
            ),
        ),
    )
    BIDSLayout(
        bids_dir,
        database_path=db_path,
        reset_database=reset,
        indexer=_indexer,
    )

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Initialize BIDS layout")
    parser.add_argument("-r", "--reset", action="store_true", help="Reset database")
    parser.add_argument("-b", "--bids-dir", default="rawdata", help="BIDS directory")
    parser.add_argument("-d", "--db-path", default="bids_db", help="Database path")
    args = parser.parse_args()
    init_layout(bids_dir=Path(args.bids_dir), db_path=Path(args.db_path), reset=args.reset)
