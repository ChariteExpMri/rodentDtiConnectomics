#!/bin/bash
# tensor metrics, run preprocessing script first!

# Generate diffusion tensor and kurtosis tensor after removal of negative values
for_each * : mrthreshold -abs 0 IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias.mif IN/mrtrix/maskpreunbiaspos.mif
for_each * : mrcalc IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias.mif IN/mrtrix/maskpreunbiaspos.mif -multiply IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_pos.mif

for_each * : dwi2tensor -mask IN/mrtrix/maskantx.mif IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_pos.mif IN/mrtrix/dt.mif

# Calculate diffusion tensor metrics
for_each * : tensor2metric -mask IN/mrtrix/maskantx.mif -adc IN/mrtrix/adc.mif -fa IN/mrtrix/fa.mif -ad IN/mrtrix/ad.mif -rd IN/mrtrix/rd.mif IN/mrtrix/dt.mif

# Convert to NIFTI format
for_each * : mrconvert IN/mrtrix/adc.mif IN/adc.nii
for_each * : mrconvert IN/mrtrix/fa.mif IN/fa.nii
for_each * : mrconvert IN/mrtrix/ad.mif IN/ad.nii
for_each * : mrconvert IN/mrtrix/rd.mif IN/rd.nii

