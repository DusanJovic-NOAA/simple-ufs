#!/bin/bash
set -eu
set -o pipefail

usage() {
  echo "Usage: $0 gnu | intel [-all] [-ufslibs] [-preproc] [-model] [-post]"
  exit 1
}

[[ $# -lt 2 ]] && usage

export COMPILER=$1
shift

if [[ $COMPILER == gnu ]]; then
  export CC=${CC:-gcc}
  export CXX=${CXX:-g++}
  export FC=${FC:-gfortran}
  export MPICC=${MPICC:-mpicc}
  export MPICXX=${MPICXX:-mpicxx}
  export MPIF90=${MPIF90:-mpif90}
elif [[ $COMPILER == intel ]]; then
  if [[ $(command -v ftn) ]]; then
    # Special case on Cray systems
    export CC=${CC:-cc}
    export CXX=${CXX:-CC}
    export FC=${FC:-ftn}
    export MPICC=${MPICC:-cc}
    export MPICXX=${MPICXX:-CC}
    export MPIF90=${MPIF90:-ftn}
  else
    export CC=${CC:-icc}
    export CXX=${CXX:-icpc}
    export FC=${FC:-ifort}
    export MPICC=${MPICC:-mpicc}
    export MPICXX=${MPICXX:-mpicxx}
    export MPIF90=${MPIF90:-mpif90}
  fi
else
  usage
fi

BUILD_UFSLIBS=no
BUILD_PREPROC=no
BUILD_MODEL=no
BUILD_POST=no

while [[ $# -gt 0 ]]; do
opt=$1

case $opt in
  -all)
    BUILD_UFSLIBS=yes
    BUILD_PREPROC=yes
    BUILD_MODEL=yes
    BUILD_POST=yes
    shift
    ;;
  -ufslibs)
    BUILD_UFSLIBS=yes
    shift
    ;;
  -preproc)
    BUILD_PREPROC=yes
    shift
    ;;
  -model)
    BUILD_MODEL=yes
    shift
    ;;
  -post)
    BUILD_POST=yes
    shift
    ;;
  *)
    echo "unknown option ${opt}"
    usage
esac
done

echo "BUILD_UFSLIBS = ${BUILD_UFSLIBS}"
echo "BUILD_PREPROC = ${BUILD_PREPROC}"
echo "BUILD_MODEL   = ${BUILD_MODEL}"
echo "BUILD_POST    = ${BUILD_POST}"


readonly MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

# print compiler version
echo
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
cmake --version | head -1
echo

mpiexec --version
echo

export OMPI_CC=${CC}
export OMPI_CXX=${CXX}
export OMPI_FC=${FC}

#
# ufslibs
#
if [ $BUILD_UFSLIBS == yes ]; then
SECONDS=0
printf '%-.30s ' "Building ufslibs .........................."
(
  cd libs/ufslibs

  rm -rf build install
  mkdir build
  cd build

  cmake .. -DCMAKE_INSTALL_PREFIX=../install

  make -j 8

) > log_ufslibs 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi

CMAKE_PREFIX_PATH="${MYDIR}/libs/ufslibs/install"

export ESMFMKFILE=${CMAKE_PREFIX_PATH}/lib/esmf.mk

export CC=${MPICC}
export CXX=${MPICXX}
export FC=${MPIF90}

#
# preproc
#
if [ $BUILD_PREPROC == yes ]; then
SECONDS=0
printf '%-.30s ' "Building preproc ..........................."
(
  cd src/preproc

  rm -rf build
  mkdir build
  cd build

  cmake .. -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
           -DCMAKE_INSTALL_PREFIX="${MYDIR}"

  make -j 8
  make install

) > log_preproc 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi

#
# model
#
if [ $BUILD_MODEL == yes ]; then
SECONDS=0
printf '%-.30s ' "Building model ..........................."
(
  cd src/model

  rm -rf build
  mkdir build
  cd build

  cmake .. -DAPP=ATM \
           -DCCPP_SUITES="FV3_GFS_v16,FV3_GFS_2017_gfdlmp_regional" \
           -D32BIT=ON \
           -DINLINE_POST=ON \
           -DPARALLEL_NETCDF=ON \
           -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
           -DCMAKE_INSTALL_PREFIX=install

  # cmake .. -DAPP=S2S \
  #          -DCCPP_SUITES="FV3_GFS_v16_coupled" \
  #          -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
  #          -DCMAKE_INSTALL_PREFIX=install

  make -j8
  make install

  cp ufs_model ${MYDIR}/bin/ufs_model

) > log_model 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi

#
# post
#
if [ $BUILD_POST == yes ]; then
SECONDS=0
printf '%-.30s ' "Building post ..........................."
(
  cd src/post

  rm -rf build
  mkdir build
  cd build

  cmake .. -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}"

  make -j8

  cp sorc/ncep_post.fd/upp.x ${MYDIR}/bin/ufs_post

) > log_post 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi

echo "Done!"
