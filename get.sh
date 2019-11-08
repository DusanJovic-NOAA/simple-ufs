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
git clone https://github.com/DusanJovic-NOAA/UFS_UTILS --branch generic_linux preproc
)

(
cd src
rm -rf model
git clone --recursive https://github.com/DusanJovic-NOAA/ufs-weather-model --branch cmake_rt  model
)

(
cd src
rm -rf post
git clone https://github.com/NOAA-EMC/EMC_post post
)
