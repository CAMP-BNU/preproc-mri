#!/usr/bin/env bash
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
# heudiconv setup
: ${HEUDICONV_CONTAINER:=/opt/fmritools/containers/heudiconv-0.12.2.sif}
: ${HEUDICONV_CMD:=${SINGULARITY_CMD} run -c -e -B /seastor:/seastor ${HEUDICONV_CONTAINER}}
# get the path where stores current script
DIR_SELF=`dirname $0`

${HEUDICONV_CMD} \
    --dicom_dir_template ${PROJECT_ROOT}/sourcedata/{subject}_*_{session}/*/*/*.IMA \
    --outdir ${PROJECT_ROOT}/rawdata \
    --subjects $SUBJECT \
    --ses $SESSION \
    --heuristic ${DIR_SELF}/heudiconv/heuristic.py \
    --anon-cmd ${DIR_SELF}/heudiconv/format_subject.py \
    --converter dcm2niix \
    --bids --overwrite --minmeta
