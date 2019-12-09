#!/bin/bash

## Yet another simple script that downloads and builds
## nceplibs libraries required for the UFS Weather application.
##      -Dusan Jovic Oct. 2019

set -eu
set -o pipefail

usage() {
  echo "Usage: $0 gnu | intel"
  exit 1
}

[[ $# -ne 1 ]] && usage

COMPILERS=$1

if [[ $COMPILERS == gnu ]]; then
  export CC=${CC:-gcc}
  export CXX=${CXX:-g++}
  export FC=${FC:-gfortran}
elif [[ $COMPILERS == intel ]]; then
  export CC=${CC:-icc}
  export CXX=${CXX:-icpc}
  export FC=${FC:-ifort}
else
  usage
fi

date

echo
echo "Building nceplibs libraries using ${COMPILERS} compilers"
echo
#
# print compiler version
#
echo
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
mpiexec --version
cmake --version | head -1
echo

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

ALL_LIBS="bacio g2 g2tmpl gfsio ip landsfcutil nemsio nemsiogfs sfcio sigio sp w3emc w3nco"

export NEMSIO_LIB=${MYDIR}/local/nemsio/lib
export NEMSIO_INC=${MYDIR}/local/nemsio/include
export SIGIO_LIB=${MYDIR}/local/sigio/lib
export SIGIO_INC=${MYDIR}/local/sigio/include

for libname in ${ALL_LIBS}; do
  printf '%-.30s ' "Building ${libname} ..........................."
  (
    set -x
    cd ${MYDIR}/NCEPLIBS-${libname}
    rm -rf build
    mkdir build
    cd build
    cmake .. \
          -DCMAKE_INSTALL_PREFIX=${MYDIR}/local/${libname} \
          -DCMAKE_C_COMPILER=${CC} \
          -DCMAKE_CXX_COMPILER=${CXX} \
          -DCMAKE_Fortran_COMPILER=${FC} \
          -DCMAKE_BUILD_TYPE=RELEASE \
          -DCMAKE_PREFIX_PATH=${MYDIR}/../3rdparty/local
    make VERBOSE=1
    make install
  ) > log_${libname} 2>&1
  echo 'done'
done


for libname in crtm; do
  printf '%-.30s ' "Building ${libname} ..........................."
  (
    set -x
    cd ${MYDIR}/EMC_${libname}
    rm -rf build
    mkdir build
    cd build
    cmake .. \
          -DCMAKE_INSTALL_PREFIX=${MYDIR}/local/${libname} \
          -DCMAKE_C_COMPILER=${CC} \
          -DCMAKE_CXX_COMPILER=${CXX} \
          -DCMAKE_Fortran_COMPILER=${FC} \
          -DCMAKE_BUILD_TYPE=RELEASE \
          -DCMAKE_PREFIX_PATH=${MYDIR}/../3rdparty/local
    make VERBOSE=1
    make install
  ) > log_${libname} 2>&1
  echo 'done'
done


# special case
mv ${MYDIR}/local/sfcio/lib/libsfcio_v1.1.0.a ${MYDIR}/local/sfcio/lib/libsfcio_v1.1.0_4.a
mv ${MYDIR}/local/sigio/lib/libsigio_v2.1.0.a ${MYDIR}/local/sigio/lib/libsigio_v2.1.0_4.a

echo
date

echo
echo "Finished"
