#! /bin/bash

# define converter
pc=/group/tuominen/TBS-FDG/scripts/pet_convert

PETsearch=$( find ../e7ToolsRecon/ -maxdepth 1 -name "LTU*")
PETf=()
for f in ${PETsearch[@]}; do
  if [[ ! $f == *"0-900"* ]]; then
    bf=$( basename $f )
    PETf+=($bf)
  fi
done 


for f in ${PETf[@]}; do
  spltf=(${f//-/ })
  str=${spltf[0]}-${spltf[1]}-${spltf[2]}
  d=($(ls ../e7ToolsRecon/$f/$str*/$str*/$str*.ima))
  newf=../rawdata/sub-tbsfdg${spltf[2]}/ses-00${spltf[3]}/pet
  mkdir $newf/tmp
  dcm2niix -f sub-tbsfdg${spltf[2]}-ses-00${spltf[3]}_pet -b y -o $newf/tmp ${d[0]}
  cp $newf/tmp/sub-tbsfdg${spltf[2]}-ses-00${spltf[3]}_peta.json $newf/sub-tbsfdg${spltf[2]}-ses-00${spltf[3]}_pet.json
  rm -r $newf/tmp
 done 
 
