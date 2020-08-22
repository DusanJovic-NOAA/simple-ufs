#!/bin/bash
set -eu

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

(
rm -rf preproc
#git clone --recursive --branch develop https://github.com/NOAA-EMC/UFS_UTILS preproc
git clone --recursive --branch feature/cmakepkgs https://github.com/aerorahul/UFS_UTILS preproc
)

(
rm -rf model
git clone --recursive --branch develop https://github.com/ufs-community/ufs-weather-model model
#sed -i -e '/affinity.c/d' model/CMakeLists.txt
)

(
rm -rf post
git clone --recursive --branch develop https://github.com/NOAA-EMC/EMC_post post
)
