#!/usr/bin/env bash
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
: ${FMRIPREP_CONTAINER:=/opt/fmritools/containers/fmriprep-23.0.2.sif}
: ${FMRIPREP_CMD:=${SINGULARITY_CMD} run -c -e -B /seastor:/seastor -B /home/zhangliang:/home/zhangliang ${FMRIPREP_CONTAINER}}
: ${FS_LICENSE:=/seastor/zhangliang/license.txt}
: ${N_THREADS:=2}

${FMRIPREP_CMD} \
    ${PROJECT_ROOT}/rawdata ${PROJECT_ROOT}/derivatives/fmriprep participant \
    `# filtering bids queries` \
    --skip_bids_validation \
    --participant_label ${SUBJECT} \
    `# performance options` \
    --nthreads ${N_THREADS} --mem_mb 12000 \
    --output-spaces MNI152NLin2009cAsym anat \
    `# other options` \
    -w ${PROJECT_ROOT}/tmp/fmriprep \
    --stop-on-first-crash --notrack \
    `# freesurfere license` \
    --fs-license-file ${FS_LICENSE}
