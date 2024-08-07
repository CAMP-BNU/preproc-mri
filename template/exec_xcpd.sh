#!/usr/bin/env bash
# prepare command of fmriprep
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
: ${XCPD_CONTAINER:=/opt/fmritools/containers/xcp_d-0.7.5.sif}
: ${XCPD_CMD:=${SINGULARITY_CMD} run -e -B /seastor,$HOME:/home/xcp_d --home /home/xcp_d ${XCPD_CONTAINER}}
# positional parameters
: ${CONFIG_PARAMS:=example}
: ${FMRI_DIR:=${PROJECT_ROOT}/derivatives/fmriprep}
: ${OUTPUT_DIR:=${PROJECT_ROOT}/derivatives/$CONFIG_PARAMS}
: ${BIDS_DATABASE_DIR:=${PROJECT_ROOT}/derivatives/layout_fmriprep}
: ${WORK_DIR:=${PROJECT_ROOT}/tmp}
# freesurfer
: ${FS_LICENSE:=/seastor/zhangliang/license.txt}
# performance related
: ${NTHREADS:=8}
: ${OMPTHREADS:=8}

export SINGULARITYENV_TEMPLATEFLOW_HOME=/home/xcp_d/.cache/templateflow/

${XCPD_CMD} \
    ${FMRI_DIR} ${OUTPUT_DIR} participant \
    `# filtering bids queries` \
    --participant_label ${SUBJECT} \
    --bids-database-dir ${BIDS_DATABASE_DIR} \
    `# post-processing parameters` \
    $PARAMS_POST \
    `# performance options` \
    --nthreads ${NTHREADS} \
    --omp-nthreads ${OMPTHREADS} \
    `# other options` \
    --work-dir ${WORK_DIR} \
    --stop-on-first-crash \
    --notrack \
    `# freesurfere options` \
    --fs-license-file ${FS_LICENSE}
