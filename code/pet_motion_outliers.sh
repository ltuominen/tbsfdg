#! /bin/bash

subjects=$( cat subjects )
derivates=/group/tuominen/TBS-FDG/derivatives/iter6/

for subject in ${subjects[@]}; do
  for ses in ses-002 ses-003; do
    petdir=${derivates}/sub-${subject}/${ses}/pet/
    petfile=${petdir}/sub-${subject}-${ses}_pet.nii.gz
    outfile=${petdir}/fd_motion
    fsl_motion_outliers -i $petfile --fd -s $outfile.metrics -o $outfile.confounds &
  done
done
