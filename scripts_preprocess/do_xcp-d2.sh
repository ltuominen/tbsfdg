unset PYTHONPATH;
export SINGULARITYENV_TEMPLATEFLOW_HOME=/opt/templateflow
cd /group/tuominen/TBS-FDG

singularity -d run -B $HOME/.cache/templateflow:/opt/templateflow,/group/tuominen/TBS-FDG:/mnt \
/home/lauri/Documents/xcp_d-0.6.0.simg \
/mnt/derivatives/iter6s2 /mnt/xcp-d_output_s2/ participant \
--combineruns --nuisance-regressors 36P \
--min-coverage 0.5 \
--min-time 100 --dummy-scans 0 --bpf-order 2 --lower-bpf 0.01 --upper-bpf 0.08 \
--head-radius auto --fd-thresh 0.3 -v
 
singularity run -B $HOME/.cache/templateflow:/opt/templateflow,/group/tuominen/TBS-FDG:/mnt \
 /home/lauri/Documents/xcp_d-0.6.0.simg \
/mnt/derivatives/iter6s3 /mnt/xcp-d_output_s3/ participant \
--combineruns --nuisance-regressors 36P \
--min-coverage 0.5 \
--min-time 100 --dummy-scans 0 --bpf-order 2 --lower-bpf 0.01 --upper-bpf 0.08 \
--head-radius auto --fd-thresh 0.3 -v





