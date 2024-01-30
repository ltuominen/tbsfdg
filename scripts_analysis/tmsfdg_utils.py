#!/usr/bin/env python
# coding: utf-8

import os
import numpy as np
import nibabel as nb


def make_spherical_roi(coordinates, radius):
    '''
    takes MNI152 coordinates and a radius and creates a sphere
    '''

    # this is in fsl MNI152 space
    fsl_dir=os.environ['FSL_DIR']
    mni152_brain=fsl_dir + '/data/standard/MNI152_T1_2mm_brain.nii.gz'
    data = nb.load(mni152_brain).get_fdata()
    affine = nb.load(mni152_brain).affine

    # the center and radius of the sphere in MNI coordinates
    center_roi = np.array(coordinates)

    # Convert MNI coordinates to voxel coordinates
    center_vox = np.round(nb.affines.apply_affine(np.linalg.inv(affine), center_roi)).astype(int)

    # calculate voxels within the sphere
    x, y, z = np.indices(data.shape)
    dist_from_center = np.sqrt((x - center_vox[0])**2 + (y - center_vox[1])**2 + (z - center_vox[2])**2)

    # Create a binary spherical mask
    mask = dist_from_center <= radius
    return nb.Nifti1Image(mask.astype('float32'), affine)
