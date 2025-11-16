#!/usr/bin/env python3
"""
A minimal rewritten version of `preprocess/perform_fmriprep.R` in Python.
"""
import argparse
from preproc.runner import run_pipeline


def main():
    import sys
    # forward any extra args to run_pipeline
    run_pipeline('fmriprep', extra_args=sys.argv[1:])


if __name__ == '__main__':
    main()
