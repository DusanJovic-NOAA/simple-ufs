#!/bin/bash
set -eu
set -o pipefail

usage() {
  echo "Usage: $0 gnu|intel|pgi [-all] [-3rdparty] [-nceplibs] [-preproc] [-model] [-post]"
  exit 1
}

[[ $# -lt 2 ]] && usage

COMPILER=$1
shift

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
echo

export MPICH_CC=${CC}
export MPICH_CXX=${CXX}
export MPICH_F90=${FC}
export OMPI_CC=${CC}
export OMPI_CXX=${CXX}
export OMPI_FC=${FC}

#
# 3rdparty
#
if [ $BUILD_3RDPARTY == yes ]; then
(
  cd libs/3rdparty
  ./build.sh ${COMPILER}
) > log_3rdpaty 2>&1
echo 'done'
fi

export PKG_CONFIG_PATH=${MYDIR}/libs/3rdparty/local/lib/pkgconfig
export HDF5=${MYDIR}/libs/3rdparty/local
export NETCDF=${MYDIR}/libs/3rdparty/local
export ESMFMKFILE=${MYDIR}/libs/3rdparty/local/esmf/lib/libO/Linux.${ESMF_COMPILER}.64.${MPI_IMPLEMENTATION}.default/esmf.mk

#
# nceplibs
#
if [ $BUILD_NCEPLIBS == yes ]; then
(
  cd libs/nceplibs
  ./build.sh ${COMPILER}
) > log_nceplibs 2>&1
echo 'done'
fi


#
# preproc
#
if [ $BUILD_PREPROC == yes ]; then
printf '%-.30s ' "Building preproc ..........................."
(
  export target=linux.${COMPILER}
  export NCEPLIBS=${MYDIR}/libs/nceplibs/local

  cd src/preproc/sorc

  ./build_fre-nctools.sh
  ./build_orog.sh
  ./build_chgres.sh
  ./build_chgres_cube.sh

  (
     cd ./sfc_climo_gen.fd
     export FCOMP=${MPIF90}
     if [[ $COMPILER == gnu ]]; then
       export FFLAGS="-O3 -g -fdefault-real-8"
     elif [[ $COMPILER == intel ]]; then
       export FFLAGS="-O3 -g -r8"
     fi
     make clean
     make
     make install
  )

  cp ../exec/* ${MYDIR}/bin
) > log_preproc 2>&1
echo 'done'
fi

#
# model
#
if [ $BUILD_MODEL == yes ]; then
printf '%-.30s ' "Building model ..........................."
(
  # gmake build
  # -----------
  # mkdir -p src/model/modulefiles/linux.${COMPILER}
  # cp src/patches/modulefiles_linux.${COMPILER}_fv3 src/model/modulefiles/linux.${COMPILER}/fv3
  # cp src/patches/conf_configure.fv3.linux.${COMPILER} src/model/conf/configure.fv3.linux.${COMPILER}

  # export NCEPLIBS_DIR=${MYDIR}/libs/nceplibs/local
  # export NEMS_COMPILER=${COMPILER}
  # export BUILD_ENV=linux.${COMPILER}
  # export FC=${MPIF90}  # for ccpp cmake

  # cd src/model/NEMS
  # make -j 4 COMPONENTS="CCPP,FV3" FV3_MAKEOPT="DEBUG=N 32BIT=Y OPENMP=N CCPP=Y STATIC=Y SUITES=FV3_GFS_2017" build
  # cp exe/NEMS.x ${MYDIR}/bin/ufs_model


  # cmake build
  # -----------
  export CMAKE_Platform=linux.${COMPILER}
  export CMAKE_C_COMPILER=mpicc
  export CMAKE_CXX_COMPILER=mpicxx
  export CMAKE_Fortran_COMPILER=mpif90

  export NCEPLIBS_DIR=${MYDIR}/libs/nceplibs/local

  export BACIO_LIB4=${NCEPLIBS_DIR}/bacio/lib/libbacio_v2.1.0_4.a
  export NEMSIO_INC=${NCEPLIBS_DIR}/nemsio/include
  export NEMSIO_LIB=${NCEPLIBS_DIR}/nemsio/lib/libnemsio_v2.2.3.a
  export SP_LIBd=${NCEPLIBS_DIR}/sp/lib/libsp_v2.0.2_d.a
  export W3EMC_LIBd=${NCEPLIBS_DIR}/w3emc/lib/libw3emc_v2.2.0_d.a
  export W3NCO_LIBd=${NCEPLIBS_DIR}/w3nco/lib/libw3nco_v2.0.6_d.a

  BUILD_DIR=${MYDIR}/src/model/build
  rm -rf ${BUILD_DIR}
  mkdir ${BUILD_DIR}

  CCPP_SUITES="FV3_GFS_2017,FV3_GFS_2017_gfdlmp,FV3_GFS_2017_gfdlmp_regional"

  (
    cd src/model
    ./FV3/ccpp/framework/scripts/ccpp_prebuild.py \
            --config=FV3/ccpp/config/ccpp_prebuild_config.py \
            --static --suites=${CCPP_SUITES} \
            --builddir=${BUILD_DIR}/FV3
  )
  source ${BUILD_DIR}/FV3/ccpp/physics/CCPP_SCHEMES.sh
  source ${BUILD_DIR}/FV3/ccpp/physics/CCPP_CAPS.sh
  source ${BUILD_DIR}/FV3/ccpp/physics/CCPP_STATIC_API.sh

  cd ${BUILD_DIR}
  cmake .. -D32BIT=Y -DOPENMP=N -DCCPP=Y -DSTATIC=Y -DSUITES=${CCPP_SUITES} -DNETCDF_DIR=${NETCDF}
  make -j 4
  cp NEMS.exe ${MYDIR}/bin/ufs_model
) > log_model 2>&1
echo 'done'
fi

#
# post
#
if [ $BUILD_POST == yes ]; then
printf '%-.30s ' "Building post ..........................."
(
  echo "post is not ported yet!"

  #cd src/post/sorc/ncep_post.fd
  #make -f makefile_module
) > log_post 2>&1
echo 'done'
fi

echo "Done!"
