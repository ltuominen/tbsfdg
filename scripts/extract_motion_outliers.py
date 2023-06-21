import os
import numpy as np
import sys
import pandas as pd
import seaborn as sns

# get subjects
subjects=list(np.genfromtxt(sys.argv[1],dtype='str'))
derivates='/group/tuominen/TBS-FDG/derivatives/iter6/'

# initialize
data = {}

# loop over subjects and sesssions fill out data dictionary
for subject in subjects:
  for ses in ['002', '003' ]:
      fd_metrics=derivates + 'sub-' + subject + '/ses-' + ses + '/pet/fd_motion.metrics'
      numbers = np.loadtxt(fd_metrics)
      motion_data[(subject + '-' + ses)] = numbers

df=pd.DataFrame(data)

# output
output_file= os.path.dirname(os.getcwd()) + '/qc/fd_pet_motion.csv'
df.to_csv(output_file)
