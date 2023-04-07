import os

def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes


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
    dwi = create_key('sub-{subject}/{session}/dwi/sub-{subject}_{session}_dir-{dir}_dwi')

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
        item = {'item': s.series_id}
        if s.protocol_name.startswith('ep2d_se'):
            parts = s.protocol_name.split('_')
            item['intended'] = task_map[parts[2]]
            item['dir'] = parts[3]
            info[fmap].append(item)
        elif 'bold' in s.protocol_name:
            parts = s.protocol_name.split('_')
            if s.dim4 == int(parts[4]):
                task_run = parts[0]
                item['task'] = task_map[task_run[:2]]
                item['run'] = task_run[-1]
                item['dir'] = parts[5]
                info[bold].append(item)
        elif 't1_mprage_sag_iso' in s.protocol_name:
            info[t1w].append(item)
        elif 't2_spc_sag_iso' in s.protocol_name:
            info[t2w].append(item)
        elif s.protocol_name == 'TSE_HiResHp' and 'NORM' in s.image_type:
            info[t2w_hp].append(item)
        elif s.protocol_name == 'sms4_diff_CMR130_fastMode_PA':
            item['dir'] = 'PA'
            info[dwi].append(item)
        elif s.protocol_name == 'sms4_diff_CMR130_fastMode_B0_AP':
            item['intended'] = 'dwi'
            item['dir'] = 'AP'
            info[fmap].append(item)
    return info
