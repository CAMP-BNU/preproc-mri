#!/usr/bin/env bash
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
# set default MRIQC_CONTAINER
: ${MRIQC_CONTAINER:=/opt/fmritools/containers/mriqc-v23.1.0.sif}
# note $HOME is used for cached templateflow
: ${MARQC_CMD:=${SINGULARITY_CMD} run -c -e -B /seastor:/seastor -B /home/zhangliang:/home/zhangliang ${MRIQC_CONTAINER}}
# positional parameters
: ${INPUT_DIR:=${PROJECT_ROOT}/rawdata}
: ${OUTPUT_DIR:=${PROJECT_ROOT}/derivatives/mriqc}
: ${BIDS_DATABASE_DIR:=${PROJECT_ROOT}/bids_db}
: ${WORK_DIR:=${PROJECT_ROOT}/tmp}
# performance related
: ${NTHREADS:=8}
: ${OMPTHREADS:=4}
: ${MEMMB:=12288} # 12GiB

${MARQC_CMD} \
    ${INPUT_DIR} ${OUTPUT_DIR} participant \
    `# filtering subject` \
    --participant_label ${SUBJECT} \
    --session-id ${SESSION} \
    --bids-database-dir ${BIDS_DATABASE_DIR} \
    `# instrumental options` \
    --work-dir ${PROJECT_ROOT}/tmp \
    --write-graph --verbose-reports --no-sub \
    `# performance related` \
    --nthreads $NTHREADS \
    --omp-nthreads $OMPTHREADS \
    --mem_mb $MEMMB \
    --float32 \
    `# workflow config` \
    --ica --fft-spikes-detector --fd_thres 0.3
