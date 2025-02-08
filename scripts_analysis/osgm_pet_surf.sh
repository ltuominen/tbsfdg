#! /bin/bash

parentdir=$( dirname $PWD)
contrasts=$parentdir/contrasts/
group=$parentdir/group/

# collect surfaces 

for h in lh rh; do
    cmd=mri_concat
    while read line; do
        cmd+=" --i ${contrasts}${line}_hemi-${h}_active_minus_sham_fsaverage_sm00.nii.gz"

    done < subjects  
    cmd+=' --o ${group}/all_${h}_active_minus_sham_fsaverage_sm00.nii.gz --prune'
    $cmd
done 

# let's try different smooths 
for h in lh rh; do
    for s in 6 8 10 12; do
        mris_fwhm --smooth-only --i $group/all_${h}_active_minus_sham_fsaverage_sm00.nii.gz \
        --fwhm $s --cortex --s fsaverage --hemi ${h} --o ${group}/all_${h}_active_minus_sham_fsaverage_sm${s}.nii.gz  
    done
done

# let's fit all those different smooths 
for h in lh rh; do
    for s in 6 8 10 12; do

        mri_glmfit --y $${group}/all_${h}_active_minus_sham_fsaverage_sm${s}.nii.gz  \
        --surface fsaverage ${h} \
        --save-eres \
        --osgm \
        --nii.gz \
        --glmdir ${group}/${h}__active_minus_sham_fsaverage_sm${s}

    done
done 

