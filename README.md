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

### Usage
In terminal, go to the `dat` directory. Run the 'complete' file in the shellscripts folder. E.g.
```
cd /path/to/directory/dat
./../shellscripts/mouse_dti_complete_7texpmri.sh
```
