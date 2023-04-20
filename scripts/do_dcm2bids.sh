# Wrapper for dcm2bids https://unfmontreal.github.io/Dcm2Bids/

folders=$(ls ../dcm)
np=0 # counter for resources
maxjobs=4
for f in ${folders[@]}; do
  # get name and session
  spltf=(${f//-/ })
  sub=${spltf[2]}
  ses="00${spltf[3]}"

  # define config file
  case $ses in
    001)
    configfile=config_pretms_visit.json
    ;;
    002)
      configfile=config_tms_visit.json
    ;;
    003)
      configfile=config_tms_visit.json
    ;;
  esac

  # run dcm2bids
  dcm2bids -d ../dcm/$f -p tbsfdg$sub -s $ses -c ../info/${configfile} -o ../rawdata &

  # manage resources, run 4 jobs simultaneously
  (( np++ ))
  if [ $np == $maxjobs ]; then
	 wait
	 np=0
  fi

done
