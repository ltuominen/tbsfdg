#!/usr/bin/env python
# coding: utf-8

import os
import sys
import numpy as np
import pandas as pd
import subprocess
import nibabel as nb
from nibabel.freesurfer.io import read_label


def surf2vol(fMRI_file):
    '''
    Use freesurfer mri_vol2surf to convert fMRI from MNI152 to fsaverage
    '''

    FMRI_PATH = os.path.dirname(fMRI_file)
    split_id = os.path.basename(fMRI_file).split('_')
    id = split_id[0] + '_' + split_id[1]
    surface = os.path.join(FMRI_PATH, id + '.lh.fsaverage.preprocessed.nii.gz')

    # vol2surf
    cmd = [
    "mri_vol2surf",
    "--mov", fMRI_file,
    "--mni152reg",
    "--hemi", "lh",
    "--surf", "white",
    "--o", surface
    ]
    # Run the command
    result = subprocess.run(cmd, capture_output=True, text=True)
    return(surface)


def get_awf(label, surface):
    '''
    extract seed time series and save
    '''

    # extract seed
    img_L = nb.load(surface).get_fdata()
    img_L = np.squeeze(img_L)
    awf = np.mean(img_L[label,:],0)

    # save awf
    split_id = os.path.basename(surface).split('.')
    id = split_id[0]
    FMRI_PATH = os.path.dirname(surface)
    np.savetxt(os.path.join(FMRI_PATH, id + '_awf.txt'), awf)

    return(awf)


def seed2vox(full_file, awf):
    '''
    calculate correlations between seed and all voxels
    save correlations and zscored data
    '''

    # load fMRI
    fMRI = nb.load(full_file)
    fMRI_data =fMRI.get_fdata()

    # Calculate means, std, and normalize
    fMRI_mean = np.mean(fMRI_data, axis=3, keepdims=True)
    fMRI_std = np.std(fMRI_data, axis=3, keepdims=True)
    epsilon = 1e-8
    fMRI_std_adjusted = fMRI_std + epsilon
    normalized_fMRI = (fMRI_data - fMRI_mean) / fMRI_std_adjusted

    # variance normalize seed time series
    awf_mean = np.mean(awf)
    awf_std = np.std(awf)
    normalized_seed = (awf - awf_mean) / awf_std

    # calculate correlation between seed and voxels
    seed_correlations = np.dot(normalized_fMRI, normalized_seed) / normalized_seed.shape[0]
    zscored = np.arctanh(seed_correlations)

    # save data
    corr_img = nb.Nifti1Image(seed_correlations, fMRI.affine, nb.Nifti1Header())
    zscored_img = nb.Nifti1Image(zscored, fMRI.affine, nb.Nifti1Header())

    # write data
    split_id = os.path.basename(full_file).split('_')
    id = split_id[0] + '_' + split_id[1]
    FMRI_PATH = os.path.dirname(full_file)
    nb.save(corr_img, os.path.join(FMRI_PATH, id + '.seed_to_voxel_correlations.nii'))
    nb.save(zscored_img, os.path.join(FMRI_PATH, id + '.seed_to_voxel_zscore.nii'))

    # return
    return((corr_img, zscored_img))

if __name__ == "__main__":

    fMRI_file = sys.argv[1]
    label = sys.argv[2]

    surface = surf2vol(fMRI_file)

    awf = get_awf(label,surface)

    seed2vox(fMRI_file, awf)
