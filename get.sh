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
#rm -rf preproc
#git clone --branch generic_linux https://github.com/DusanJovic-NOAA/UFS_UTILS preproc
#git clone --recursive --branch release/ufs_release_v1.0 https://github.com/NOAA-EMC/UFS_UTILS preproc

rm -rf preproc_grib
git clone --branch feature/chgres_cube_grib2_release https://github.com/GeorgeGayno-NOAA/UFS_UTILS preproc_grib

sed -i'' -e '/NCEPLIBS/s/^/\#/' preproc_grib/modulefiles/chgres_cube.linux.gnu
sed -i'' -e '/NCEPLIBS/s/^/\#/' preproc_grib/modulefiles/chgres_cube.linux.intel
)

(
cd src
rm -rf model
git clone --recursive --branch develop https://github.com/ufs-community/ufs-weather-model model
sed -i'' -e '/affinity.c/s/^/\#/' model/CMakeLists.txt
sed -i'' -e '/LibXml2 REQUIRED/s/^/\#/' model/FV3/ccpp/framework/src/CMakeLists.txt
)

(
cd src
rm -rf post
git clone --recursive --branch ufs_release_v1.0 https://github.com/NOAA-EMC/EMC_post post
)
