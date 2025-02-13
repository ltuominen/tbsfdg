#!/usr/bin/env python
# coding: utf-8

import os
import numpy as np
import nibabel as nb
import ants

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


# motion correction & sum 
def motioncorrection(pet_fullpath, subject, session):

    """Do motion correction and sum the PET file and return the fullpath of mc corrected and summed pet image

    Args:
        pet_file (str): fullpath to the unprocessed pet nifti file in native space 
        subject (str): subject id, e.g. sub-tbsfdg002
        session (str): session number: ses-002 or ses-003
    """

    pet_dir = os.path.dirname(pet_fullpath)
    # do first round motion correction 
    pet_image=ants.image_read(pet_fullpath) 
    images_unmerged = ants.ndimage_to_list( pet_image )
    motion_corrected_first = list()
    for i in range(len(images_unmerged)):
        areg = ants.registration( images_unmerged[0], images_unmerged[i], type_of_transform='Affine' )
        motion_corrected_first.append( areg[ 'warpedmovout' ] )   

    # sum the motion corrected to be used as a template
    template= motion_corrected_first[0]
    for i in range(1,len(motion_corrected_first)):
        template + motion_corrected_first[i]
    template_pet_fullpath = f'{pet_dir}/{subject}-{session}_template_pet.nii.gz' 
    ants.image_write(image=template, filename=template_pet_fullpath) 

    # do motion correction but this time use the template
    motion_corrected_second = list()
    for i in range(len(images_unmerged)):
        areg = ants.registration( template, images_unmerged[i], type_of_transform='Affine')
        motion_corrected_second.append( areg[ 'warpedmovout' ] ) 
        
    # save the motion corrected PET   
    mc = ants.list_to_ndimage( pet_image, motion_corrected_second )
    mc_pet_fullpath = f'{pet_dir}/{subject}-{session}_mc_pet.nii.gz' 
    ants.image_write(image=mc, filename=mc_pet_fullpath) 
    
    # sum the motion corrected PET
    sum_mc = motion_corrected_second[0]
    for i in range(1,len(motion_corrected_second)):
        sum_mc  + motion_corrected_second[i]
    sum_mc_pet_fullpath = f'{pet_dir}/{subject}-{session}_sum_mc_pet.nii.gz' 
    ants.image_write(image=sum_mc, filename=sum_mc_pet_fullpath) 
    
    return(sum_mc_pet_fullpath)
    