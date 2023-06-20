from nilearn import plotting
import os
import sys
import numpy as np

subjects=list(np.genfromtxt(sys.argv[1],dtype='str'))

derivates='/group/tuominen/TBS-FDG/derivatives/iter6/'
output_dir='/group/tuominen/TBS-FDG/tbsfdg/qc_images/'

fsl_dir=os.environ['FSL_DIR']
mni152=fsl_dir + '/data/standard/MNI152_T1_2mm_brain.nii.gz'

for subject in subjects:
    for ses in ['ses-002', 'ses-003']:
        petfile=os.path.join(derivates, ('sub-' + subject), ses, 'pet/SUVR.mni152.2mm.sm00.nii.gz')
        output_file=os.path.join(output_dir, (subject + '_' + ses + '.png' ))

        if os.path.exists(petfile):
            plotting.plot_stat_map(
                petfile,
                bg_img=mni152,
                title=subject + ' ' + ' ' + ses,
                threshold=1,
                output_file=output_file
            )
