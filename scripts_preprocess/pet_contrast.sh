#! /bin/bash

parentdir=$( dirname $PWD)
outputfolder=$parentdir/contrasts/

while read line; do
  array=( $line );

  subject=${array[0]}
  sham_ses=ses-${array[1]}
  sham_derivatives=/home/lauri/Documents/TMS-FDG/derivatives/iter6s${array[1]: -1} 

  active_ses=ses-${array[2]}
  active_derivatives=/home/lauri/Documents/TMS-FDG/derivatives/iter6s${array[2]: -1}

  sham_pet=${sham_derivatives}/sub-${subject}/$sham_ses/pet/SUVR.mni152.2mm.sm00.nii.gz
  active_pet=${active_derivatives}/sub-${subject}/$active_ses/pet/SUVR.mni152.2mm.sm00.nii.gz
  
  
  fslmaths $active_pet -sub $sham_pet ${outputfolder}/${subject}_active_minus_sham_mni152_sm00.nii.gz
  fslmaths ${outputfolder}/${subject}_active_minus_sham_mni152_sm00.nii.gz -div $sham_pet -mul 100 ${outputfolder}/${subject}_active_minus_sham_mni152_sm00_perc_diff.nii.gz
  
  # also do surface 
  for h in lh, rh; do 
    active_surf=${active_derivatives}/sub-${subject}/$active_ses/pet/${h}.SUVR.fsaverage.sm00.nii.gz
    sham_surf=${sham_derivatives}/sub-${subject}/$sham_ses/pet/${h}.SUVR.fsaverage.sm00.nii.gz
    fscalc $active_surf sub $sham_surf --output ${outputfolder}/${h}_${subject}_active_minus_sham_fsaverage_sm00.nii.gz

  done 

done < <(tail -n +2 ../info/unmask.txt)
