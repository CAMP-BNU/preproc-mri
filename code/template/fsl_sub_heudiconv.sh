fsl_sub -l logs \
    -N heudiconv_site-${SITE}_sub-${SUBJECT}_ses-${SESSION} \
    heudiconv -d ${PROJECT_ROOT}/sourcedata/${SITE}_*_CAMP_SUB{subject}_*_{session}/*/*/*.IMA \
    -o ${PROJECT_ROOT}/rawdata/${SITE} -s $SUBJECT -ss $SESSION \
    -f ${PROJECT_ROOT}/code/heuristic.py \
    -c dcm2niix -b --overwrite
