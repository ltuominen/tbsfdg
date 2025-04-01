import ants
import os
import shutil
import sys

HELP_DOC ="""""
    Cli wrapper for ants.py nonlinear SyNRA registration for PET 
    args: 1. target image, 2. image to be moved, 3. image to be moved with, 4. outputdir
    example: ./ants_reg.py MNI152template.nii.gz T1w.nii.gz PET_in_anat.nii.gz /path/to/output 
"""

# Argument parser (allowing the registration script to be called from main preprocessing script, with 'subj' as argument)
if '-h' in sys.argv or '--help' in sys.argv or len(sys.argv)<2:
    print(HELP_DOC)
    sys.exit(0)

target = sys.argv[1]
mov = sys.argv[2]
movwith = sys.argv[3]
if len(sys.argv) < 5:
    outputdir = os.getwd()
else:
    outputdir = sys.argv[4]

nlin6 = ants.image_read(target)
ANAT = ants.image_read(mov)
PETscan = ants.image_read(movwith)

transform_type = "SyNRA"
interpolation = "linear"

# register
TRANSFORMS = ants.registration(
	fixed = nlin6,
	moving = ANAT,
	type_of_transform = f'{transform_type}',
	verbose = True
)

# transform
PET_in_MNI = ants.apply_transforms(
	fixed = nlin6,
	moving = PETscan,
	transformlist=TRANSFORMS['fwdtransforms'],
	interpolator=f'{interpolation}',
	verbose = True
)

MNI_projection = f'{outputdir}/SUVR-in-MNI-2mm__{transform_type}_{interpolation}.nii.gz'

### Save the PET data in MNI
ants.image_write(PET_in_MNI, MNI_projection)


# Check how many forward transforms are returned
num_transforms = len(TRANSFORMS['fwdtransforms'])
print(f"Number of forward transforms: {num_transforms} \n")

# Print out each transform's details
for idx, transform in enumerate(TRANSFORMS['fwdtransforms']):
    print(f"Transform {idx}: {transform}")

## Non-linear
warp_transform = TRANSFORMS['fwdtransforms'][0]
warp_destination = f'{outputdir}/forward_warp_SyNRA.nii.gz'
## Save non-linear transforms
shutil.move(warp_transform, warp_destination)

## Linear
affine_transform = TRANSFORMS['fwdtransforms'][1]
affine_destination = f'{outputdir}/forward_affine_SyNRA.mat'
## Save affine transforms
shutil.move(affine_transform, affine_destination)