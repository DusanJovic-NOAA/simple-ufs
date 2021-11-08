#!/bin/bash
set -eu

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
cd ${MYDIR}

(
rm -rf preproc
git clone --recursive --branch develop https://github.com/ufs-community/UFS_UTILS preproc
)

(
rm -rf model
git clone --recursive --branch develop https://github.com/ufs-community/ufs-weather-model model
)

(
rm -rf post
git clone --recursive --branch develop https://github.com/NOAA-EMC/EMC_post post
)
