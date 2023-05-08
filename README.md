# Pre-processing MRI data

This repository contains the code for pre-processing MRI data. The codes are highly customized for the data we have. However, the codes can be used as a reference for pre-processing MRI data.

## Requirements

R and python are required to run the codes. The following R packages are required:

- tidyverse: data manipulation
- argparser: command line argument parser
- box: auto-detect script location

As for python, no additional packages are required. But we utilize a lot of containers including heudiconv, mriqc and fmriprep. Please refer to the [BIDS documentation](https://bids.neuroimaging.io/) for more information.

## Usage

Pre-processing is done with the following steps:

1. Convert DICOM files to BIDS format: `./preprocess/perform_heudiconv.R`
2. Run MRIQC: `./preprocess/perform_mriqc.R`
3. Run pre-processing for functional data (i.e., fmriprep): `./preprocess/perform_fmriprep.R`

### `perform_heudiconv.R`

This script converts DICOM files to BIDS format. The script is highly customized for the data we have. The script is designed to be run on a cluster. Run `./preprocess/perform_heudiconv.R -h` for more information.

### `perform_mriqc.R`

This script runs MRIQC. The script is highly customized for the data we have. The script is designed to be run on a cluster. Run `./preprocess/perform_mriqc.R -h` for more information.

### `perform_fmriprep.R`

This script runs fmriprep. The script is highly customized for the data we have. The script is designed to be run on a cluster. Run `./preprocess/perform_fmriprep.R -h` for more information.

## Notes

The repository organized into the following structure:

- Data Folders:
  - Folder `sourcedata`: contains the DICOM files
  - Folder `rawdata`: contains the BIDS format data
  - Folder `derivatives`: contains the pre-processed data
  - Folder `backup`: contains backup data which are deemed obsolete
  - Folder `tmp`: contains the temporary files generated during the pre-processing (mostly will be deleted after the pre-processing automatically)
- Code Folders:
  - Folder `R`: contains the R scripts to do the pre-processing
  - Folder `preprocess`: contains the end point script to do the pre-processing
  - Folder `template`: contains the template files (you can find the shell and python templates here) to do the pre-processing
  - Folder `logs`: contains the log files generated during the pre-processing by the cluster

## TODO
