#!/bin/bash
# preprocess

# Display start time
echo "start:"
date

#if you have multishell:
#mrcat b1000_AP/ b2000_AP/ b3000_AP/ dwi.mif
for_each * : mkdir IN/mrtrix

# For a standard Bruker DTI scan, bx and by directions as stored in the method file are opposing the mrtrix x and y directions, so bx and by need a flip (minus sign)
for_each * : mrconvert -grad IN/grad_b100.txt IN/dwi_b100.nii IN/mrtrix/dwi_b100.mif
for_each * : mrconvert -grad IN/grad_b1600.txt IN/dwi_b1600.nii IN/mrtrix/dwi_b1600.mif
for_each * : mrconvert -grad IN/grad_b3400.txt IN/dwi_b3400.nii IN/mrtrix/dwi_b3400.mif
for_each * : mrconvert -grad IN/grad_b6000.txt IN/dwi_b6000.nii IN/mrtrix/dwi_b6000.mif
for_each * : mrcat IN/mrtrix/dwi_b100.mif IN/mrtrix/dwi_b1600.mif IN/mrtrix/dwi_b3400.mif IN/mrtrix/dwi_b6000.mif IN/mrtrix/dwi.mif

# Get voxel dimensions for scaling later on

# Denoising
for_each * : dwidenoise IN/mrtrix/dwi.mif IN/mrtrix/dwi_den.mif -noise IN/mrtrix/noise.mif
#for_each * : dwidenoise IN/mrtrix/dwi.mif IN/5_dwi/dwi_den.mif -noise IN/5_dwi/noise.mif
for_each * : mrcalc IN/mrtrix/dwi.mif IN/mrtrix/dwi_den.mif -subtract IN/mrtrix/residual.mif
#you could check if the noise.mif is good, I recommend to do it. If you could see a brain in this file,dude, then you meet a problem.
#Unringing
#The “axes” option must be adjusted to your dataset: With this option, you inform the algorithm of the plane in which you acquired your data: –axes 0,1 means you acquired axial slices; -axes 0,2 refers to coronal slices and –axes 1,2 to sagittal slices!
#but basically, I'd never seen sagittal and coronal
for_each * : mrdegibbs IN/mrtrix/dwi_den.mif IN/mrtrix/dwi_den_unr.mif -axes 0,1
#Motion and distortion correction
#Reason: Main reference(s):
#EPI-distortioncorrection:Hollandetal.,2010(suggestusingapairofb0sin in phase encoding (PE) and reversed PE correction)
#B0-field inhomogeneity correction: Andersson et al., 2003; Smith et al., 2004 (FSL’s topup tool is called by MRtrix’s preprocessing tool dwipreproc)
#Eddy-current and movement distortion correction: Andersson and Sotiropoulos, 2016 (FSL’s eddy tool is called by MRtrix’s preprocessing tool dwipreproc)
#For EPI distortion correction

#dwiextract dwi_den_unr.mif - -bzero | mrmath – mean mean_b0_AP.mif –axis 3
#“-axis 3”denotesthatthemeanimagewillbecalculatedalongthethirdaxis
#mrconvert b0_PA/ - | mrmath – mean mean_b0_PA.mif –axis 3
#mrcat mean_b0_AP.mif mean_b0_PA.mif –axis 3 b0_pair.mif
#if no b0_PA/, don't need to do these steps

# =get VOXEL-size & inflate by factor 10 =========================
cd $(ls -d */|head -n 1)
dim1=$(fslinfo dwi_b100.nii | grep -m 1 pixdim1 | awk '{print $2}');
dim2=$(fslinfo dwi_b100.nii | grep -m 1 pixdim2 | awk '{print $2}');
dim3=$(fslinfo dwi_b100.nii | grep -m 1 pixdim3 | awk '{print $2}');
echo '['$dim1','$dim2','$dim3']'
cd ..

fac=10
echo blow up voxelsize by factor: $fac

dim1fac=$(echo $dim1*$fac | bc)
dim2fac=$(echo $dim2*$fac | bc) 
dim3fac=$(echo $dim3*$fac | bc)
echo '['$dim1fac','$dim2fac','$dim3fac']'

#motion and distortion correction, scale to human length scales for FSL commands and then back to original length scales
for_each * : mrconvert -vox $dim1fac,$dim2fac,$dim3fac IN/mrtrix/dwi_den_unr.mif IN/mrtrix/dwi_den_unr_vox.mif
### test whether no -eddy_options gives an error message
for_each * : dwifslpreproc IN/mrtrix/dwi_den_unr_vox.mif IN/mrtrix/dwi_den_unr_pre_vox.mif -rpe_none -pe_dir AP -eddy_options " --slm=linear --data_is_shelled"
###
for_each * : mrconvert -vox $dim1,$dim2,$dim3 IN/mrtrix/dwi_den_unr_pre_vox.mif IN/mrtrix/dwi_den_unr_pre.mif

# =========================
#if [ 1 -eq 0 ]; then
# =========================

# remove negative values from dwi dataset since this leads to problems in ants N4 bias field correction
for_each * : mrthreshold -abs 0 IN/mrtrix/dwi_den_unr_pre.mif IN/mrtrix/maskprepos.mif
for_each * : mrcalc IN/mrtrix/dwi_den_unr_pre.mif IN/mrtrix/maskprepos.mif -multiply IN/mrtrix/dwi_den_unr_pre_pos.mif

# Convert to nii for processing in ANTX2
# foreach * : mrconvert IN/mrtrix/dwi_den_unr_pre_pos.mif IN/dwi_den_unr_pre_pos.nii

#if you do the b0 step, then use the following command:
#dwipreproc dwi_den_unr.mif dwi_den_unr_preproc.mif –pe_dir AP –rpe_pair –se_epi b0_pair.mif –eddy_options “ --slm=linear”
#Calculate the number of outlier slices
#cd dwipreproc-tmp-*
#totalSlices=`mrinfo dwi.mif | grep Dimensions | awk '{print $6 * $8}'`
#totalOutliers=`awk '{ for(i=1;i<=NF;i++)sum+=$i } END { print sum }' dwi_post_eddy.eddy_outlier_map`
#echo "If the following number is greater than 10, you may have to discard this subject because of too much motion or corrupted slices"
#echo "scale=5; ($totalOutliers / $totalSlices * 100)/1" |bc | tee percentageOutliers.txt
#cd ..

#Bias field correction

# Use rc_mt2.nii/rc_t2.nii which are the SPM biasfield-corrected/uncorrected t2 coregistered to dwi, requires preprocessing in ANTx2 toolbox https://github.com/ChariteExpMri/antx2
for_each * : mrconvert IN/rc_mt2.nii IN/mrtrix/rc_mt2corruptheader.mif
for_each * : mrtransform IN/mrtrix/rc_mt2corruptheader.mif -replace IN/mrtrix/dwi_den_unr_pre.mif IN/mrtrix/rc_mt2.mif
for_each * : mrconvert IN/rc_t2.nii IN/mrtrix/rc_t2corruptheader.mif
for_each * : mrtransform IN/mrtrix/rc_t2corruptheader.mif -replace IN/mrtrix/dwi_den_unr_pre.mif IN/mrtrix/rc_t2.mif
for_each * : mrcalc IN/mrtrix/rc_mt2.mif IN/mrtrix/rc_t2.mif -divide IN/mrtrix/biasantx.mif
# do the bias field correction using the antx t2 biasfield
for_each * : mrcalc IN/mrtrix/dwi_den_unr_pre_pos.mif IN/mrtrix/biasantx.mif -multiply IN/mrtrix/dwi_den_unr_pre_pos_unbiasantxcorruptheader.mif
for_each * : mrtransform IN/mrtrix/dwi_den_unr_pre_pos_unbiasantxcorruptheader.mif -replace IN/mrtrix/dwi_den_unr_pre.mif IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx.mif

# generate brain mask output from antx2 in mif format and fix header
for_each * : mrconvert IN/rc_ix_AVGTmask.nii IN/mrtrix/maskantxcorruptheader.mif
for_each * : mrtransform IN/mrtrix/maskantxcorruptheader.mif -replace IN/mrtrix/dwi_den_unr_pre.mif IN/mrtrix/maskantx.mif

# Ants biasfieldcorrection. Use ants.b parameter to compensate differences in brain size from human (standard is -ants.b [100,3]) to mouse
for_each * : dwibiascorrect ants -ants.b "[10,3]" -mask IN/mrtrix/maskantx.mif IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx.mif IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias.mif -bias IN/mrtrix/bias.mif

# Generate overall biasfield
for_each * : mrcalc IN/mrtrix/bias.mif IN/mrtrix/biasantx.mif -divide IN/mrtrix/biasoverall.mif
#you can check bias.mif if you want

#resize voxel:
for_each * : mrgrid IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias.mif regrid -vox 0.1 IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up.mif
for_each * : mrgrid IN/mrtrix/maskantx.mif regrid -vox 0.1 -interp nearest IN/mrtrix/maskantx_up.mif
for_each * : mrfilter IN/mrtrix/maskantx_up.mif smooth IN/mrtrix/maskantx_up_smooth.mif
for_each * : mrthreshold IN/mrtrix/maskantx_up_smooth.mif IN/mrtrix/maskantx_up_smooth_thresh.mif
for_each * : maskfilter -npass 2 IN/mrtrix/maskantx_up_smooth_thresh.mif erode IN/mrtrix/maskantx_up_smooth_thresh_erode.mif

# remove negative values
for_each * : mrthreshold -abs 0 IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up.mif IN/mrtrix/maskpreunbiasuppos.mif
for_each * : mrcalc IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up.mif IN/mrtrix/maskpreunbiasuppos.mif -multiply IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up_pos.mif

#Fiber orientation distribution
for_each * : dwi2response dhollander IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up_pos.mif IN/mrtrix/wm.txt IN/mrtrix/gm.txt IN/mrtrix/csf.txt -voxels IN/mrtrix/voxels.mif -mask IN/mrtrix/maskantx_up_smooth_thresh_erode.mif
#for_each * : dwi2response dhollander IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up.mif IN/mrtrix/x_wm.txt IN/mrtrix/x_gm.txt IN/mrtrix/x_csf.txt -voxels IN/mrtrix/x_voxels.mif
for_each * : dwi2fod msmt_csd IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up_pos.mif IN/mrtrix/csf.txt IN/mrtrix/csf.mif IN/mrtrix/gm.txt IN/mrtrix/gm.mif IN/mrtrix/wm.txt IN/mrtrix/wm.mif -mask IN/mrtrix/maskantx_up_smooth_thresh_erode.mif
#foreach * : dwi2fod msmt_csd IN/mrtrix/dwi_den_unr_pre_pos_unbiasantx_unbias_up.mif IN/mrtrix/csf.txt IN/mrtrix/csf.mif IN/mrtrix/gm.txt IN/mrtrix/gm.mif IN/mrtrix/wm.txt IN/mrtrix/wm.mif -mask IN/mrtrix/maskantx_up.mif
for_each * : mrconvert -coord 3 0 IN/mrtrix/wm.mif - \| mrcat IN/mrtrix/csf.mif IN/mrtrix/gm.mif - IN/mrtrix/rgb.mif


#remove remaining intensity variations
#for_each * : mtnormalise IN/mrtrix/csf.mif IN/mrtrix/csf_norm.mif IN/mrtrix/wm.mif IN/mrtrix/wm_norm.mif IN/mrtrix/gm.mif IN/mrtrix/gm_norm.mif -mask IN/mrtrix/maskantx_up.mif

# Generate c_t2.mif for illustration purposes, make sure that c_t2 exists and is correct (moving image, not target image when cofiguring coreg in antx2)
for_each * : mrconvert IN/c_t2.nii IN/mrtrix/c_t2corruptheader.mif
for_each * : mrtransform IN/mrtrix/c_t2corruptheader.mif -replace IN/mrtrix/dwi_den_unr_pre.mif IN/mrtrix/c_t2.mif
for_each * : mrgrid IN/mrtrix/c_t2.mif regrid -vox 0.1 IN/mrtrix/c_t2_up.mif
for_each * : mrgrid IN/mrtrix/biasantx.mif regrid -vox 0.1 -interp nearest IN/mrtrix/biasantx_up.mif
for_each * : mrcalc IN/mrtrix/c_t2_up.mif IN/mrtrix/biasantx_up.mif -multiply IN/mrtrix/c_t2_up_unbias.mif
for_each * : mrcalc IN/mrtrix/c_t2_up.mif IN/mrtrix/maskantx_up_smooth_thresh_erode.mif -multiply IN/mrtrix/c_t2_up_unbias_masked.mif

# To dos
#Generate atlas and eroded brain mask excluding csf.
# 

# =========================
#fi
# =========================
