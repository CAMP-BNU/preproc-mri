import os

# Dictionary to specify options for the `populate_intended_for`.
# Valid options are defined in 'bids.py' (for 'matching_parameters':
# ['Shims', 'ImagingVolume',]; for 'criterion': ['First', 'Closest']
POPULATE_INTENDED_FOR_OPTS = {
    "matching_parameters": "CustomAcquisitionLabel",
    "criterion": "Closest",
}

def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes

def find_item(info, item):
    # do not check "item" field itself
    item_clean = {k: v for k, v in item.items() if k != 'item'}
    for i in range(len(info)):
        if all(info[i][k] == v for k, v in item_clean.items()):
            return i
    return None

def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    # functional images
    fmap = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-{intended}_dir-{dir}_epi')
    bold = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-{task}_dir-{dir}_run-{run}_bold')

    # structural images
    t1w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_T1w')
    t2w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_T2w')
    t2w_hp = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-HiResHp_T2w')

    # diffusion images
    dwi = create_key('sub-{subject}/{session}/dwi/sub-{subject}_{session}_acq-dwi_dir-{dir}_dwi')

    info = {
        fmap: [],
        bold: [],
        t1w: [],
        t2w: [],
        t2w_hp: [],
        dwi: []
    }
    task_map = {'RS': 'rest', 'AM': 'am', 'WM': 'wm', 'MV': 'movie'}

    for s in seqinfo:
        """
        The namedtuple `s` contains the following fields:

        * total_files_till_now
        * example_dcm_file
        * series_id
        * dcm_dir_name
        * unspecified2
        * unspecified3
        * dim1
        * dim2
        * dim3
        * dim4
        * TR
        * TE
        * protocol_name
        * is_motion_corrected
        * is_derived
        * patient_id
        * study_description
        * referring_physician_name
        * series_description
        * image_type
        """
        key = None
        item = {'item': s.series_id}
        if s.protocol_name.startswith('ep2d_se'):
            parts = s.protocol_name.split('_')
            item['intended'] = task_map[parts[2]]
            item['dir'] = parts[3]
            key = fmap
        elif 'bold' in s.protocol_name:
            parts = s.protocol_name.split('_')
            if s.dim4 == int(parts[4]):
                task_run = parts[0]
                item['task'] = task_map[task_run[:2]]
                item['run'] = task_run[-1]
                item['dir'] = parts[5]
                key = bold
        elif 't1_mprage_sag_iso' in s.protocol_name:
            key = t1w
        elif 't2_spc_sag_iso' in s.protocol_name:
            key = t2w
        elif s.protocol_name == 'TSE_HiResHp' and 'NORM' in s.image_type:
            key = t2w_hp
        elif s.protocol_name == 'sms4_diff_CMR130_fastMode_PA':
            if s.dim4 == 130:
                item['dir'] = 'PA'
                key = dwi
        elif s.protocol_name == 'sms4_diff_CMR130_fastMode_B0_AP':
            item['intended'] = 'dwi'
            item['dir'] = 'AP'
            key = fmap
        # when found duplicate scans, then keep the last
        if key is not None:
            idx = find_item(info[key], item)
            if idx is not None:
                info[key].pop(idx)
            info[key].append(item)
    return info
