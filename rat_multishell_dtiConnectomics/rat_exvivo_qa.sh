#!/bin/bash
# Generate screenshots for quality assessment
for_each * : mrview IN/mrtrix/c_t2_up_unbias_masked.mif -overlay.load IN/mrtrix/voxels.mif  -quiet -mode 2 -plane 1 -voxel 150,80,150 -noannot -overlay.load IN/mrtrix/voxels.mif -capture.prefix IN/mrtrix/capture_voxels -capture.grab -exit

for_each * : mrview IN/mrtrix/c_t2_up_unbias_masked.mif -odf.load_sh IN/mrtrix/wm.mif -mode 2 -plane 1 -voxel 150,80,150 -noannot -capture.prefix IN/mrtrix/capture_fod -capture.grab -exit

for_each * : mrview IN/mrtrix/c_t2_up_unbias_masked.mif -tractography.load IN/mrtrix/100k.tck -tractography.lighting 1 -tractography.thickness 0.2 -mode 2 -plane 1 -voxel 150,80,150 -noannot -capture.prefix IN/mrtrix/capture_tck -capture.grab -exit

# Display end time
echo "end:"
date