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

OS=$(uname -s)
ESMF_OS=${OS}

if [[ $COMPILER == gnu ]]; then
  export CC=${CC:-gcc}
  export CXX=${CXX:-g++}
  export FC=${FC:-gfortran}
  export MPICC=${MPICC:-mpicc}
  export MPICXX=${MPICXX:-mpicxx}
  export MPIF90=${MPIF90:-mpif90}
  ESMF_COMPILER=gfortran
elif [[ $COMPILER == intel ]]; then
  if [[ $(type ftn &> /dev/null) ]]; then
    # Special case on Cray systems
    export CC=${CC:-cc}
    export CXX=${CXX:-CC}
    export FC=${FC:-ftn}
    export MPICC=${MPICC:-cc}
    export MPICXX=${MPICXX:-CC}
    export MPIF90=${MPIF90:-ftn}
    ESMF_OS=Unicos
    MPI_IMPLEMENTATION=mpi
  else
    export CC=${CC:-icc}
    export CXX=${CXX:-icpc}
    export FC=${FC:-ifort}
    export MPICC=${MPICC:-mpicc}
    export MPICXX=${MPICXX:-mpicxx}
    export MPIF90=${MPIF90:-mpif90}
  fi
  ESMF_COMPILER=intel
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

OS=$(uname -s)

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
printf '%-.30s ' "Building 3rdparty .........................."
(
  cd libs/3rdparty
  ./build.sh ${COMPILER}
) > log_3rdparty 2>&1
echo 'done'
fi

export HDF5=${MYDIR}/libs/3rdparty/local
export NETCDF=${MYDIR}/libs/3rdparty/local
export ESMFMKFILE=${MYDIR}/libs/3rdparty/local/lib/esmf.mk

#
# nceplibs
#
if [ $BUILD_NCEPLIBS == yes ]; then
printf '%-.30s ' "Building nceplibs .........................."
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

  #(
  #  cd src/preproc/sorc
  #  ./build_fre-nctools.sh
  #  ./build_orog.sh
  #  ./build_chgres.sh
  #  ./build_chgres_cube.sh
  #  ./build_sfc_climo_gen.sh
  #  cp ../exec/* ${MYDIR}/bin/
  #)

  #(
  #  export IP_INCd=${NCEPLIBS}/include_d
  #  export NEMSIO_INC=${NCEPLIBS}/include
  #  export SFCIO_INC4=${NCEPLIBS}/include_4
  #  export SIGIO_INC4=${NCEPLIBS}/include_4

  #  export BACIO_LIB4=${NCEPLIBS}/lib/libbacio_v2.1.0_4.a
  #  export IP_LIBd=${NCEPLIBS}/lib/libip_v3.0.0_d.a
  #  export NEMSIO_LIB=${NCEPLIBS}/lib/libnemsio_v2.2.3.a
  #  export SFCIO_LIB4=${NCEPLIBS}/lib/libsfcio_v1.1.0_4.a
  #  export SIGIO_LIB4=${NCEPLIBS}/lib/libsigio_v2.1.0_4.a
  #  export SP_LIBd=${NCEPLIBS}/lib/libsp_v2.0.2_d.a
  #  export W3NCO_LIBd=${NCEPLIBS}/lib/libw3nco_v2.0.6_d.a

  #  export WGRIB2_DIR=${MYDIR}/libs/3rdparty/local

  #  export WGRIB2API_INC=${WGRIB2_DIR}/include
  #  export WGRIB2_LIB=${WGRIB2_DIR}/lib/libwgrib2.a

  #  cd src/preproc/sorc
  #  ./build_chgres_cube.sh
  #  cp ../exec/chgres_cube.exe ${MYDIR}/bin/chgres_cube_grib2.exe
  #)

  (
    cd src/preproc

    rm -rf build
    mkdir build
    cd build

    export NCEPLIBS_DIR=${MYDIR}/libs/nceplibs/local

    export BACIO_LIB4=${NCEPLIBS_DIR}/lib/libbacio_v2.1.0_4.a

    export NEMSIO_INC=${NCEPLIBS_DIR}/include
    export NEMSIO_LIB=${NCEPLIBS_DIR}/lib/libnemsio_v2.2.3.a

    export SFCIO_INC4=${NCEPLIBS_DIR}/include_4
    export SFCIO_LIB4=${NCEPLIBS_DIR}/lib/libsfcio_v1.1.0_4.a

    export SIGIO_INC4=${NCEPLIBS_DIR}/include_4
    export SIGIO_LIB4=${NCEPLIBS_DIR}/lib/libsigio_v2.1.0_4.a

    export SP_LIB4=${NCEPLIBS_DIR}/lib/libsp_v2.0.2_4.a
    export SP_LIBd=${NCEPLIBS_DIR}/lib/libsp_v2.0.2_d.a

    export W3NCO_LIB4=${NCEPLIBS_DIR}/lib/libw3nco_v2.0.6_4.a
    export W3NCO_LIBd=${NCEPLIBS_DIR}/lib/libw3nco_v2.0.6_d.a

    cmake .. -DCMAKE_PREFIX_PATH=${MYDIR}/libs/3rdparty/local \
             -DCMAKE_C_COMPILER=${MPICC} \
             -DCMAKE_CXX_COMPILER=${MPICXX} \
             -DCMAKE_Fortran_COMPILER=${MPIF90}

    make -j 8

    cp sorc/chgres_cube.fd/chgres_cube.exe ${MYDIR}/bin/chgres_cube_grib2.exe
  )

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
  export CMAKE_C_COMPILER=${MPICC}
  export CMAKE_CXX_COMPILER=${MPICXX}
  export CMAKE_Fortran_COMPILER=${MPIF90}

  export NCEPLIBS_DIR=${MYDIR}/libs/nceplibs/local

  export BACIO_LIB4=${NCEPLIBS_DIR}/lib/libbacio_v2.1.0_4.a
  export NEMSIO_INC=${NCEPLIBS_DIR}/include
  export NEMSIO_LIB=${NCEPLIBS_DIR}/lib/libnemsio_v2.2.3.a
  export SP_LIBd=${NCEPLIBS_DIR}/lib/libsp_v2.0.2_d.a
  export W3EMC_LIBd=${NCEPLIBS_DIR}/lib/libw3emc_v2.2.0_d.a
  export W3NCO_LIBd=${NCEPLIBS_DIR}/lib/libw3nco_v2.0.6_d.a

  cd ${MYDIR}/src/model
  export CCPP_SUITES="FV3_GFS_2017,FV3_GFS_2017_gfdlmp,FV3_GFS_2017_gfdlmp_regional"
  export CMAKE_FLAGS="-D32BIT=ON -DDYN32=ON"

  ./build.sh

  cp ufs_weather_model ${MYDIR}/bin/ufs_model

) > log_model 2>&1
echo 'done'
fi

#
# post
#
if [ $BUILD_POST == yes ]; then
printf '%-.30s ' "Building post ..........................."
(
  export NCEPLIBS_DIR=${MYDIR}/libs/nceplibs/local

  export BACIO_LIB4=${NCEPLIBS_DIR}/lib/libbacio_v2.1.0_4.a

  export CRTM_INC=${NCEPLIBS_DIR}/include
  export CRTM_LIB=${NCEPLIBS_DIR}/lib/libcrtm_v2.3.0.a

  export G2TMPL_INCd=${NCEPLIBS_DIR}/include_d
  export G2TMPL_LIBd=${NCEPLIBS_DIR}/lib/libg2tmpl_v1.5.0_d.a

  export G2_INC4=${NCEPLIBS_DIR}/include_4
  export G2_INCd=${NCEPLIBS_DIR}/include_d
  export G2_LIB4=${NCEPLIBS_DIR}/lib/libg2_v3.1.0_4.a
  export G2_LIBd=${NCEPLIBS_DIR}/lib/libg2_v3.1.0_d.a

  export GFSIO_INC4=${NCEPLIBS_DIR}/include_4
  export GFSIO_LIB4=${NCEPLIBS_DIR}/lib/libgfsio_v1.1.0_4.a

  export IP_INC4=${NCEPLIBS_DIR}/include_4
  export IP_INCd=${NCEPLIBS_DIR}/include_d
  export IP_INC8=${NCEPLIBS_DIR}/include_8
  export IP_LIB4=${NCEPLIBS_DIR}/lib/libip_v3.0.0_4.a
  export IP_LIBd=${NCEPLIBS_DIR}/lib/libip_v3.0.0_d.a
  export IP_LIB8=${NCEPLIBS_DIR}/lib/libip_v3.0.0_8.a

  export NEMSIO_INC=${NCEPLIBS_DIR}/include
  export NEMSIO_LIB=${NCEPLIBS_DIR}/lib/libnemsio_v2.2.3.a

  export SFCIO_INC4=${NCEPLIBS_DIR}/include_4
  export SFCIO_LIB4=${NCEPLIBS_DIR}/lib/libsfcio_v1.1.0_4.a

  export SIGIO_INC4=${NCEPLIBS_DIR}/include_4
  export SIGIO_LIB4=${NCEPLIBS_DIR}/lib/libsigio_v2.1.0_4.a

  export SP_LIB4=${NCEPLIBS_DIR}/lib/libsp_v2.0.2_4.a
  export SP_LIBd=${NCEPLIBS_DIR}/lib/libsp_v2.0.2_d.a

  export W3EMC_INC4=${NCEPLIBS_DIR}/include_4
  export W3EMC_LIB4=${NCEPLIBS_DIR}/lib/libw3emc_v2.2.0_4.a
  export W3EMC_LIBd=${NCEPLIBS_DIR}/lib/libw3emc_v2.2.0_d.a
  export W3EMC_LIB8=${NCEPLIBS_DIR}/lib/libw3emc_v2.2.0_8.a

  export W3NCO_LIB4=${NCEPLIBS_DIR}/lib/libw3nco_v2.0.6_4.a
  export W3NCO_LIBd=${NCEPLIBS_DIR}/lib/libw3nco_v2.0.6_d.a
  export W3NCO_LIB8=${NCEPLIBS_DIR}/lib/libw3nco_v2.0.6_8.a

  cd src/post

  rm -rf build
  mkdir build
  cd build

  cmake .. -DCMAKE_PREFIX_PATH=${MYDIR}/libs/3rdparty/local \
           -DCMAKE_C_COMPILER=${MPICC} \
           -DCMAKE_CXX_COMPILER=${MPICXX} \
           -DCMAKE_Fortran_COMPILER=${MPIF90}

  make -j 8
  cp sorc/ncep_post.fd/ncep_post ${MYDIR}/bin/ufs_post

) > log_post 2>&1
echo 'done'
fi

echo "Done!"
