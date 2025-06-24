#!/bin/bash
set -u
set -o pipefail

usage() {
  echo "Usage: $0 gnu | intel | intel_llvm [-all] [-ufslibs] [-preproc] [-model] [-post]"
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
    export MPICC=${MPICC:-mpiicc}
    export MPICXX=${MPICXX:-mpiicpc}
    export MPIF90=${MPIF90:-mpiifort}
  fi
elif [[ $COMPILER == intel_llvm ]]; then
  export CC=${CC:-icx}
  export CXX=${CXX:-icpx}
  export FC=${FC:-ifx}
  export MPICC=${MPICC:-mpiicx}
  export MPICXX=${MPICXX:-mpiicpx}
  export MPIF90=${MPIF90:-mpiifx}
  export I_MPI_CC=${CC}
  export I_MPI_CXX=${CXX}
  export I_MPI_F90=${FC}
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

MYDIR=$(dirname "$(realpath "$0")")
readonly MYDIR

export OMPI_CC=${CC}
export OMPI_CXX=${CXX}
export OMPI_FC=${FC}

# print compiler version
echo
echo "CC = ${CC}"
echo "CXX = ${CXX}"
echo "FC = ${FC}"
which ${CC}
which ${CXX}
which ${FC}
${CC} --version | head -1
${CXX} --version | head -1
${FC} --version | head -1
echo
echo "MPICC = ${MPICC}"
echo "MPICXX = ${MPICXX}"
echo "MPIF90 = ${MPIF90}"
which ${MPICC}
which ${MPICXX}
which ${MPIF90}
${MPICC} --version | head -1
${MPICXX} --version | head -1
${MPIF90} --version | head -1
echo
cmake --version | head -1
echo

#
# ufslibs
#
if [ $BUILD_UFSLIBS == yes ]; then
SECONDS=0
printf '%-.30s ' "Building ufslibs .........................."
(
  cd libs

  rm -rf build install
  mkdir build
  cd build

  cmake .. -DCMAKE_INSTALL_PREFIX=../install

  make -j 8

) > log_ufslibs 2>&1
status=$?
  if [ $status -eq 0 ]; then
printf 'done [%4d sec]\n' ${SECONDS}
  else
    printf 'FAILED [%4d sec]\n' ${SECONDS}
    echo
    echo "---------------------------------------------------------------"
    echo "--- log_ufslibs"
    cat log_ufslibs
    echo "---------------------------------------------------------------"
    for f in libs/ufslibs/build/*-prefix/src/*-stamp/*-*-*.log; do
      echo
      echo "---------------------------------------------------------------"
      echo "--- $f"
      cat $f
      echo "---------------------------------------------------------------"
    done
    exit 1
  fi
fi

export CC=${MPICC}
export CXX=${MPICXX}
export FC=${MPIF90}

ufslibs_install_prefix=${MYDIR}/libs/install

export ZLIB_ROOT=${ufslibs_install_prefix}/zlib
export PNG_ROOT=${ufslibs_install_prefix}/libpng
export NetCDF_ROOT=${ufslibs_install_prefix}/netcdf
export PIO_ROOT=${ufslibs_install_prefix}/pio

export ESMFMKFILE=${ufslibs_install_prefix}/esmf/lib/esmf.mk
export ESMF_ROOT=${ufslibs_install_prefix}/esmf
export FMS_ROOT=${ufslibs_install_prefix}/fms

export bacio_ROOT=${ufslibs_install_prefix}/bacio
export g2_ROOT=${ufslibs_install_prefix}/g2
export g2tmpl_ROOT=${ufslibs_install_prefix}/g2tmpl
export ip_ROOT=${ufslibs_install_prefix}/ip
export sp_ROOT=${ufslibs_install_prefix}/sp
export w3emc_ROOT=${ufslibs_install_prefix}/w3emc

export crtm_ROOT=${ufslibs_install_prefix}/crtm/cmake/crtm

export GFTL_ROOT=${ufslibs_install_prefix}/gftl
export GFTL_SHARED_ROOT=${ufslibs_install_prefix}/gftl_shared
export MAPL_ROOT=${ufslibs_install_prefix}/mapl

export SCOTCH_ROOT=${ufslibs_install_prefix}/scotch

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

  cmake .. -DCMAKE_INSTALL_PREFIX="${MYDIR}" -DBUILD_TESTING=OFF -DGBLEVENTS=OFF

  make -j 8
  make install

) > log_preproc 2>&1
status=$?
  if [ $status -eq 0 ]; then
printf 'done [%4d sec]\n' ${SECONDS}
  else
    printf 'FAILED [%4d sec]\n' ${SECONDS}
    cat log_preproc
    exit 1
  fi
fi

#
# model
#
if [ $BUILD_MODEL == yes ]; then
SECONDS=0
printf '%-.30s ' "Building model ..........................."
(
  cd src/model
  sed -i -e 's/crtm::crtm/crtm/g' FV3/upp/sorc/ncep_post.fd/CMakeLists.txt

  rm -rf build
  mkdir build
  cd build

  cmake .. -DAPP=ATM \
           -DCCPP_SUITES="FV3_GFS_v16" \
           -D32BIT=ON \
           -DINLINE_POST=ON \
           -DPARALLEL_NETCDF=ON \
           -DCMAKE_INSTALL_PREFIX=install

  # cmake .. -DAPP=S2S \
  #          -DCCPP_SUITES="FV3_GFS_v16_coupled" \
  #          -DCMAKE_INSTALL_PREFIX=install

  # cmake .. -DAPP=ATMAERO \
  #          -DCCPP_SUITES="FV3_GFS_v16" \
  #          -DCMAKE_INSTALL_PREFIX=install

  # cmake .. -DAPP=S2SWA \
  #          -DCCPP_SUITES="FV3_GFS_v17_coupled_p8_ugwpv1" \
  #          -D32BIT=ON \
  #          -DPDLIB=ON \
  #          -DCMAKE_INSTALL_PREFIX=install

  make -j 8
  make install

  cp ufs_model ${MYDIR}/bin/ufs_model

) > log_model 2>&1
status=$?
  if [ $status -eq 0 ]; then
printf 'done [%4d sec]\n' ${SECONDS}
  else
    printf 'FAILED [%4d sec]\n' ${SECONDS}
    cat log_model
    exit 1
  fi
fi

#
# post
#
if [ $BUILD_POST == yes ]; then
SECONDS=0
printf '%-.30s ' "Building post ..........................."
(
  cd src/model/FV3/upp

  rm -rf build
  mkdir build
  cd build

  cmake .. -DBUILD_WITH_NEMSIO=OFF

  make -j 8

  cp sorc/ncep_post.fd/upp.x ${MYDIR}/bin/ufs_post

) > log_post 2>&1
status=$?
  if [ $status -eq 0 ]; then
printf 'done [%4d sec]\n' ${SECONDS}
  else
    printf 'FAILED [%4d sec]\n' ${SECONDS}
    cat log_post
    exit 1
  fi
fi

echo "Done!"
