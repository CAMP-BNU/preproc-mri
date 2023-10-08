#!/usr/bin/env bash
# prepare command of fmriprep
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
: ${FMRIPREP_CONTAINER:=/opt/fmritools/containers/fmriprep-v23.1.4.sif}
: ${FMRIPREP_CMD:=${SINGULARITY_CMD} run -c -e -B /seastor:/seastor -B /home/zhangliang:/home/zhangliang ${FMRIPREP_CONTAINER}}
# positional parameters
: ${INPUT_DIR:=${PROJECT_ROOT}/rawdata}
: ${OUTPUT_DIR:=${PROJECT_ROOT}/derivatives/fmriprep}
: ${BIDS_DATABASE_DIR:=${PROJECT_ROOT}/bids_db}
: ${WORK_DIR:=${PROJECT_ROOT}/tmp}
# output spaces
: ${OUTPUT_SPACES:=MNI152NLin2009cAsym MNI152NLin6Asym:res-2 anat fsaverage fsaverage6}
# freesurfer
: ${FS_LICENSE:=/seastor/zhangliang/license.txt}
: ${FS_SUBJECTS_DIR:=${OUTPUT_DIR}/sourcedata/freesurfer}
# performance related
: ${NTHREADS:=8}
: ${OMPTHREADS:=4}
: ${MEMMB:=61400} # 60GiB

export SINGULARITYENV_TEMPLATEFLOW_HOME=/home/zhangliang/.cache/templateflow/

${FMRIPREP_CMD} \
    ${INPUT_DIR} ${OUTPUT_DIR} participant \
    `# filtering bids queries` \
    --skip_bids_validation \
    --participant_label ${SUBJECT} \
    --bids-database-dir ${BIDS_DATABASE_DIR} \
    `# performance options` \
    --nthreads ${NTHREADS} \
    --omp-nthreads ${OMPTHREADS} \
    --mem_mb ${MEMMB} \
    --output-spaces ${OUTPUT_SPACES} \
    `# other options` \
    -w ${WORK_DIR} \
    --stop-on-first-crash --notrack \
    `# freesurfere options` \
    --fs-license-file ${FS_LICENSE} \
    --fs-subjects-dir ${FS_SUBJECTS_DIR}
