# Script reconstructs connectome, does filtering, writes connectivity matrix

# tractography
for_each * : tckgen IN/mrtrix/wm.mif IN/mrtrix/100m.tck -seed_dynamic IN/mrtrix/wm.mif -select 100M -maxlength 50 -cutoff 0.06
for_each * : tckgen IN/mrtrix/wm.mif IN/mrtrix/100k.tck -seed_dynamic IN/mrtrix/wm.mif -select 100K -maxlength 50 -cutoff 0.06

# debugging with 10000 seeds
#for_each * : tckgen IN/mrtrix/wm_norm.mif IN/mrtrix/10m.tck -seed_dynamic IN/mrtrix/wm_norm.mif -select 10000 -maxlength 50 -cutoff 0.06


# sift_2
for_each * : tcksift2 IN/mrtrix/100m.tck IN/mrtrix/wm.mif IN/mrtrix/tck_weights.txt -out_mu IN/mrtrix/SIFT2_mu.txt -out_coeffs IN/mrtrix/tck_coeffs.txt

# upscale atlas and convert to mif with ascending label ids
# atlas_lut_freesurfer - spaces replaced with _
# atlas: ANO_DTI.txt ANO_DTI.nii
for_each * : mrgrid IN/ANO_DTI.nii regrid -vox 0.1 -interp nearest IN/mrtrix/ANO_DTI_up.mif 
for_each * : labelconvert IN/mrtrix/ANO_DTI_up.mif IN/ANO_DTI.txt IN/atlas_lut.txt IN/mrtrix/atlas.mif

# inpect AAL brain pacellations
#mrview ../t1.nii.gz -plane 2 \ -overlay.load parc_aal.mif -overlay.opacity 0.2 -overlay.colourmap 3 -overlay.interpolation 0 &
#head -n 50 aal.txt

# connectome edge: weighted SIFT2 tractogram
for_each * : tck2connectome IN/mrtrix/100m.tck IN/mrtrix/atlas.mif IN/mrtrix/connectome_di_sy.csv -tck_weights_in IN/mrtrix/tck_weights.txt -out_assignments IN/mrtrix/assignments_di_sy.txt -zero_diagonal -symmetric

# generate exemplar streamlines for edges visualisation
for_each * : connectome2tck IN/mrtrix/100m.tck IN/mrtrix/assignments_di_sy.txt IN/mrtrix/exemplars.tck -tck_weights_in IN/mrtrix/tck_weights.txt -exemplars IN/mrtrix/atlas.mif -files single

# generate a smooth surface representation of each parcellation
for_each * : label2mesh IN/mrtrix/atlas.mif IN/mrtrix/mesh.obj;
for_each * : meshfilter IN/mrtrix/mesh.obj smooth IN/mrtrix/smoothed_atlas.obj
