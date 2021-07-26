#!/bin/bash

## Yet another simple script that downloads and builds
## nceplibs libraries required for the UFS Weather application.
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
  export MPICC=${MPICC:-mpicc}
  export MPICXX=${MPICXX:-mpicxx}
  export MPIF90=${MPIF90:-mpif90}
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

if [[ $fetch_only == off ]]; then
  echo
  echo "Building nceplibs libraries using ${COMPILERS} compilers"
  echo
  #
  # print compiler version
  #
  ${CC} --version | head -1
  ${CXX} --version | head -1
  ${FC} --version | head -1
  mpiexec --version
  cmake --version | head -1
  echo
else
  echo
  echo "Fetching nceplibs libraries"
  echo
fi

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

IFS=""

ALL_LIBS=(
" bacio        : NOAA-EMC/NCEPLIBS-bacio       : develop "
" crtm         : NOAA-EMC/EMC_crtm             : develop "
" g2tmpl       : NOAA-EMC/NCEPLIBS-g2tmpl      : develop "
" gfsio        : NOAA-EMC/NCEPLIBS-gfsio       : develop "
" landsfcutil  : NOAA-EMC/NCEPLIBS-landsfcutil : develop "
" sfcio        : NOAA-EMC/NCEPLIBS-sfcio       : develop "
" sigio        : NOAA-EMC/NCEPLIBS-sigio       : develop "
" sp           : NOAA-EMC/NCEPLIBS-sp          : develop "
" w3nco        : NOAA-EMC/NCEPLIBS-w3nco       : develop "

" g2           : NOAA-EMC/NCEPLIBS-g2          : develop "
" ip           : NOAA-EMC/NCEPLIBS-ip          : v3.3.3  "
" ip2          : NOAA-EMC/NCEPLIBS-ip2         : develop "
" nemsio       : NOAA-EMC/NCEPLIBS-nemsio      : develop "

" nemsiogfs    : NOAA-EMC/NCEPLIBS-nemsiogfs   : develop "
" w3emc        : NOAA-EMC/NCEPLIBS-w3emc       : develop "

" wgrib2       : NOAA-EMC/NCEPLIBS-wgrib2      : feature/cmake "
" upp          : NOAA-EMC/EMC_post             : develop "
)

for lib in ${ALL_LIBS[*]}; do

  lib_name=$( echo $lib | awk -F: '{ print $1 }' | tr -d '[:space:]' )
  repo_url=$( echo $lib | awk -F: '{ print $2 }' | tr -d '[:space:]' )
  tag=$(      echo $lib | awk -F: '{ print $3 }' | tr -d '[:space:]' )

  repo=$( basename ${repo_url} )

  if [[ ! -d ${repo} ]]; then
	printf '%-.30s ' "Cloning  ${lib_name} ..........................."
	(
	  cd ${MYDIR}
      rm -rf ${repo}-cloning
	  git clone --recursive --branch ${tag} https://github.com/${repo_url} ${repo}-cloning
      mv ${repo}-cloning ${repo}
	) > ${lib_name}_clone.log 2>&1
	echo 'done'
  fi

  [[ $fetch_only == on ]] && continue

  SECONDS=0
  printf '%-.30s ' "Building ${lib_name} ..........................."
  (
    set -x
    cd ${MYDIR}/${repo}

    if [[ -f VERSION ]]; then
      version=$(head -1 VERSION)
    else
      version="0.0.0"
    fi
    install_name="${lib_name}_${version}"

    install_root=${MYDIR}/local
    install_prefix=${install_root}/${install_name}

    mkdir -p ${MYDIR}/local/modulefiles/${lib_name}
    modulefile=${MYDIR}/local/modulefiles/${lib_name}/${version}
    echo "#%Module"                                                       >  ${modulefile}
    echo "setenv ${lib_name}_VERSION ${version}"                          >> ${modulefile}
    echo "setenv ${lib_name}_DIR ${install_prefix}/lib/cmake/${lib_name}" >> ${modulefile}

    # for backward compatibility with WW3
    if [[ ${lib_name} == bacio || ${lib_name} == g2 || ${lib_name} == w3nco ]]; then
      lib_name_uc=$( echo "${lib_name}" | tr '/a-z/' '/A-Z/' )
      echo "setenv ${lib_name_uc}_LIB4 ${install_prefix}/lib/lib${lib_name}_v${version}_4.a" >> ${modulefile}
    fi

    rm -rf build
    mkdir build
    cd build
    rm -rf ${MYDIR}/local/${install_name}

    cmake .. \
          -DCMAKE_INSTALL_PREFIX=${install_prefix} \
          -DCMAKE_C_COMPILER=${MPICC} \
          -DCMAKE_Fortran_COMPILER=${MPIF90} \
          -DCMAKE_BUILD_TYPE=RELEASE \
          -DCMAKE_PREFIX_PATH="${MYDIR}/../3rdparty/local;${install_root}"

    make -j ${BUILD_JOBS} VERBOSE=1
    make install

  ) > ${lib_name}_build.log 2>&1
  printf 'done [%4d sec]\n' ${SECONDS}
done

echo
date

echo
echo "Finished"
