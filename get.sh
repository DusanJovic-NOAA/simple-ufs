#!/bin/bash
set -eu

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
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
git clone --branch generic_linux https://github.com/DusanJovic-NOAA/UFS_UTILS preproc
)

(
cd src
rm -rf model
git clone --recursive --branch develop https://github.com/ufs-community/ufs-weather-model model
)

(
cd src
rm -rf post
git clone --recursive --branch ufs_release_v1.0 https://github.com/NOAA-EMC/EMC_post post
)
