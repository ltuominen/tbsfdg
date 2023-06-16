#! /bin/bash

## preproc FDG PET data

input=$1 # path to raw pet scan (pet.nii)
subject=$2 # subject name as in SUBJECTS_DIR
derivates=$3 # path to derivates folder
iter=$4 # name of iter folder in the derivates folder

pet=$( basename $input )
spl_pet=(${pet//_/ })
pn=(${spl_pet[0]//-/ })

# create folders if missing
if [ ! -d  ${derivates}/${iter} ]; then mkdir ${derivates}/${iter}; fi
if [ ! -d ${derivates}/${iter}/sub-${pn[1]} ]; then mkdir ${derivates}/${iter}/sub-${pn[1]}; fi
if [ ! -d ${derivates}/${iter}/sub-${pn[1]}/ses-${pn[3]} ]; then mkdir ${derivates}/${iter}/sub-${pn[1]}/ses-${pn[3]}; fi

pdir=${derivates}/${iter}/sub-${pn[1]}/ses-${pn[3]}/pet

# create PET directory in the derivates and make a copy of the raw pet.nii 
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
mri_concat $pdir/mc_${pet}.gz --sum --o $pdir/sum_mc_${pet}.gz # out = sum_mc_p1.nii.gz

echo "----------------------------------------------------------------------------------------------------------------
Reslicing $pdir/sum_mc_${pet}.gz.
----------------------------------------------------------------------------------------------------------------"

# reslice
mri_convert $pdir/sum_mc_${pet}.gz -vs 2 2 2 $pdir/rs_sum_mc_${pet}.gz --force_ras_good # out = rs_sum_mc_p1.nii.gz

echo "----------------------------------------------------------------------------------------------------------------
Coregistering $pdir/rs_sum_mc_${pet}.gz to ${subject}.
----------------------------------------------------------------------------------------------------------------"

# coregister to T1
mri_coreg --s ${subject} --targ $SUBJECTS_DIR/${subject}/mri/brain.mgz --no-ref-mask --mov $pdir/rs_sum_mc_${pet}.gz --reg $pdir/p2mri1.reg.lta --dof 9 --threads 3 # out = p2mri1.reg.lta

# move to T1
mri_vol2vol --reg $pdir/p2mri1.reg.lta --mov $pdir/rs_sum_mc_${pet}.gz --fstarg --o $pdir/in-anat-${pet}.gz  # out = in-anat-p.nii.gz

echo "----------------------------------------------------------------------------------------------------------------
Calculating SUVR from $pdir/rs_sum_mc_${pet}.gz.
----------------------------------------------------------------------------------------------------------------"

# make whitematter + graymatter mask
./make_mask.sh ${SUBJECTS_DIR}/${subject}/mri/aparc+aseg.mgz
mask=${SUBJECTS_DIR}/${subject}/mri/wmgm_mask.nii.gz

# extract average value within the mask from the image
fslstats $pdir/in-anat-${pet}.gz -k $mask -M > ${pdir}/wmgm_mean_activity
R=$( cat ${pdir}/wmgm_mean_activity )

# dived the image by the average value
fslmaths $pdir/rs_sum_mc_${pet}.gz -div $R ${pdir}/SUVR.nii.gz
fslmaths $pdir/in-anat-${pet}.gz -div $R ${pdir}/SUVR.in.anat.nii.gz

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
