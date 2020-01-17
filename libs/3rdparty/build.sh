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

fetch_only=off
if [[ $COMPILERS == gnu ]]; then
  export CC=${CC:-gcc}
  export CXX=${CXX:-g++}
  export FC=${FC:-gfortran}
elif [[ $COMPILERS == intel ]]; then
  export CC=${CC:-icc}
  export CXX=${CXX:-icpc}
  export FC=${FC:-ifort}
elif [[ $COMPILERS == fetch ]]; then
  fetch_only=on
else
  usage
fi

date

MAX_BUILD_JOBS=${MAX_BUILD_JOBS:-4}

INSTALL_ZLIB=on
INSTALL_JPEG=on
INSTALL_JASPER=on
INSTALL_LIBPNG=on

INSTALL_HDF5=on
INSTALL_NETCDF_C=on
INSTALL_NETCDF_FORTRAN=on

INSTALL_ESMF=on

INSTALL_WGRIB2=on

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
PREFIX_PATH="${MYDIR}"/local
export PATH=${PREFIX_PATH/bin}:$PATH

SRC_PATH=${MYDIR}/src
mkdir -p ${SRC_PATH}
cd ${SRC_PATH}

OS=$(uname -s)

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
    curl -f -s -S -R -L "$URL" -o "$OUT_FILE"
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
JASPER=jasper-1.900.16
LIBPNG=libpng-1.6.35
HDF5=hdf5-1.10.6
#HDF5=hdf5-1.8.21
NETCDF=netcdf-c-4.7.3
NETCDF_FORTRAN=netcdf-fortran-4.5.2
ESMF=esmf_8_0_0_src
WGRIB2=wgrib2-2.0.8

[ $INSTALL_ZLIB           == on ] && download_and_check_md5sum   1c9f62f0778697a09d36121ead88e08e   https://www.zlib.net/${ZLIB}.tar.gz
[ $INSTALL_JPEG           == on ] && download_and_check_md5sum   93c62597eeef81a84d988bccbda1e990   http://www.ijg.org/files/jpegsrc.v9c.tar.gz ${JPEG}.tar.gz
[ $INSTALL_JASPER         == on ] && download_and_check_md5sum   d0401ced2f5cc7aa1629696c5cba5980   http://www.ece.uvic.ca/~frodo/jasper/software/${JASPER}.tar.gz
[ $INSTALL_LIBPNG         == on ] && download_and_check_md5sum   d94d9587c421ac42316b6ab8f64f1b85   https://download.sourceforge.net/libpng/${LIBPNG}.tar.gz
[ $INSTALL_HDF5           == on ] && download_and_check_md5sum   37f3089e7487daf0890baf3d3328e54a   https://support.hdfgroup.org/ftp/HDF5/releases/${HDF5:0:9}/${HDF5}/src/${HDF5}.tar.gz
#[ $INSTALL_HDF5           == on ] && download_and_check_md5sum   15dbf8b2b466950e1c7be45b66317873   https://support.hdfgroup.org/ftp/HDF5/releases/${HDF5:0:8}/${HDF5}/src/${HDF5}.tar.gz
[ $INSTALL_NETCDF_C       == on ] && download_and_check_md5sum   9e1d7f13c2aef921c854d87037bcbd96   https://www.unidata.ucar.edu/downloads/netcdf/ftp/${NETCDF}.tar.gz
[ $INSTALL_NETCDF_FORTRAN == on ] && download_and_check_md5sum   864c6a5548b6f1e00579caf3cbbe98cc   https://www.unidata.ucar.edu/downloads/netcdf/ftp/${NETCDF_FORTRAN}.tar.gz
[ $INSTALL_ESMF           == on ] && download_and_check_md5sum   5cdb3814141068ef15420e7c2d2a158a   http://www.earthsystemmodeling.org/esmf_releases/public/ESMF_8_0_0/${ESMF}.tar.gz
[ $INSTALL_WGRIB2         == on ] && download_and_check_md5sum   3d56cbed5de8c460d304bf2206abc8d3   https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v2.0.8 wgrib2-2.0.8.tar.gz

[ $fetch_only == on ] && exit

echo
echo "Building 3rdparty libraries using ${COMPILERS} compilers"
echo

export CPPFLAGS=-I${PREFIX_PATH}/include
export LDFLAGS=-L${PREFIX_PATH}/lib

if [[ $OS == Darwin ]]; then
NPROC=$(sysctl -n hw.logicalcpu)
else
NPROC=$(nproc --all)
fi
BUILD_JOBS=$(( $NPROC < $MAX_BUILD_JOBS ? $NPROC : $MAX_BUILD_JOBS ))

#
# print compiler version
#
echo
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
mpiexec --version
echo

###
### zlib
###
if [ $INSTALL_ZLIB == on ]; then
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
  rm -rf ${SRC_PATH}/${ZLIB}
) > log_zlib 2>&1
echo 'done'
fi


###
### jpeg
###
if [ $INSTALL_JPEG == on ]; then
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
  rm -rf ${SRC_PATH}/${JPEG}
) > log_jpeg 2>&1
echo 'done'
fi


###
### jasper
###
if [ $INSTALL_JASPER == on ]; then
printf '%-.30s ' 'Building jasper ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${JASPER}
  tar -zxf ${JASPER}.tar.gz
  cd ${JASPER}
  sed -i -e 's/ -pedantic-errors//g' configure.ac
  sed -i -e 's/tmpnam(obj->pathname);/snprintf(obj->pathname, L_tmpnam, "%stmp.XXXXXXXXXX", P_tmpdir);/g' src/libjasper/base/jas_stream.c
  autoreconf -fiv
  ./configure --prefix=${PREFIX_PATH} \
              --disable-shared
  make
  make install
  rm -rf ${SRC_PATH}/${JASPER}
) > log_jasper 2>&1
echo 'done'
fi


###
### libpng
###
if [ $INSTALL_LIBPNG == on ]; then
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
  rm -rf ${SRC_PATH}/${LIBPNG}
) > log_libpng 2>&1
echo 'done'
fi


###
### hdf5
###
if [ $INSTALL_HDF5 == on ]; then
printf '%-.30s ' 'Building hdf5 ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${HDF5}
  tar -zxf ${HDF5}.tar.gz
  cd ${HDF5}
  ./configure --prefix=${PREFIX_PATH} \
              --enable-fortran \
              --enable-cxx \
              --disable-shared \
              --enable-static \
              --enable-static-exec
  make -j ${BUILD_JOBS}
  #make check
  make install
  make check-install
  rm -rf ${SRC_PATH}/${HDF5}
) > log_hdf5 2>&1
echo 'done'
fi


###
### netcdf
###
if [ $INSTALL_NETCDF_C == on ]; then
printf '%-.30s ' 'Building netcdf-c ...........................'
(
  export LIBS="-lhdf5_hl -lhdf5 -lm -lz -ldl"

  set -x
  cd ${SRC_PATH}
  rm -rf ${NETCDF}
  tar -zxf ${NETCDF}.tar.gz
  cd ${NETCDF}
  ./configure --prefix=${PREFIX_PATH} \
              --enable-cdf5 \
              --disable-dap \
              --enable-netcdf-4 \
              --disable-doxygen \
              --disable-shared \
              --disable-large-file-tests
  make -j ${BUILD_JOBS}
  #make check
  make install
  rm -rf ${SRC_PATH}/${NETCDF}
) > log_netcdf 2>&1
echo 'done'
fi


###
### NetCDF Fortran
###
if [ $INSTALL_NETCDF_FORTRAN == on ]; then
printf '%-.30s ' 'Building netcdf-fortran ...........................'
(
  export LIBS="-lhdf5_hl -lhdf5 -lm -lz -ldl"

  set -x
  cd ${SRC_PATH}
  rm -rf ${NETCDF_FORTRAN}
  tar -zxf ${NETCDF_FORTRAN}.tar.gz
  cd ${NETCDF_FORTRAN}
  ./configure --prefix=${PREFIX_PATH} \
             --disable-shared
  make
  #make check
  make install
  rm -rf ${SRC_PATH}/${NETCDF_FORTRAN}
) > log_netcdf_fortran 2>&1
echo 'done'
fi


###
### ESMF
###
if [ $INSTALL_ESMF == on ]; then
printf '%-.30s ' 'Building esmf ...........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf esmf
  tar -zxf ${ESMF}.tar.gz
  cd esmf
  export NETCDF=${PREFIX_PATH}
  export ESMF_DIR=$(pwd)
  export ESMF_BOPT=O

  export ESMF_MPIRUN=mpiexec

  MPI_IMPLEMENTATION=${MPI_IMPLEMENTATION:-mpich3}
  mpiexec --version | grep OpenRTE 2> /dev/null && MPI_IMPLEMENTATION=openmpi
  mpiexec --version | grep Intel 2> /dev/null && MPI_IMPLEMENTATION=intelmpi

  if [[ $COMPILERS == intel ]]; then
    export ESMF_COMPILER=intel
    export ESMF_COMM=${MPI_IMPLEMENTATION}
  elif [[ $COMPILERS == gnu ]]; then
    export ESMF_COMPILER=gfortran
    export ESMF_COMM=${MPI_IMPLEMENTATION}
  elif [[ $COMPILERS == pgi ]]; then
    export ESMF_COMPILER=pgi
    export ESMF_COMM=${MPI_IMPLEMENTATION}
    sed -i 's/pgf90rc/pgf90llvmrc/g' scripts/version.pgf90
  fi

  export ESMF_NFCONFIG=nf-config
  export ESMF_NETCDF_INCLUDE=$NETCDF/include
  export ESMF_NETCDF_LIBPATH=$NETCDF/lib
  export ESMF_NETCDF=split
  export ESMF_NETCDF_LIBS="-lnetcdff -lnetcdf -lhdf5_hl -lhdf5 -lm -lz -ldl"
  export ESMF_SHARED_LIB_BUILD=OFF

  export ESMF_INSTALL_PREFIX=${PREFIX_PATH}/esmf

  make info > log_info 2>&1
  make -j ${BUILD_JOBS} > log_make 2>&1
  #make check > log_check 2>&1 # this takes forever
  make install > log_install 2>&1
  rm -rf ${SRC_PATH}/esmf
) > log_esmf 2>&1
echo 'done'
fi


###
### wgrib2
###
if [ $INSTALL_WGRIB2 == on ]; then
printf '%-.30s ' 'Building wgrib2 .........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${WGRIB2}
  tar -zxf ${WGRIB2}.tar.gz && mv grib2 ${WGRIB2}
  mkdir -p ${PREFIX_PATH}/wgrib2/{include,lib}

  cd ${WGRIB2}
  sed -i -e 's/^USE_NETCDF3=1/USE_NETCDF3=0/g' makefile
  sed -i -e 's/^USE_IPOLATES=3/USE_IPOLATES=0/g' makefile
  sed -i -e 's/^USE_OPENMP=1/USE_OPENMP=0/g' makefile
  sed -i -e 's/^USE_AEC=1/USE_AEC=0/g' makefile

  export COMP_SYS=${COMPILERS}_linux

  make lib

  # install
  cp lib/*.mod       ${PREFIX_PATH}/wgrib2/include
  cp lib/libwgrib2.a ${PREFIX_PATH}/wgrib2/lib

) > log_wgrib2 2>&1
echo 'done'
fi

echo
date

echo
echo "Finished"
