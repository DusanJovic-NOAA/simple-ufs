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
rm -rf UFS_UTILS
git clone https://github.com/DusanJovic-NOAA/UFS_UTILS --branch generic_linux preproc
)

(
cd src
rm -rf ufs-weather-model
git clone https://github.com/ufs-community/ufs-weather-model model
cd model
git fetch origin pull/1/head:PR1
git checkout PR1
git submodule sync
git submodule update --init --recursive
)

(
cd src
rm -rf EMC_post
git clone https://github.com/NOAA-EMC/EMC_post post
)
