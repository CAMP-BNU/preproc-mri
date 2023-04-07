# before heuristics
heudiconv -d sourcedata/${site}_*_CAMP_SUB{subject}_*_{session}/*/*/*.IMA \
    -o rawdata/${site} -s $subject -ss $session -f convertall -c none --overwrite

# after heuristics
fsl_sub heudiconv -d sourcedata/${site}_*_CAMP_SUB{subject}_*_{session}/*/*/*.IMA \
    -o rawdata/${site} -s $subject -ss $session -f code/heuristic.py \
    -c dcm2niix -b --overwrite
