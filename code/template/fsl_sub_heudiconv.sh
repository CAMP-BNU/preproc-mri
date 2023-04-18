#!/usr/bin/env bash
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
# heudiconv setup
: ${HEUDICONV_CONTAINER:=/home/shaoxuhao2008/containers/neurobox-2.sif}
: ${HEUDICONV_CMD:=${SINGULARITY_CMD} exec -c -e -B /seastor:/seastor ${HEUDICONV_CONTAINER} heudiconv}
fsl_sub -l ${PROJECT_ROOT}/logs \
    -N heudiconv_site-${SITE}_sub-${SUBJECT}_ses-${SESSION} \
    ${HEUDICONV_CMD} -d ${PROJECT_ROOT}/sourcedata/${SITE}_*_CAMP_SUB{subject}_*_{session}/*/*/*.IMA \
    -o ${PROJECT_ROOT}/rawdata/${SITE} -s $SUBJECT -ss $SESSION \
    -f ${PROJECT_ROOT}/code/heuristic.py \
    -c dcm2niix -b --overwrite
