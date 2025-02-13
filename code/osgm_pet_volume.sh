#! /bin/bash

parentdir=$( dirname $PWD)
contrasts=$parentdir/contrasts/
group=$parentdir/group/

# collect volumes
cmd=mri_concat
while read line; do
    cmd+=" --i ${contrasts}${line}_active_minus_sham_mni152_sm00.nii.gz"
    ls ${contrasts}${line}_active_minus_sham_mni152_sm00.nii.gz
done < subjects  
cmd+=" --o ${group}/all_active_minus_sham_mni152_sm00.nii.gz"
$cmd


# let's try different smooths 

for s in 6 8 10 12; do
        mri_fwhm --smooth-only --i $group/all_active_minus_sham_mni152_sm00.nii.gz \
        --fwhm $s --o ${group}/all_active_minus_sham_mni152_sm${s}.nii.gz  
done


# let's fit all those different smooths 

for s in 6 8 10 12; do
        mkdir ${group}/mni152__active_minus-sham_sm${s}/
        mri_glmfit --y ${group}/all_active_minus_sham_mni152_sm${s}.nii.gz    \
        --save-eres \
        --osgm \
        --mask /home/lauri/Documents/TMS-FDG/tbsfdg/graymask.nii.gz\
        --nii.gz \
        --glmdir ${group}/mni152__active_minus-sham_sm${s}/ \

done

# permutate 
for s in 6 8 10 12; do

    mri_glmfit-sim --glmdir ${group}/mni152__active_minus-sham_sm${s}/ --perm 1000 1.3 abs --cwp 0.05 

done 
