#! /bin/bash

subjects=$( cat subjects )
cmd=mri_concat
for subject in ${subjects[@]}; do
  file=$( find ../contrasts -name "*${subject}_active_minus_sham_mni152_sm08.nii.gz" )

  cmd+=" --i $file"
done
cmd+=" --o ../group_pet/Y.nii.gz"
$cmd

mri_glmfit --y ../group_pet/Y.nii.gz \
 --osgm  \
 --glmdir ../group_pet/active_vs_sham \
 --nii.gz \
 --save-eres
