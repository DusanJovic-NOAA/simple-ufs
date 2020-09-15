#!/bin/bash

## Yet another simple script that downloads and builds
## third party (not under our control) libraries required
## for the UFS Weather application.
## Note that NCEP libraries are not considered third party.
## I guess they are second party (under our control).
##      -Dusan Jovic Oct. 2019

set -eu
set -o pipefail

usage() {
  echo "Usage: $0 gnu | intel | fetch"
  exit 1
}

[[ $# -ne 1 ]] && usage

COMPILERS=$1

function ver { printf "%d%02d%02d" $(echo "$1" | tr '.' ' '); }

fetch_only=off
if [[ $COMPILERS == gnu ]]; then
  export CC=${CC:-gcc}
  export CXX=${CXX:-g++}
  export FC=${FC:-gfortran}
  export MPICC=${MPICC:-mpicc}
  export MPICXX=${MPICXX:-mpicxx}
  export MPIF90=${MPIF90:-mpif90}
  gcc_ver=$( gcc -dumpfullversion )
  if [[ $(ver $gcc_ver ) -ge $(ver 10.0) ]]; then
    export FFLAGS="-fallow-argument-mismatch" # for gcc 10
  fi
elif [[ $COMPILERS == intel ]]; then
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
    export MPICC=${MPICC:-mpiicc}
    export MPICXX=${MPICXX:-mpiicpc}
    export MPIF90=${MPIF90:-mpiifort}
  fi
elif [[ $COMPILERS == fetch ]]; then
  fetch_only=on
else
  usage
fi

date

MAX_BUILD_JOBS=${MAX_BUILD_JOBS:-8}

OS=$(uname -s)
if [[ $OS == Darwin ]]; then
  NPROC=$(sysctl -n hw.logicalcpu)
else
  NPROC=$(nproc --all)
fi
BUILD_JOBS=$(( NPROC < MAX_BUILD_JOBS ? NPROC : MAX_BUILD_JOBS ))

INSTALL_ZLIB=on
INSTALL_JPEG=on
INSTALL_JASPER=on
INSTALL_LIBPNG=on

INSTALL_HDF5=on
INSTALL_NETCDF_C=on
INSTALL_NETCDF_FORTRAN=on

INSTALL_ESMF=on

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
PREFIX_PATH="${MYDIR}"/local
export PATH=${PREFIX_PATH/bin}:$PATH

SRC_PATH=${MYDIR}/src
mkdir -p ${SRC_PATH}
cd ${SRC_PATH}

download_and_check_md5sum()
{
  local -r HASH="$1"
  local -r URL="$2"
  local -r FILE="$(basename "$URL")"
  local -r OUT_FILE="${3:-$FILE}"

  local GREEN
  local RED
  local NC
  [[ -t 1 ]] && GREEN='\033[1;32m' || GREEN=''
  [[ -t 1 ]] && RED='\033[1;31m' || RED=''
  [[ -t 1 ]] && NC='\033[0m' || NC=''

  local MD5HASH=''
  if [[ -f "$OUT_FILE" ]]; then
    if [[ $OS == Darwin ]]; then
      MD5HASH=$(md5 "$OUT_FILE" 2>/dev/null | awk '{print $4}')
    else
      MD5HASH=$(md5sum "$OUT_FILE" 2>/dev/null | awk '{print $1}')
    fi
  fi
  if [[ "$MD5HASH" == "$HASH" ]]; then
    echo -e "$OUT_FILE ${GREEN}checksum OK${NC}"
  else
    rm -f "${OUT_FILE}"
    printf '%s' "Downloading $OUT_FILE "
    curl -f -k -s -S -R -L "$URL" -o "$OUT_FILE"
    if [[ -f "$OUT_FILE" ]]; then
      if [[ $OS == Darwin ]]; then
        MD5HASH=$(md5 "$OUT_FILE" 2>/dev/null | awk '{print $4}')
      else
        MD5HASH=$(md5sum "$OUT_FILE" 2>/dev/null | awk '{print $1}')
      fi
    fi
    if [[ "$MD5HASH" == "$HASH" ]]; then
      echo -e "${GREEN}checksum OK${NC}"
    else
      echo -e "${RED}incorrect checksum${NC}"
      exit 1
    fi
  fi
}

ZLIB=zlib-1.2.11
JPEG=jpeg-9c
JASPER=jasper-2.0.19
LIBPNG=libpng-1.6.35
HDF5=hdf5-1_12_0
NETCDF=netcdf-c-4.7.4
NETCDF_FORTRAN=netcdf-fortran-4.5.3
ESMF=ESMF_8_1_0_beta_snapshot_26

[ $INSTALL_ZLIB           == on ] && download_and_check_md5sum   0095d2d2d1f3442ce1318336637b695f   https://github.com/madler/zlib/archive/v${ZLIB:5}.tar.gz                       ${ZLIB}.tar.gz
[ $INSTALL_JPEG           == on ] && download_and_check_md5sum   93c62597eeef81a84d988bccbda1e990   http://www.ijg.org/files/jpegsrc.v9c.tar.gz ${JPEG}.tar.gz
[ $INSTALL_JASPER         == on ] && download_and_check_md5sum   165376c403c9ccfd115c23db4e7815ea   https://github.com/jasper-software/jasper/archive/version-${JASPER:7}.tar.gz   ${JASPER}.tar.gz
[ $INSTALL_LIBPNG         == on ] && download_and_check_md5sum   d703ed4913fcfb40021bd3d4d35e00b6   https://github.com/glennrp/libpng/archive/v${LIBPNG:7}.tar.gz                  ${LIBPNG}.tar.gz
[ $INSTALL_HDF5           == on ] && download_and_check_md5sum   7181d12d1940b725248046077a849f54   https://github.com/HDFGroup/hdf5/archive/hdf5-${HDF5:5}.tar.gz                 ${HDF5}.tar.gz
[ $INSTALL_NETCDF_C       == on ] && download_and_check_md5sum   33979e8f0cf4ee31323fc0934282111b   https://github.com/Unidata/netcdf-c/archive/v${NETCDF:9}.tar.gz                ${NETCDF}.tar.gz
[ $INSTALL_NETCDF_FORTRAN == on ] && download_and_check_md5sum   47bf6eed50bd50b23b7e391dc1f8b5c4   https://github.com/Unidata/netcdf-fortran/archive/v${NETCDF_FORTRAN:15}.tar.gz ${NETCDF_FORTRAN}.tar.gz
[ $INSTALL_ESMF           == on ] && download_and_check_md5sum   2e8279f8e3c207655b1572b2eb3ea206   https://github.com/esmf-org/esmf/archive/${ESMF}.tar.gz                        ${ESMF}.tar.gz

[ $fetch_only == on ] && exit

echo
echo "Building 3rdparty libraries using ${COMPILERS} compilers"
echo

export CFLAGS+=""
export CXXFLAGS+=""
export FFLAGS+=""
export CPPFLAGS+=" -I${PREFIX_PATH}/include"
export LDFLAGS+=" -L${PREFIX_PATH}/lib"

#
# print compiler version
#
echo
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
mpiexec --version
cmake --version
echo

###
### zlib
###
if [ $INSTALL_ZLIB == on ]; then
SECONDS=0
printf '%-.30s ' 'Building zlib ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${ZLIB}
  tar -zxf ${ZLIB}.tar.gz
  cd ${ZLIB}
  ./configure --prefix=${PREFIX_PATH} \
              --static
  make -j ${BUILD_JOBS}
  make check
  make install
  rm -rf ${SRC_PATH:?}/${ZLIB}
) > log_zlib 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


###
### jpeg
###
if [ $INSTALL_JPEG == on ]; then
SECONDS=0
printf '%-.30s ' 'Building jpeg ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${JPEG}
  tar -zxf ${JPEG}.tar.gz
  cd ${JPEG}
  ./configure --prefix=${PREFIX_PATH} \
              --disable-shared
  make
  make install
  rm -rf ${SRC_PATH:?}/${JPEG}
) > log_jpeg 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


###
### jasper
###
if [ $INSTALL_JASPER == on ]; then
SECONDS=0
printf '%-.30s ' 'Building jasper ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${JASPER}
  tar -zxf ${JASPER}.tar.gz
  mv jasper-version-${JASPER:7} ${JASPER}
  cd ${JASPER}
  mkdir bld && cd bld
  cmake .. -DCMAKE_INSTALL_PREFIX=${PREFIX_PATH} \
           -DCMAKE_BUILD_TYPE=Release \
           -DJAS_ENABLE_DOC=OFF \
           -DJAS_ENABLE_SHARED=OFF \
           -DJAS_ENABLE_AUTOMATIC_DEPENDENCIES=OFF \
           -DJAS_ENABLE_PROGRAMS=OFF \
           -DJAS_ENABLE_OPENGL=OFF \
           -DJAS_ENABLE_LIBJPEG=OFF \
           -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=ON
  make
  make install
  rm -rf ${SRC_PATH:?}/${JASPER}
) > log_jasper 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


###
### libpng
###
if [ $INSTALL_LIBPNG == on ]; then
SECONDS=0
printf '%-.30s ' 'Building libpng ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${LIBPNG}
  tar -zxf ${LIBPNG}.tar.gz
  cd ${LIBPNG}
  ./configure --prefix=${PREFIX_PATH} \
              --disable-shared
  make
  make install
  rm -rf ${SRC_PATH:?}/${LIBPNG}
) > log_libpng 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


###
### hdf5
###
if [ $INSTALL_HDF5 == on ]; then
SECONDS=0
printf '%-.30s ' 'Building hdf5 ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${HDF5}
  tar -zxf ${HDF5}.tar.gz
  mv hdf5-${HDF5} ${HDF5}
  cd ${HDF5}
  CC=${MPICC} \
  CFLAGS+=" -pthread" \
  ./configure --prefix=${PREFIX_PATH} \
              --disable-shared \
              --enable-static \
              --enable-static-exec \
              --enable-parallel \
              --enable-tests=no
  make -j ${BUILD_JOBS}
  #make check
  make install
  make check-install
  rm -rf ${SRC_PATH:?}/${HDF5}
) > log_hdf5 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


###
### netcdf
###
if [ $INSTALL_NETCDF_C == on ]; then
SECONDS=0
printf '%-.30s ' 'Building netcdf-c ...........................'
(
  export LIBS="-lhdf5_hl -lhdf5 -lm -lz -ldl"

  set -x
  cd ${SRC_PATH}
  rm -rf ${NETCDF}
  tar -zxf ${NETCDF}.tar.gz
  cd ${NETCDF}
  CC=${MPICC} \
  ./configure --prefix=${PREFIX_PATH} \
              --enable-cdf5 \
              --disable-dap \
              --enable-netcdf-4 \
              --disable-doxygen \
              --disable-shared \
              --enable-static \
              --disable-large-file-tests \
              --enable-parallel-tests
  make -j ${BUILD_JOBS}
  #make check
  make install
  rm -rf ${SRC_PATH:?}/${NETCDF}
) > log_netcdf 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


###
### NetCDF Fortran
###
if [ $INSTALL_NETCDF_FORTRAN == on ]; then
SECONDS=0
printf '%-.30s ' 'Building netcdf-fortran ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${NETCDF_FORTRAN}
  tar -zxf ${NETCDF_FORTRAN}.tar.gz
  cd ${NETCDF_FORTRAN}
  CC=${MPICC} \
  FC=${MPIF90} \
  LIBS="-lhdf5_hl -lhdf5 -lm -lz -ldl" \
  ./configure --prefix=${PREFIX_PATH} \
              --disable-shared \
              --enable-static
  make
  #make check
  make install
  rm -rf ${SRC_PATH:?}/${NETCDF_FORTRAN}
) > log_netcdf_fortran 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


###
### ESMF
###
if [ $INSTALL_ESMF == on ]; then
SECONDS=0
printf '%-.30s ' 'Building esmf ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf esmf-${ESMF}
  tar -zxf ${ESMF}.tar.gz
  cd esmf-${ESMF}
  export NETCDF=${PREFIX_PATH}
  export ESMF_DIR=$(pwd)
  export ESMF_BOPT=O

  export ESMF_MPIRUN=mpiexec

  MPI_IMPLEMENTATION=${MPI_IMPLEMENTATION:-mpich3}
  mpiexec --version | grep OpenRTE 2> /dev/null && MPI_IMPLEMENTATION=openmpi
  mpiexec --version | grep Intel 2> /dev/null && MPI_IMPLEMENTATION=intelmpi

  if [[ $(scripts/esmf_os) == Unicos ]]; then
    MPI_IMPLEMENTATION=mpi
  fi

  if [[ $COMPILERS == intel ]]; then
    export ESMF_COMPILER=intel
    export ESMF_COMM=${MPI_IMPLEMENTATION}
  elif [[ $COMPILERS == gnu ]]; then
    export ESMF_COMPILER=gfortran
    export ESMF_COMM=${MPI_IMPLEMENTATION}
  fi

  export ESMF_F90COMPILEOPTS="${FFLAGS:-}"
  export ESMF_CXXCOMPILEOPTS="${CXXFLAGS:-}"

  export ESMF_NFCONFIG=nf-config
  export ESMF_NETCDF_INCLUDE=$NETCDF/include
  export ESMF_NETCDF_LIBPATH=$NETCDF/lib
  export ESMF_NETCDF=split
  export ESMF_NETCDF_LIBS="-lnetcdff -lnetcdf -lhdf5_hl -lhdf5 -lm -lz -ldl"
  export ESMF_PIO=OFF

  export ESMF_SHARED_LIB_BUILD=OFF

  export ESMF_INSTALL_PREFIX=${PREFIX_PATH}
  export ESMF_INSTALL_HEADERDIR=${ESMF_INSTALL_PREFIX}/include
  export ESMF_INSTALL_MODDIR=${ESMF_INSTALL_PREFIX}/mod
  export ESMF_INSTALL_LIBDIR=${ESMF_INSTALL_PREFIX}/lib
  export ESMF_INSTALL_BINDIR=${ESMF_INSTALL_PREFIX}/bin

  make info > log_info 2>&1
  make -j ${BUILD_JOBS} > log_make 2>&1
  #make check > log_check 2>&1 # this takes forever
  make install > log_install 2>&1
  rm -rf ${SRC_PATH}/esmf
) > log_esmf 2>&1
printf 'done [%4d sec]\n' ${SECONDS}
fi


echo
date

echo
echo "Finished"
