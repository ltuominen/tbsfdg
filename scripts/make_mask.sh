#! /bin/bash
target=$1

targ_dir=$(dirname $target)
temp=${targ_dir}/temp
mkdir ${temp}

mri_convert $target ${temp}/aparc+aseg.nii.gz

fslmaths ${temp}/aparc+aseg.nii.gz -thr 24 -uthr 24 -bin ${temp}/CSF_mask.nii.gz

remove=(4 5 14 15 43 44 72 73)
for r in ${remove[@]};do
  fslmaths $target -thr $r -uthr $r -bin ${temp}/${r}.nii.gz
  fslmaths ${temp}/CSF_mask.nii.gz -add ${temp}/${r}.nii.gz -bin ${temp}/CSF_mask.nii.gz
done

fslmaths ${temp}/aparc+aseg.nii.gz -bin ${temp}/aparc+aseg_bin.nii.gz
fslmaths ${temp}/aparc+aseg_bin.nii.gz -sub ${temp}/CSF_mask.nii.gz ${temp}/wmgm_mask.nii.gz

cp ${temp}/CSF_mask.nii.gz $targ_dir
cp ${temp}/wmgm_mask.nii.gz $targ_dir

rm -r ${temp}
