# Rodent DTI Connectomics

Shellscripts for DTI connectomics generation from rodent data. 
* mouse_singleShell_dtiConnectomics
* mouse_multiShell_dtiConnectomics
* rat_singleShell_dtiConnectomics
* rat_multiShell_dtiConnectomics

## Prerequisites
You need to have these programmed installed.
* [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
* [ANTs](https://github.com/ANTsX/ANTs)
* [MRtrix](https://www.mrtrix.org/)

## Instructions
### Folder Structure
```
.
├── dat                   # each subdirectory contains a dataset
│   ├── dataset1
│   ├── dataset2
│   └── ...
└── shellscripts          # download and save the shellscripts here
```

### List of Input Files
For Preprocessing step
- grad.txt (grad_xx.txt; diffusion-weighted gradient scheme in MRtrix format)
- dwi.nii (dwi_xx.nii)
- rc_mt2.nii / rc_t2.nii (SPM biasfield-corrected/uncorrected t2 coregistered to dwi)
- rc_ix_AVGTmask.nii (mask image)
- c_t2.nii
requires preprocessing in ANTx2 toolbox https://github.com/ChariteExpMri/antx2

For Connectome generation
- ANO_DTI.nii (atlas)
- ANO_DTI.txt (6 columns: ID, LabelName, R, G, B, A)
- atlas_lut.txt (identical to ANO_DTI.txt, but make sure ID is sequential with no gaps)

### Usage
In terminal, go to the `dat` directory. Run the 'complete' file in the shellscripts folder. E.g.
```
cd /path/to/directory/dat
./../shellscripts/mouse_dti_complete_7texpmri.sh
```
