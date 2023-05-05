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

1. Convert DICOM files to BIDS format: `./perform_heudiconv.R`
2. Run MRIQC: `./perform_mriqc.R`

### `perform_heudiconv.R`

This script converts DICOM files to BIDS format. The script is highly customized for the data we have. The script is designed to be run on a cluster. Run `./perform_heudiconv.R -h` for more information.

### `perform_mriqc.R`

This script runs MRIQC. The script is highly customized for the data we have. The script is designed to be run on a cluster. Run `./perform_mriqc.R -h` for more information.

## Notes

The repository organized into the following structure:

- Folder `sourcedata`: contains the DICOM files
- Folder `rawdata`: contains the BIDS format data
- Folder `derivatives`: contains the pre-processed data
- Folder `template`: contains the template files (you can find the shell and python templates here) to do the pre-processing
- Folder `tmp`: contains the temporary files generated during the pre-processing (mostly will be deleted after the pre-processing automatically)
- Folder `R`: contains the R scripts to do the pre-processing
- Folder `logs`: contains the log files generated during the pre-processing by the cluster

## TODO

Add fmriprep step.
