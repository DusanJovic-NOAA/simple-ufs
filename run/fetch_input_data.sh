#!/bin/bash
set -eux

source configuration.sh

MYDIR=$(pwd)

rm -rf ${INPUT_DATA}
mkdir ${INPUT_DATA}
cd ${INPUT_DATA}

YYYYMMDD=${START_YEAR}${START_MONTH}${START_DAY}
CC=${START_HOUR}

if [[ $INPUT_TYPE == grib2 ]]; then

  curl -O ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDD}/${CC}/gfs.t${CC}z.pgrb2.0p50.f000

  if [[ $gtype == regional* ]]; then
    for FHR in $(seq -s ' ' -f %03g $BC_INT $BC_INT $NHOURS_FCST); do
      curl -O ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDD}/${CC}/gfs.t${CC}z.pgrb2.0p50.f${FHR}
    done
  fi

elif [[ $INPUT_TYPE == nemsio ]]; then

  curl -O ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDD}/${CC}/gfs.t${CC}z.sfcanl.nemsio
  curl -O ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDD}/${CC}/gfs.t${CC}z.atmanl.nemsio

  if [[ $gtype == regional ]]; then
    for FHR in $(seq -s ' ' -f %03g $BC_INT $BC_INT $NHOURS_FCST); do
      curl -O ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDD}/${CC}/gfs.t${CC}z.atmf${FHR}.nemsio
    done
  fi

else

  echo "Unknown INPUT_TYPE ${INPUT_TYPE}"
  exit 1

fi
