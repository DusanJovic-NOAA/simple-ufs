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

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

ALL_LIBS="
NCEPLIBS-bacio
NCEPLIBS-g2
NCEPLIBS-g2tmpl
NCEPLIBS-gfsio
NCEPLIBS-ip
NCEPLIBS-landsfcutil
NCEPLIBS-nemsio
NCEPLIBS-nemsiogfs
NCEPLIBS-sfcio
NCEPLIBS-sigio
NCEPLIBS-sp
NCEPLIBS-w3emc
NCEPLIBS-w3nco
EMC_crtm
"

export NEMSIO_LIB=${MYDIR}/local/nemsio/lib
export NEMSIO_INC=${MYDIR}/local/nemsio/include
export SIGIO_LIB=${MYDIR}/local/sigio/lib
export SIGIO_INC=${MYDIR}/local/sigio/include

for libname in ${ALL_LIBS}; do
  printf '%-.30s ' "Building ${libname} ..........................."
  (
    set -x
    install_name=${libname//NCEPLIBS-/}
    install_name=${install_name//EMC_/}
    cd ${MYDIR}/${libname}
    rm -rf build
    mkdir build
    cd build
    cmake .. \
          -DCMAKE_INSTALL_PREFIX=${MYDIR}/local/${install_name} \
          -DCMAKE_C_COMPILER=${CC} \
          -DCMAKE_CXX_COMPILER=${CXX} \
          -DCMAKE_Fortran_COMPILER=${FC} \
          -DCMAKE_BUILD_TYPE=RELEASE \
          -DCMAKE_PREFIX_PATH=${MYDIR}/../3rdparty/local
    make VERBOSE=1
    make install

    if [[ ${libname} == "NCEPLIBS-nemsio" ]]; then
      # inconsistent naming of nemsio include directory and library name
      mv ${MYDIR}/local/nemsio/include_4 ${MYDIR}/local/nemsio/include
    fi

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
