# Pre-processing MRI data

This repository contains the code for pre-processing MRI data. The codes are highly customized for the data we have. However, the codes can be used as a reference for pre-processing MRI data.

## Requirements

R and python are required to run the codes. Additionally, we utilize a lot of containers including heudiconv, mriqc and fmriprep. Please refer to the [BIDS documentation](https://bids.neuroimaging.io/) for more information.

## Usage

Pre-processing is done with the following steps:

1. Convert DICOM files to BIDS format: `./preprocess/perform_heudiconv.R`. Run `./preprocess/perform_heudiconv.R -h` for more information.
2. Run MRIQC: `./preprocess/perform_mriqc.R`. Run `./preprocess/perform_mriqc.R -h` for more information.
3. Run pre-processing for functional data (i.e., fmriprep): `./preprocess/perform_fmriprep.R`. Run `./preprocess/perform_fmriprep.R -h` for more information.

## Notes

The repository is organized into the following structure:

- Data Folders:
  - Folder `sourcedata`: contains the DICOM files.
  - Folder `rawdata`: contains the BIDS format data.
  - Folder `bids_db`: contains the database of BIDS Layout. This is used to speed up the pre-processing.
  - Folder `derivatives`: contains the pre-processed data.
  - Folder `backup`: contains backup data which are deemed obsolete.
  - Folder `tmp`: contains the temporary files generated during the pre-processing (mostly will be deleted after the pre-processing automatically).
  - Folder `logs`: contains the log files generated during the pre-processing by the cluster.
- Code Folders:
  - Folder `R`: contains the R scripts to do the pre-processing.
  - Folder `preprocess`: contains the end point script to do the pre-processing.
  - Folder `template`: contains the template files (you can find the shell and python templates here) to do the pre-processing.

### fMRIprep

For storage considerations, we specified the outspaces as:

- `MNI152NLin6Asym`: we do not include `MNI152NLin2009cAsym`.
- `anat`: T1 weighted non-standard space.
- `fsaverage6`: freesurfer's surface based space.
- `fsLR`: aka CIFTI output.

## TODO

ICA-AROMA was removed from fmriprep since 23.1.0, and a custom ICA-AROMA workflow is required.
