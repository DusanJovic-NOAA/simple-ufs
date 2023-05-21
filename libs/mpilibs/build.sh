#!/bin/bash

## Yet another simple script that downloads and builds
## MPI (MPICH and OpenMPI) libraries
##      -Dusan Jovic Oct. 2019

set -eu
set -o pipefail

usage() {
  echo "Usage: $0 gnu | intel [-all] [-mpich] [-openmpi]"
  exit 1
}

[[ $# -ne 2 ]] && usage

COMPILER=$1
shift

if [[ $COMPILER == gnu ]]; then
  export CC=${CC:-gcc}
  export CXX=${CXX:-g++}
  export FC=${FC:-gfortran}
  gcc_ver=$( gcc -dumpfullversion )
  if [[ ${gcc_ver%%.*} -ge 10 ]]; then
    export FFLAGS="-fallow-argument-mismatch ${FFLAGS:-}" # for gcc 10
    export FCFLAGS="-fallow-argument-mismatch ${FCFLAGS:-}" # for gcc 10
  fi
elif [[ $COMPILER == intel ]]; then
  export CC=${CC:-icc}
  export CXX=${CXX:-icpc}
  export FC=${FC:-ifort}
else
  usage
fi

export CFLAGS="-fPIC ${CFLAGS:-}"
export FFLAGS="-fPIC ${FFLAGS:-}"
export FCFLAGS="-fPIC ${FCFLAGS:-}"

BUILD_MPICH=no
BUILD_OPENMPI=no

while [[ $# -gt 0 ]]; do
opt=$1

case $opt in
  -all)
    BUILD_MPICH=yes
    BUILD_OPENMPI=yes
    shift
    ;;
  -mpich)
    BUILD_MPICH=yes
    shift
    ;;
  -openmpi)
    BUILD_OPENMPI=yes
    shift
    ;;
  *)
    echo "unknown option ${opt}"
    usage
esac
done

date

echo
echo "Building MPI libraries using ${COMPILER} compilers"
echo

MAX_BUILD_JOBS=${MAX_BUILD_JOBS:-4}

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

MPICH=mpich-3.3.2
MPICH_MD5SUM=2d680f620583beadd7a08acdcfe355e6

# MPICH=mpich-4.1.1
# MPICH_MD5SUM=bd0ecf550e4a3e54128f377b65743370

OPENMPI=openmpi-4.1.2
OPENMPI_MD5SUM=2f86dc37b7a00b96ca964637ee68826e

[ $BUILD_MPICH   == yes ] && download_and_check_md5sum ${MPICH_MD5SUM}   https://www.mpich.org/static/downloads/${MPICH:6}/${MPICH}.tar.gz
[ $BUILD_OPENMPI == yes ] && download_and_check_md5sum ${OPENMPI_MD5SUM} https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.2.tar.gz

#
# print compiler version
#
echo
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
echo

NPROC=$(nproc --all)
BUILD_JOBS=$(( NPROC < MAX_BUILD_JOBS ? NPROC : MAX_BUILD_JOBS ))


###
### MPICH
###
if [ $BUILD_MPICH == yes ]; then
printf '%-.30s ' 'Building mpich ..........................'
(
  set -x
  cd ${SRC_PATH}
  rm -rf ${MPICH} mpich
  tar -zxf ${MPICH}.tar.gz
  cd ${MPICH}
  ./configure --prefix=${PREFIX_PATH}/mpich \
              --enable-fc \
              --enable-static \
              --disable-shared
  make -j ${BUILD_JOBS}
  make install
  rm -rf ${SRC_PATH:?}/${MPICH}
) > log_mpich 2>&1
echo 'done'
fi


###
### OPENMPI
###
if [ $BUILD_OPENMPI == yes ]; then
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
  rm -rf ${SRC_PATH:?}/${OPENMPI}
) > log_openmpi 2>&1
echo 'done'
fi

echo
date

echo
echo "Finished"
