#!/bin/bash
set -eu
set -o pipefail

usage() {
  echo "Usage: $0 gnu | intel [-all] [-3rdparty] [-nceplibs] [-preproc] [-model] [-post]"
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
    MPI_IMPLEMENTATION=mpi
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

BUILD_3RDPARTY=no
BUILD_NCEPLIBS=no
BUILD_PREPROC=no
BUILD_MODEL=no
BUILD_POST=no

while [[ $# -gt 0 ]]; do
opt=$1

case $opt in
  -all)
    BUILD_3RDPARTY=yes
    BUILD_NCEPLIBS=yes
    BUILD_PREPROC=yes
    BUILD_MODEL=yes
    BUILD_POST=yes
    shift
    ;;
  -3rdparty)
    BUILD_3RDPARTY=yes
    shift
    ;;
  -nceplibs)
    BUILD_NCEPLIBS=yes
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

echo "BUILD_3RDPARTY = ${BUILD_3RDPARTY}"
echo "BUILD_NCEPLIBS = ${BUILD_NCEPLIBS}"
echo "BUILD_PREPROC  = ${BUILD_PREPROC}"
echo "BUILD_MODEL    = ${BUILD_MODEL}"
echo "BUILD_POST     = ${BUILD_POST}"


MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

# print compiler version
echo
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
cmake --version | head -1
echo

MPI_IMPLEMENTATION=${MPI_IMPLEMENTATION:-mpich3}
if ! command -v mpiexec > /dev/null ; then
  if [[ -f ${MYDIR}/mpilibs/local/${MPI_IMPLEMENTATION}/bin/mpiexec ]]; then
    export PATH=${MYDIR}/mpilibs/local/${MPI_IMPLEMENTATION}/bin:$PATH
  else
    echo "Missing mpiexec for ${MPI_IMPLEMENTATION}"
    exit 1
  fi
fi

mpiexec --version | grep OpenRTE 2> /dev/null && MPI_IMPLEMENTATION=openmpi
mpiexec --version | grep Intel 2> /dev/null && MPI_IMPLEMENTATION=intelmpi
mpiexec --version
echo

export MPICH_CC=${CC}
export MPICH_CXX=${CXX}
export MPICH_F90=${FC}
export MPICH_FC=${FC}
export OMPI_CC=${CC}
export OMPI_CXX=${CXX}
export OMPI_FC=${FC}

#
# 3rdparty
#
if [ $BUILD_3RDPARTY == yes ]; then
SECONDS=0
printf '%-.30s ' "Building 3rdparty .........................."
(
  cd libs/3rdparty
  ./build.sh ${COMPILER}
) > log_3rdparty 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi

export NETCDF=${MYDIR}/libs/3rdparty/local
export PATH=${NETCDF}/bin:${PATH} # for nc-config for WW3
export ESMFMKFILE=${MYDIR}/libs/3rdparty/local/lib/esmf.mk

#
# nceplibs
#
if [ $BUILD_NCEPLIBS == yes ]; then
SECONDS=0
printf '%-.30s ' "Building nceplibs .........................."
(
  cd libs/nceplibs
  ./build.sh ${COMPILER}
) > log_nceplibs 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


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

  cmake .. -DCMAKE_PREFIX_PATH="${MYDIR}/libs/3rdparty/local;${MYDIR}/libs/nceplibs/local" \
           -DCMAKE_C_COMPILER=${MPICC} \
           -DCMAKE_Fortran_COMPILER=${MPIF90} \
           -DNetCDF_PATH="${MYDIR}/libs/3rdparty/local" \
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
  export CMAKE_C_COMPILER=${MPICC}
  export CMAKE_CXX_COMPILER=${MPICXX}
  export CMAKE_Fortran_COMPILER=${MPIF90}

  cd ${MYDIR}/src/model

  rm -rf build
  mkdir build
  cd build
  cmake .. -DAPP=ATM \
           -DCCPP_SUITES="FV3_GFS_v15p2_no_nsst,FV3_GFS_2017_gfdlmp_regional" \
           -D32BIT=ON \
           -DINLINE_POST=ON \
           -DPARALLEL_NETCDF=ON \
           -DNETCDF_DIR=${NETCDF} \
           -DCMAKE_PREFIX_PATH="${MYDIR}/libs/3rdparty/local;${MYDIR}/libs/nceplibs/local" \
           -DCMAKE_INSTALL_PREFIX=install

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

  cmake .. -DCMAKE_PREFIX_PATH="${MYDIR}/libs/3rdparty/local;${MYDIR}/libs/nceplibs/local" \
           -DCMAKE_Fortran_COMPILER=${MPIF90}

  make -j8
  cp sorc/ncep_post.fd/upp.x ${MYDIR}/bin/ufs_post

) > log_post 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi

echo "Done!"
