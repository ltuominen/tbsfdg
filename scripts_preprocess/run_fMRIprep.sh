np=0
maxjobs=16

tmp=$( find ../../rawdata/ -maxdepth 1 -name "sub-*")
subjects=()
for t in ${tmp[@]}; do
b=$( basename $t )
subjects+=( ${b:4} )
done 

#--here we define fmriprep settings--#
bids_root_dir="/group/tuominen/TBS-FDG"
nthreads=4
#--here we define fmriprep settings--#

for subject in ${subjects[@]}; do
	for SD in SUBJECTS_DIR_ses-002 SUBJECTS_DIR_ses-003; do 
	    if [ $SD = SUBJECTS_DIR_ses-002 ]; then
	    work=/home/lauri/work1; filter=/mnt/tbsfdg/scripts/bids_filter_ses-002.json; deriv=/mnt/derivatives/iter6s2
	    else 
	    work=/home/lauri/work2; filter=/mnt/tbsfdg/scripts/bids_filter_ses-003.json; deriv=/mnt/derivatives/iter6s3
	    fi

	    unset PYTHONPATH; singularity run -B $HOME/.cache/templateflow:/opt/templateflow,$bids_root_dir:/mnt /home/test-oc/singularity/images/fmriprep-23.0.2.simg \
	    /mnt/rawdata/ $deriv  \
	    participant \
	    --participant-label ${subject} \
	    -w $work \
	    --fs-license-file /mnt/tbsfdg/scripts/license.txt \
	    --fs-subjects-dir /mnt/${SD} \
	    --output-spaces MNI152NLin6Asym:res-2 fsaverage:res-native \
	    --use-aroma \
	    --write-graph \
	    --nthreads $nthreads \
	    --omp-nthreads $nthreads \
	    --bids-filter-file $filter \
	    --verbose &
	done 

  # manage resources, run 4 jobs simultaneously
  (( np++ ))
  if [ $np == $maxjobs ]; then
  	 wait
  	 np=0
  fi
  
done
