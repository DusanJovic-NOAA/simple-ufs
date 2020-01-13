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

cp ../post_conf/params_grib2_tbl_new  .
cp ../post_conf/postxconfig-NT.txt .

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

for FHR in ${FHRS[@]}; do

  NEWDATE=$(date +"%Y%m%d%H" --date "${start_date} ${FHR} hours")
  YY=${NEWDATE:0:4}
  MM=${NEWDATE:4:2}
  DD=${NEWDATE:6:2}
  HH=${NEWDATE:8:2}

  cat > itag.${FHR} <<EOF
../model_run/dynf${FHR}.nc
netcdf
grib2
${YY}-${MM}-${DD}_${HH}:00:00
GFS
../model_run/phyf${FHR}.nc

&NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,
                 675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,
                 375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,
                  70., 50., 30., 20., 10.,  7.,  5.,  3.,  2.,  1.,
/
EOF

  cp itag.${FHR} itag
  mpiexec -np 4 ${sufs}/bin/ufs_post 1> stdout.${FHR} 2> stderr.${FHR}
  rm itag

done

echo "Done!"
