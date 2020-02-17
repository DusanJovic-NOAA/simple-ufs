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

#
# Fix find_library bug
#
cd preproc/cmake
git checkout release/public-v1
for f in Modules/Find*.cmake
do
  echo $f
  sed -i'' -e '/find_library/i unset(lib_path CACHE)' $f
done

#sed -i'' -e '/NCEPLIBS/s/^/\#/' preproc/modulefiles/chgres_cube.linux.gnu
#sed -i'' -e '/NCEPLIBS/s/^/\#/' preproc/modulefiles/chgres_cube.linux.intel
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
git clone --recursive --branch release/public-v4 https://github.com/NOAA-EMC/EMC_post post

#
# Fix find_library bug
#
cd post/cmake
git checkout release/public-v1
for f in Modules/Find*.cmake
do
  echo $f
  sed -i'' -e '/find_library/i unset(lib_path CACHE)' $f
done

)
