# dlPFC iTBS and [18F]FDG-PET uptake  

This is a repository for code for a project comparing the effects of active iTBS to sham stimulation on [18F]FDG-PET uptake in 16 healthy control subjects


## Folders

### info

contains various scan info & [order of the scans](info/unmask.txt)

### scripts_preprocess

scripts for preprocessing PET data

### scripts_analysis

scripts to plot:
+ [Reference tissue SUV](scripts_analysis/Plot_reference_SUV.ipynb)
+ [Individual scans in MNI152 for qc](scripts_analysis/plot_fdg_mni.py)
+ [Head motion during PET scans](scripts_analysis/plot_motion.ipynb)
+ [Individual active - sham PET contrasts](scripts_analysis/plot_contrasts_and_pct.ipynb)
+ [Uncorrected GLM](scripts_analysis/Plot_uncorrected_GLM.ipynb)

### qc

contains individual scans & contrast images in MNI152

### contrasts

+ active vs sham contrast [$^18$F]FDG-PET nifti files for each subject
+ percetage differences ((active-sham)/sham)*100 for each subject

### group

[osgm](group/active_vs_sham/osgm/) contains output files from the glm

### results

currently empty
