#!/usr/bin/env bash
: ${SINGULARITY_CMD:=/opt/fmritools/singularity/bin/singularity}
# set default MRIQC_CONTAINER
: ${MRIQC_CONTAINER:=/opt/fmritools/containers/mriqc-23.1.0rc0.sif}
# note $HOME is used for cached templateflow
: ${MARQC_CMD:=${SINGULARITY_CMD} exec -c -e -B /seastor:/seastor -B /home/zhangliang:/home/zhangliang ${MRIQC_CONTAINER} mriqc}
: ${N_THREADS:=4}
fsl_sub -l ${PROJECT_ROOT}/logs \
    -N mriqc_sub-${SUBJECT}_ses-${SESSION} \
    ${MARQC_CMD} \
    ${PROJECT_ROOT}/rawdata ${PROJECT_ROOT}/derivatives/mriqc participant \
    `# filtering subject` \
    --participant_label ${SUBJECT} \
    --session-id ${SESSION} \
    `# instrumental options` \
    -w ${PROJECT_ROOT}/tmp/mriqc \
    --write-graph --verbose-reports --no-sub \
    `# performance related` \
    --n_procs $N_THREADS --mem_gb 4000 --ants-nthreads $N_THREADS \
    `# workflow config` \
    --ica --fft-spikes-detector --fd_thres 0.3
