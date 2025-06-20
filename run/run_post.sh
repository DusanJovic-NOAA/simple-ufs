#!/bin/bash
set -eux

if [[ $(uname -s) == Linux ]]; then
ulimit -s unlimited
fi

source configuration.sh

MYDIR=$(pwd)

POST_RUN_DIR=${MYDIR}/post_run
rm -rf ${POST_RUN_DIR}
mkdir -p ${POST_RUN_DIR}

cd ${POST_RUN_DIR}

start_date="${START_YEAR}-${START_MONTH}-${START_DAY} ${START_HOUR}:00:00"

FHRS=()
for FHR in $(seq -s ' ' -f %03g 00 $NFHOUT_HF $NFHMAX_HF); do
  FHRS+=( "$FHR" )
done

if [[ $((NFHMAX_HF + NFHOUT)) -lt $NHOURS_FCST ]]; then
  for FHR in $(seq -s ' ' -f %03g $((NFHMAX_HF + NFHOUT)) $NFHOUT $NHOURS_FCST); do
    FHRS+=( "$FHR" )
  done
fi

if [[ $gtype == regional* ]]; then
  IOFORM='netcdf'
  MODELNAME='FV3R'
  conf_dir='regional_conf'
else
  IOFORM='netcdfpara'
  MODELNAME='GFS'
  conf_dir='global_conf'
fi

cp ${sufs}/src/model/FV3/upp/parm/params_grib2_tbl_new .

for FHR in "${FHRS[@]}"; do

  NEWDATE=$(date +"%Y%m%d%H" --date "${start_date} ${FHR} hours")
  YY=${NEWDATE:0:4}
  MM=${NEWDATE:4:2}
  DD=${NEWDATE:6:2}
  HH=${NEWDATE:8:2}

  cat > itag.${FHR} <<EOF
&MODEL_INPUTS
 FILENAME='../model_run/atmf${FHR}.nc'
 IOFORM='${IOFORM}'
 GRIB='grib2'
 DateStr='${YY}-${MM}-${DD}_${HH}:00:00'
 MODELNAME='${MODELNAME}'
 fileNameFlux='../model_run/sfcf${FHR}.nc'
 fileNameFlat='postxconfig-NT.txt'
/
EOF

  cat ../${conf_dir}/itag >> itag.${FHR}

  cp itag.${FHR} itag

  if [[ $FHR == '000' ]]; then
    cp ../${conf_dir}/postxconfig-NT_FH00.txt postxconfig-NT.txt
  else
    cp ../${conf_dir}/postxconfig-NT.txt      postxconfig-NT.txt 
  fi

  # On 8 CPUs (Intel(R) Xeon(R) W-2123 CPU @ 3.60GHz)

  # ~17 sec
  #export OMP_NUM_THREADS=8
  #export NUM_TASKS=1

  # ~11 sec
  #export OMP_NUM_THREADS=4
  #export NUM_TASKS=2

  # ~7.5 sec
  #export OMP_NUM_THREADS=2
  #export NUM_TASKS=4

  # ~5 sec
  export OMP_NUM_THREADS=1
  export NUM_TASKS=8

  time ${MPIEXEC} -n ${NUM_TASKS} ${sufs}/bin/ufs_post 1> stdout.${FHR} 2> stderr.${FHR}
  rm itag

done

echo "Done!"
