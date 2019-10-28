#!/bin/bash
set -eu
set -o pipefail

usage() {
  echo "Usage: $0 gnu | intel | pgi"
  exit 1
}

[[ $# -ne 1 ]] && usage

COMPILER=$1

if [[ $COMPILER == gnu ]]; then
  export CC=gcc
  export CXX=g++
  export FC=gfortran
  export MPIF90=mpif90
  ESMF_COMPILER=gfortran
elif [[ $COMPILER == intel ]]; then
  export CC=icc
  export CXX=icpc
  export FC=ifort
  export MPIF90=mpif90
  ESMF_COMPILER=intel
elif [[ $COMPILER == pgi ]]; then
  echo "PGI is unsupported"
  exit 1
else
  usage
fi

MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

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

export MPICH_CC=${CC}
export MPICH_CXX=${CXX}
export MPICH_F90=${FC}
export OMPI_CC=${CC}
export OMPI_CXX=${CXX}
export OMPI_FC=${FC}

#
# 3rdparty
#
if true; then
(
  cd libs/3rdparty
  ./build.sh ${COMPILER}
)
fi

export PKG_CONFIG_PATH=${MYDIR}/libs/3rdparty/local/lib/pkgconfig
export HDF5=${MYDIR}/libs/3rdparty/local
export NETCDF=${MYDIR}/libs/3rdparty/local
export ESMFMKFILE=${MYDIR}/libs/3rdparty/local/esmf/lib/libO/Linux.${ESMF_COMPILER}.64.${MPI_IMPLEMENTATION}.default/esmf.mk

#
# nceplibs
#
if true; then
(
  cd libs/nceplibs
  ./build.sh ${COMPILER}
)
fi


#
# preproc
#
if true; then
(
  export target=linux.${COMPILER}
  export NCEPLIBS=${MYDIR}/libs/nceplibs/local

  cd src/preproc/sorc

  ./build_fre-nctools.sh
  ./build_orog.sh
  ./build_chgres.sh
  ./build_chgres_cube.sh

  cp ../exec/* ${MYDIR}/bin
)
fi

#
# model
#
if true; then
(
  mkdir -p src/model/modulefiles/linux.${COMPILER}
  cp src/patches/modulefiles_linux.${COMPILER}_fv3 src/model/modulefiles/linux.${COMPILER}/fv3
  cp src/patches/conf_configure.fv3.linux.${COMPILER} src/model/conf/configure.fv3.linux.${COMPILER}

  export NCEPLIBS_DIR=${MYDIR}/libs/nceplibs/local
  export NEMS_COMPILER=${COMPILER}
  export BUILD_ENV=linux.${COMPILER}
  export FC=${MPIF90}  # for ccpp cmake

  cd src/model/NEMS

  make -j 4 COMPONENTS="CCPP,FV3" FV3_MAKEOPT="DEBUG=N 32BIT=Y OPENMP=N CCPP=Y STATIC=Y SUITES=FV3_GFS_2017" build

  cp exe/NEMS.x ${MYDIR}/bin/ufs_model
)
fi

#
# post
#
if false; then
(
  echo "post is not ported yet!"

  #cd src/post/sorc/ncep_post.fd
  #make -f makefile_module
)
fi

echo "Done!"
