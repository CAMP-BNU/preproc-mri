#!/usr/bin/env python3
from preproc.runner import run_pipeline


def main():
    import sys
    run_pipeline('xcpd', extra_args=sys.argv[1:])


if __name__ == '__main__':
    main()
