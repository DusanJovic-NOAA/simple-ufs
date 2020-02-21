#!/bin/bash
set -eu

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

(
cd libs/3rdparty
./build.sh fetch
)

(
cd libs/nceplibs
./get.sh
)

(
cd src
rm -rf preproc
git clone --recursive --branch release/public-v1 https://github.com/NOAA-EMC/UFS_UTILS preproc
)

(
cd src
rm -rf model
git clone --recursive --branch release/public-v1 https://github.com/ufs-community/ufs-weather-model model
)

(
cd src
rm -rf post
git clone --recursive --branch release/public-v8 https://github.com/NOAA-EMC/EMC_post post
)
