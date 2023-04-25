#!/usr/bin/env bash
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
# heudiconv setup
: ${HEUDICONV_CONTAINER:=/opt/fmritools/containers/heudiconv-0.12.2.sif}
: ${HEUDICONV_CMD:=${SINGULARITY_CMD} exec -c -e -B /seastor:/seastor ${HEUDICONV_CONTAINER} heudiconv}
# get the path where stores current script
DIR_SELF=`dirname $0`
fsl_sub -l ${PROJECT_ROOT}/logs \
    -N heudiconv_sub-${SUBJECT}_ses-${SESSION} \
    ${HEUDICONV_CMD} \
    -d ${PROJECT_ROOT}/sourcedata/{subject}_*_{session}/*/*/*.IMA \
    -o ${PROJECT_ROOT}/rawdata -s $SUBJECT -ss $SESSION \
    -f ${DIR_SELF}/heuristic.py \
    --anon-cmd ${DIR_SELF}/minimize_subid.py \
    -c dcm2niix -b --overwrite --minmeta
