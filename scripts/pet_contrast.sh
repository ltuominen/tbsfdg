#! /bin/bash

outputfolder=/group/tuominen/TBS-FDG/group_pet/
derivates=/group/tuominen/TBS-FDG/derivatives/iter5/

while read line; do
  array=( $line );

  subject=${array[0]}
  sham_ses=ses-${array[1]}
  active_ses=ses-${array[1]}

  sham_pet=${derivates}/sub-${subject}/$sham_ses/pet/SUVR.mni152.2mm.sm08.nii.gz
  active_pet=${derivates}/sub-${subject}/$active_ses/pet/SUVR.mni152.2mm.sm08.nii.gz
  fslmaths $active_pet -sub $sham_pet $outputfolder/${subject}_active_minus_sham.nii.gz
  fslmaths $outputfolder/${subject}_active_minus_sham.nii.gz -div $sham_pet -mul 100 $outputfolder/${subject}_active_minus_sham_perc_diff.nii.gz

done < <(tail -n +2 unmask.txt)