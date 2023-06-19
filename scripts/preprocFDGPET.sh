#! /bin/bash

## preproc FDG PET data

make_mask() {
  target=$1

  targ_dir=$(dirname $target)
  temp=${targ_dir}/temp
  mkdir ${temp}

  mri_convert $target ${temp}/aparc+aseg.nii.gz

  fslmaths ${temp}/aparc+aseg.nii.gz -thr 24 -uthr 24 -bin ${temp}/CSF_mask.nii.gz

  add=(4 5 14 15 43 44 72 73)
  for r in ${add[@]};do
    fslmaths $target -thr $r -uthr $r -bin ${temp}/${r}.nii.gz
    fslmaths ${temp}/CSF_mask.nii.gz -add ${temp}/${r}.nii.gz -bin ${temp}/CSF_mask.nii.gz
  done

  fslmaths ${temp}/aparc+aseg.nii.gz -bin ${temp}/aparc+aseg_bin.nii.gz
  fslmaths ${temp}/aparc+aseg_bin.nii.gz -sub ${temp}/CSF_mask.nii.gz ${temp}/wmgm_mask.nii.gz

  cp ${temp}/CSF_mask.nii.gz $targ_dir
  cp ${temp}/wmgm_mask.nii.gz $targ_dir

  rm -r ${temp}

}

preproc() {
  input=$1 # path to raw pet scan (pet.nii)
  subject=$2 # subject name as in SUBJECTS_DIR
  iter=$3 # path to iter folder in the derivates folder

  # get session name etc
  pet=$( basename $input )
  spl_pet=(${pet//_/ })
  pn=(${spl_pet[0]//-/ })

  # create folders if missing
  if [ ! -d  ${derivates}/${iter} ]; then mkdir ${derivates}/${iter}; fi
  if [ ! -d ${derivates}/${iter}/sub-${pn[1]}${pn[2]} ]; then mkdir ${derivates}/${iter}/sub-${pn[1]}${pn[2]}; fi
  if [ ! -d ${derivates}/${iter}/sub-${pn[1]}${pn[2]}/ses-${pn[4]} ]; then mkdir ${derivates}/${iter}/sub-${pn[1]}${pn[2]}/ses-${pn[4]}; fi

  pdir=${derivates}/${iter}/sub-${pn[1]}${pn[2]}/ses-${pn[4]}/pet

  # create PET directory in the derivates and make a copy of the raw pet.nii.gz
  mkdir $pdir
  cp $input $pdir

  echo "----------------------------------------------------------------------------------------------------------------
  Doing motion correction for ${pdir}/${pet}.
  ----------------------------------------------------------------------------------------------------------------"

  # motion correct
  mcflirt -in ${pdir}/${pet} -refvol 0 -out $pdir/mc_${pet} # out = mc_p1.nii

  echo "----------------------------------------------------------------------------------------------------------------
  Summing up frames of $pdir/mc_${pet}.
  ----------------------------------------------------------------------------------------------------------------"

  # sum
  mri_concat $pdir/mc_${pet} --sum --o $pdir/sum_mc_${pet} # out = sum_mc_p1.nii.gz

  echo "----------------------------------------------------------------------------------------------------------------
  Reslicing $pdir/sum_mc_${pet}.
  ----------------------------------------------------------------------------------------------------------------"

  # reslice
  mri_convert $pdir/sum_mc_${pet} -vs 2 2 2 $pdir/rs_sum_mc_${pet} --force_ras_good # out = rs_sum_mc_p1.nii.gz

  echo "----------------------------------------------------------------------------------------------------------------
  Coregistering $pdir/rs_sum_mc_${pet} to ${subject}.
  ----------------------------------------------------------------------------------------------------------------"

  # coregister to T1
  mri_coreg --s ${subject} --targ $SUBJECTS_DIR/${subject}/mri/brain.mgz --no-ref-mask --mov $pdir/rs_sum_mc_${pet} --reg $pdir/p2mri1.reg.lta --dof 9 --threads 3 # out = p2mri1.reg.lta

  # move to T1
  mri_vol2vol --reg $pdir/p2mri1.reg.lta --mov $pdir/rs_sum_mc_${pet} --fstarg --o $pdir/in-anat-${pet}  # out = in-anat-p.nii.gz

  echo "----------------------------------------------------------------------------------------------------------------
  Calculating SUVR from $pdir/rs_sum_mc_${pet}.
  ----------------------------------------------------------------------------------------------------------------"

  # make whitematter + graymatter mask
  make_mask ${SUBJECTS_DIR}/${subject}/mri/aparc+aseg.mgz
  mask=${SUBJECTS_DIR}/${subject}/mri/wmgm_mask.nii.gz

  # extract average value within the mask from the image
  fslstats $pdir/in-anat-${pet} -k $mask -M > ${pdir}/wmgm_mean_activity
  R=$( cat ${pdir}/wmgm_mean_activity )

  # capture ref values
  echo ${subject} ses-${pn[4]} $R >> wmgm_mean_activity_values.txt

  # dived the image by the average value
  fslmaths $pdir/rs_sum_mc_${pet} -div $R ${pdir}/SUVR.nii.gz
  fslmaths $pdir/in-anat-${pet} -div $R ${pdir}/SUVR.in.anat.nii.gz

  echo "----------------------------------------------------------------------------------------------------------------
  Registering ${subject} to MNI152
  ----------------------------------------------------------------------------------------------------------------"

  # create a map to MNI152
  mni152reg --s ${subject}

  echo "----------------------------------------------------------------------------------------------------------------
  Normalizing and smoothing ${pdir}/SUVR.nii.gz.
  ----------------------------------------------------------------------------------------------------------------"

  # move SUVR to MNI152
  mri_vol2vol --mov $pdir/SUVR.nii.gz --reg $pdir/p2mri1.reg.lta --mni152reg --talres 2 --o $pdir/SUVR.mni152.2mm.sm00.nii.gz #out = SUVR1.mni152.2mm.sm00.nii.gz

  # smooth SUVRs
  fslmaths $pdir/SUVR.mni152.2mm.sm00.nii.gz -s 8 $pdir/SUVR.mni152.2mm.sm08.nii.gz # out = SUVR1.mni152.2mm.sm05.nii.gz

  # catch error status
  echo ${subject} ses-${pn[4]} $? >> error.log

}

run_all() {
  list_of_subjects=$1

  while read subject; do
    pet002=/group/tuominen/TBS-FDG/rawdata/sub-${subject}/ses-002/pet/sub-${subject}-ses-002_pet.nii.gz
    pet003=/group/tuominen/TBS-FDG/rawdata/sub-${subject}/ses-003/pet/sub-${subject}-ses-003_pet.nii.gz
    mri002=sub-${subject}_ses-002
    mri003=sub-${subject}_ses-003
    iter6=/group/tuominen/TBS-FDG/derivatives/iter6

    preproc $pet002 $mri002 $iter6 &
    preproc $pet003 $mri003 $iter6

  done < $list_of_subjects

}


run_all $1
