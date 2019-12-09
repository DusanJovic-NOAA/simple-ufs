#!/bin/bash

## Yet another simple script that downloads and builds
## MPI (MPICH and OpenMPI) libraries
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
echo "Building MPI libraries using ${COMPILERS} compilers"
echo

MAX_BUILD_JOBS=${MAX_BUILD_JOBS:-4}

INSTALL_MPICH=on
INSTALL_OPENMPI=on

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
PREFIX_PATH="$(readlink -f "${MYDIR}"/local)"
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
    MD5HASH=$(md5sum "$OUT_FILE" 2>/dev/null | awk '{print $1}')
  fi
  if [[ "$MD5HASH" == "$HASH" ]]; then
    echo -e "$OUT_FILE ${GREEN}checksum OK${NC}"
  else
    rm -f "${OUT_FILE}"
    printf '%s' "Downloading $OUT_FILE "
    curl -f -s -S -R -L "$URL" -o "$OUT_FILE"
    if [[ -f "$OUT_FILE" ]]; then
      MD5HASH=$(md5sum "$OUT_FILE" 2>/dev/null | awk '{print $1}')
    fi
    if [[ "$MD5HASH" == "$HASH" ]]; then
      echo -e "${GREEN}checksum OK${NC}"
    else
      echo -e "${RED}incorrect checksum${NC}"
      exit 1
    fi
  fi
}

MPICH=mpich-3.3.1
OPENMPI=openmpi-4.0.2

[ $INSTALL_MPICH          == on ] && download_and_check_md5sum   9ed4cabd3fb86525427454381b25f6af   https://www.mpich.org/static/downloads/${MPICH:6:12}/${MPICH}.tar.gz
[ $INSTALL_OPENMPI        == on ] && download_and_check_md5sum   d712bcc68a5a0bcce76b39843ed48158   https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.2.tar.gz

#
# print compiler version
#
echo
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
echo

NPROC=$(nproc --all)
BUILD_JOBS=$(( $NPROC < $MAX_BUILD_JOBS ? $NPROC : $MAX_BUILD_JOBS ))


###
### MPICH
###
if [ $INSTALL_MPICH == on ]; then
printf '%-.30s ' 'Building mpich ..........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${MPICH} mpich
  tar -zxf ${MPICH}.tar.gz
  cd ${MPICH}
  ./configure --prefix=${PREFIX_PATH}/mpich3 \
              --enable-fc \
              --enable-static \
              --disable-shared
  make -j ${BUILD_JOBS}
  make install
  rm -rf ${SRC_PATH}/${MPICH}
) > log_mpich 2>&1
echo 'done'
fi


###
### OPENMPI
###
if [ $INSTALL_OPENMPI == on ]; then
printf '%-.30s ' 'Building openmpi ........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${OPENMPI} openmpi
  tar -zxf ${OPENMPI}.tar.gz
  cd ${OPENMPI}
  ./configure --prefix=${PREFIX_PATH}/openmpi \
              --enable-static \
              --disable-shared \
              --disable-oshmem
  make -j ${BUILD_JOBS}
  make install
  rm -rf ${SRC_PATH}/${OPENMPI}
) > log_openmpi 2>&1
echo 'done'
fi

echo
date

echo
echo "Finished"
