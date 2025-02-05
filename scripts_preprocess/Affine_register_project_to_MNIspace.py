import ants
import glob, os
import datetime
import shutil
import argparse

# Argument parser
parser = argparse.ArgumentParser(description='Process a subject.')
parser.add_argument('subj', type=str, help='Subject ID')
args = parser.parse_args()
subj = args.subj

### settings

# Retrieve the SUBJECTS_DIR environment variable
FS_subjects_dir = os.environ.get('SUBJECTS_DIR')
# Get the parent directory of SUBJECTS_DIR
root = os.path.dirname(FS_subjects_dir)

mni = f'{project_dir}/atlas-for-ROIs/MNI152_1mm_brain_stripped-2mmb-no-csf.nii.gz'
nlin6 = ants.image_read(mni)

print('###############################################################################################\n')
print('    Processing the following subject:')
print(f'    {subj} \n')
print('###############################################################################################\n')

petdir = f'{project_dir}/subjects/{subj}/pet/001/'
brain = glob.glob(f'{petdir}/synthstripped-brain_no-csf.nii.gz')[0]
pet_scan = ants.image_read(f'{petdir}/SUVR-in-anat.nii.gz')
os.chdir(petdir)

print(f'######### Registering T1 to MNI with Affine \n')
anat = ants.image_read(brain)
transformations_X = ants.registration(
	fixed=nlin6,
	moving=anat,
	type_of_transform='Affine',
	verbose=True
)

##### try TRSAA

### forward projection
print(f'######### Projecting {subj} PET scan forward with linear interpolator \n')
pet_scan_in_MNI = ants.apply_transforms(
    fixed=nlin6,
    moving=pet_scan,
    transformlist=transformations_X['fwdtransforms'],
    interpolator='linear'
)
ants.image_write(pet_scan_in_MNI, f'{petdir}/pet_scan-in-MNI_Affine_linear.nii.gz')
if os.path.isfile(f'{petdir}/pet_scan-in-MNI_Affine_linear.nii.gz'):
    # If the projection was created, append a comment to logs
    with open(f'{petdir}/projection.log', 'a') as log_file:
        log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  pet_scan-in-MNI_Affine_linear.nii.gz successfully created.\n")
    with open(f'{project_dir}/subjects/projection.master.log', 'a') as master_log_file:
        master_log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  pet_scan-in-MNI_Affine_linear.nii.gz successfully created for {subj}.\n")
    print(f'##### Logs updated:  pet_scan-in-MNI_Affine_linear.nii.gz successfully created  for {subj}. ##### \n\n')
else:
    # if the projection was NOT created, append a comment to log
    with open(f'{petdir}/projection.log', 'a') as log_file:
        log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  ERROR ::: pet_scan-in-MNI_Affine_linear.nii.gz was NOT created.\n")
    with open(f'{project_dir}/subjects/projection.master.log', 'a') as master_log_file:
        master_log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  ERROR ::: pet_scan-in-MNI_Affine_linear.nii.gz was NOT created for {subj}.\n")
    print('----------------------------------------------------------------------------------------------------------\n')
    print(f'------- Logs updated:  ERROR ::: pet_scan-in-MNI_Affine_linear.nii.gz was NOT created for {subj}.----------  \n\n')


print(f'######### Projecting {subj} PET scan forward with bSpline interpolator \n')
pet_scan_in_MNI = ants.apply_transforms(
    fixed=nlin6,
    moving=pet_scan,
    transformlist=transformations_X['fwdtransforms'],
    interpolator='bSpline'
)
ants.image_write(pet_scan_in_MNI, f'{petdir}/pet_scan-in-MNI_Affine_bSpline.nii.gz')
if os.path.isfile(f'{petdir}/pet_scan-in-MNI_Affine_bSpline.nii.gz'):
    # If the projection was created, append a comment to logs
    with open(f'{petdir}/projection.log', 'a') as log_file:
        log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  pet_scan-in-MNI_Affine_bSpline.nii.gz successfully created.\n")
    with open(f'{project_dir}/subjects/projection.master.log', 'a') as master_log_file:
        master_log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  pet_scan-in-MNI_Affine_bSpline.nii.gz successfully created for {subj}.\n")
    print(f'##### Logs updated:  pet_scan-in-MNI_Affine_bSpline.nii.gz successfully created  for {subj}. ##### \n\n')
else:
    # if the projection was NOT created, append a comment to log
    with open(f'{petdir}/projection.log', 'a') as log_file:
        log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  ERROR ::: pet_scan-in-MNI_Affine_bSpline.nii.gz was NOT created.\n")
    with open(f'{project_dir}/subjects/projection.master.log', 'a') as master_log_file:
        master_log_file.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ->  ERROR ::: pet_scan-in-MNI_Affine_bSpline.nii.gz was NOT created for {subj}.\n")
    print('----------------------------------------------------------------------------------------------------------\n')
    print(f'------- Logs updated:  ERROR ::: pet_scan-in-MNI_Affine_bSpline.nii.gz was NOT created for {subj}.----------  \n\n')



if len(transformations_X['fwdtransforms']) > 1:
    for idx, transform in enumerate(transformations_X['fwdtransforms']):
        # Define the destination path for each transform file
        affine_transform = f'{petdir}/forward_Affine_transformations_{idx+1}.mat'
        # Copy the affine transform file to the new location
        shutil.copy2(affine_transform, affine_destination)
else:
    affine_transform = transformations_X['fwdtransforms'][0]
    affine_destination = f'{petdir}/forward_Affine_transformations.mat'
    # Copy the affine transform file to the new location
    shutil.copy2(affine_transform, affine_destination)
