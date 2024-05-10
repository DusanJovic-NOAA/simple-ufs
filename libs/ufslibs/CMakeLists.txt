cmake_minimum_required(VERSION 3.12)

if(POLICY CMP0135)
  # DOWNLOAD_EXTRACT_TIMESTAMP
  cmake_policy(SET CMP0135 NEW)
endif()

project(ufs-libraries LANGUAGES C CXX Fortran)

include(ExternalProject)

set(MPI_DETERMINE_LIBRARY_VERSION true)
find_package(MPI REQUIRED C CXX Fortran)

set(install_prefix ${CMAKE_INSTALL_PREFIX})

# if(${CMAKE_Fortran_COMPILER_ID} MATCHES "^(GNU)$")
#   if(${CMAKE_Fortran_COMPILER_VERSION} VERSION_GREATER_EQUAL 10)
#     set(FCFLAGS_fms "${FCFLAGS_fms} -fallow-argument-mismatch -fallow-invalid-boz")
#     set(FCFLAGS_esmf "${FCFLAGS_esmf} -fallow-argument-mismatch -fallow-invalid-boz")
#   endif()
# endif()

##
## zstd
##
ExternalProject_Add(zstd
    URL https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz
    URL_HASH MD5=63251602329a106220e0a5ad26ba656f
    SOURCE_SUBDIR build/cmake
    CMAKE_ARGS -LH
               -DCMAKE_INSTALL_PREFIX=${install_prefix}/zstd
               -DCMAKE_INSTALL_LIBDIR=lib
               -DZSTD_MULTITHREAD_SUPPORT=OFF
               -DZSTD_LEGACY_SUPPORT=OFF
               -DZSTD_BUILD_STATIC=ON
               -DZSTD_BUILD_SHARED=OFF
               -DZSTD_BUILD_PROGRAMS=OFF
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## zlib
##
ExternalProject_Add(zlib
    URL https://github.com/madler/zlib/archive/refs/tags/v1.2.13.tar.gz
    URL_HASH MD5=9c7d356c5acaa563555490676ca14d23
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ./configure --prefix=${install_prefix}/zlib
                                  --libdir=${install_prefix}/zlib/lib
                                  --static
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## jasper
##
ExternalProject_Add(jasper
    URL https://github.com/jasper-software/jasper/archive/refs/tags/version-2.0.32.tar.gz
    URL_HASH MD5=2c6017d275146f8792fa448227a7c373
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/jasper
               -DCMAKE_INSTALL_LIBDIR=lib
               -DCMAKE_BUILD_TYPE=Release
               -DJAS_ENABLE_DOC=OFF
               -DJAS_ENABLE_SHARED=OFF
               -DJAS_ENABLE_AUTOMATIC_DEPENDENCIES=OFF
               -DJAS_ENABLE_PROGRAMS=OFF
               -DJAS_ENABLE_OPENGL=OFF
               -DJAS_ENABLE_LIBJPEG=OFF
               -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=ON
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## libpng
##
ExternalProject_Add(libpng
    URL https://github.com/glennrp/libpng/archive/refs/tags/v1.6.37.tar.gz
    URL_HASH MD5=564aa9f6c678dbb016b07ecfae8b7245
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CPPFLAGS=-I${install_prefix}/zlib/include"
                      env "LDFLAGS=-L${install_prefix}/zlib/lib"
                      ./configure --prefix=${install_prefix}/libpng
                                  --libdir=${install_prefix}/libpng/lib
                                  --disable-shared
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(libpng build zlib)

##
## hdf5
##
ExternalProject_Add(hdf5
    PREFIX ${contrib_prefix}
    URL https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5_1.14.4.2.tar.gz
    URL_HASH MD5=f1eaf87cc338475deb4aa48fb17cb8f8
    PATCH_COMMAND patch -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/hdf5-1.14.4.2_add_zstd.patch
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/hdf5
               -DCMAKE_PREFIX_PATH=${install_prefix}
               -DCMAKE_BUILD_TYPE=Release
               -DBUILD_SHARED_LIBS=OFF
               -DBUILD_TESTING=OFF
               -DHDF5_BUILD_TOOLS=OFF
               -DHDF5_BUILD_UTILS=OFF
               -DHDF5_BUILD_CPP_LIB=OFF
               -DHDF5_BUILD_EXAMPLES=OFF
               -DHDF5_ENABLE_PARALLEL=ON
               -DHDF5_ENABLE_Z_LIB_SUPPORT=ON
               -DHDF5_ENABLE_ZSTD_SUPPORT=ON
               -Dzstd_ROOT=${install_prefix}/zstd/lib/cmake
               -DHDF5_INSTALL_CMAKE_DIR=lib/cmake
    LOG_DOWNLOAD ON
    LOG_PATCH ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(hdf5 build zlib zstd)


##
## netcdf
##
ExternalProject_Add(netcdf
    URL https://github.com/Unidata/netcdf-c/archive/v4.9.2.tar.gz
    URL_HASH MD5=84acd096ab4f3300c20db862eecdf7c7
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env "CPPFLAGS=-I${install_prefix}/hdf5/include"
                      env "LDFLAGS=-L${install_prefix}/hdf5/lib -L${install_prefix}/zstd/lib -L${install_prefix}/zlib/lib"
                      env "LIBS=-lhdf5_hl -lhdf5 -lzstd -lz -lm"
                      ./configure --prefix=${install_prefix}/netcdf
                                  --libdir=${install_prefix}/netcdf/lib
                                  --enable-cdf5
                                  --disable-dap
                                  --disable-libxml2
                                  --disable-byterange
                                  --enable-netcdf-4
                                  --disable-doxygen
                                  --disable-shared
                                  --enable-static
                                  --disable-large-file-tests
                                  --enable-parallel-tests
                                  --enable-logging
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(netcdf build hdf5)

##
## netcdf_fortran
##
ExternalProject_Add(netcdf_fortran
    URL https://github.com/Unidata/netcdf-fortran/archive/v4.6.1.tar.gz
    URL_HASH MD5=8c200fcf7d9d2761037dfd2dabe2216b
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env "FC=${MPI_Fortran_COMPILER}"
                      env "CPPFLAGS=-I${install_prefix}/netcdf/include"
                      env "LDFLAGS=-L${install_prefix}/hdf5/lib -L${install_prefix}/netcdf/lib -L${install_prefix}/zstd/lib -L${install_prefix}/zlib/lib"
                      env "LIBS=-lnetcdf -lhdf5_hl -lhdf5 -lzstd -lz -lm"
                      env "HDF5_PLUGIN_PATH=${install_prefix}/hdf5/lib/plugin"
                      ./configure --prefix=${install_prefix}/netcdf
                                  --libdir=${install_prefix}/netcdf/lib
                                  --enable-static
                                  --disable-shared
                                  --enable-zstandard_plugin
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(netcdf_fortran build netcdf)

##
## PIO
##
ExternalProject_Add(pio
    URL https://github.com/NCAR/ParallelIO/archive/refs/tags/pio2_5_10.tar.gz
    URL_HASH MD5=171ee9a2b31a73108314a35b4db1dfaa
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/pio
               -DCMAKE_C_COMPILER=${MPI_C_COMPILER}
               -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}
               -DPIO_ENABLE_TIMING=OFF
               -DPIO_ENABLE_DOC=OFF
               -DPIO_ENABLE_EXAMPLES=OFF
               -DNetCDF_PATH=${install_prefix}/netcdf
               -DHDF5_PATH=${install_prefix}/hdf5
               -DLIBZ_PATH=${install_prefix}/zlib
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(pio build netcdf_fortran)

##
## FMS
##
ExternalProject_Add(fms
    URL https://github.com/NOAA-GFDL/FMS/archive/refs/tags/2023.04.tar.gz
    URL_HASH MD5=2725e558eaa53fa1016fe785444759ae
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/fms
               -DCMAKE_PREFIX_PATH=${install_prefix}/netcdf
               -DCMAKE_C_FLAGS=${CFLAGS_fms}
               -DCMAKE_Fortran_FLAGS=${FCFLAGS_fms}
               -DGFS_PHYS=ON
               -DCONSTANTS=GFS
               -D64BIT=ON
               -DOPENMP=ON
               -DUSE_DEPRECATED_IO=ON
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(fms build netcdf_fortran)

##
## ESMF
##
list(APPEND esmf_env ESMF_DIR=${CMAKE_CURRENT_BINARY_DIR}/esmf-prefix/src/esmf)

if(${CMAKE_C_COMPILER_ID} STREQUAL "Intel")
  list(APPEND esmf_env ESMF_COMPILER=intel)
elseif(${CMAKE_C_COMPILER_ID} MATCHES "IntelLLVM")
  list(APPEND esmf_env ESMF_COMPILER=intel)
elseif(${CMAKE_C_COMPILER_ID} MATCHES "^(GNU|Clang|AppleClang)$")
  list(APPEND esmf_env ESMF_COMPILER=gfortran)
else()
  message(FATAL_ERROR "Unsupported compiler ${CMAKE_C_COMPILER_ID}")
endif()

if(NOT MPITYPE)
  if(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*CRAY MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpich")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "4")
    set(MPITYPE "mpich")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Open MPI.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "openmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*HPE MPT.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpt")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Intel.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "intelmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MVAPICH2.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mvapich2")
  else()
    message(STATUS "MPI_C_LIBRARY_VERSION_STRING = '${MPI_C_LIBRARY_VERSION_STRING}'")
    message(STATUS "MPI_C_VERSION_MAJOR = '${MPI_C_VERSION_MAJOR}'")
    message(FATAL_ERROR "Cannot detect MPI type for ESMF, check that it is supported and set it via -DMPITYPE=... ; valid options are: mpi, mpich3, openmpi, mpt, intelmpi, mvapich2")
  endif()
endif()
message(STATUS "Set ESMF_COMM to ${MPITYPE}")

list(APPEND esmf_env ESMF_COMM=${MPITYPE})
list(APPEND esmf_env ESMF_BOPT=O)
# list(APPEND esmf_env ESMF_OPTLEVEL=2)
list(APPEND esmf_env ESMF_F90COMPILEOPTS=${FCFLAGS_esmf})
list(APPEND esmf_env ESMF_CXXCOMPILEOPTS=${CXXFLAGS_esmf})
list(APPEND esmf_env ESMF_MPIRUN=mpiexec)
list(APPEND esmf_env ESMF_NETCDF_INCLUDE=${install_prefix}/netcdf/include)
list(APPEND esmf_env ESMF_NETCDF_LIBPATH=${install_prefix}/netcdf/lib)
list(APPEND esmf_env ESMF_NETCDF=split)
list(APPEND esmf_env "ESMF_NETCDF_LIBS=-lnetcdff -lnetcdf -L${install_prefix}/hdf5/lib -lhdf5_hl -lhdf5 -L${install_prefix}/zstd/lib -lzstd -L${install_prefix}/zlib/lib -lz -ldl -lm")
list(APPEND esmf_env ESMF_PIO=external)
list(APPEND esmf_env ESMF_PIO_INCLUDE=${install_prefix}/pio/include)
list(APPEND esmf_env ESMF_PIO_LIBPATH=${install_prefix}/pio/lib)
list(APPEND esmf_env ESMF_SHARED_LIB_BUILD=OFF)
list(APPEND esmf_env ESMF_INSTALL_PREFIX=${install_prefix}/esmf)
list(APPEND esmf_env ESMF_INSTALL_HEADERDIR=include)
list(APPEND esmf_env ESMF_INSTALL_MODDIR=mod)
list(APPEND esmf_env ESMF_INSTALL_LIBDIR=lib)
list(APPEND esmf_env ESMF_INSTALL_BINDIR=bin)

ExternalProject_Add(esmf
    URL https://github.com/esmf-org/esmf/archive/refs/tags/v8.6.1.tar.gz
    URL_HASH MD5=ddf8e428e5d9cc3b17a6ed8408aade41
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ""
    BUILD_COMMAND   env ${esmf_env} make -j 8
    INSTALL_COMMAND env ${esmf_env} make -j 1 install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(esmf build netcdf_fortran pio)

##
## NCEPLIBS
##
set(bacio_tag  2.4.1)
set(g2_tag     3.4.5)
set(g2tmpl_tag 1.10.2)
set(ip_tag     4.3.0)
set(sp_tag     2.5.0)
set(w3emc_tag  2.10.0)

foreach(lib_name bacio g2 g2tmpl ip sp w3emc)

    ExternalProject_Add(${lib_name}
        GIT_REPOSITORY https://github.com/NOAA-EMC/NCEPLIBS-${lib_name}
        GIT_TAG v${${lib_name}_tag}
        GIT_SUBMODULES_RECURSE ON
        UPDATE_COMMAND ""
        BUILD_IN_SOURCE OFF
        LIST_SEPARATOR ,
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/${lib_name}
                   -DCMAKE_INSTALL_LIBDIR=lib
                   -DCMAKE_PREFIX_PATH=${install_prefix}/netcdf,${install_prefix}/jasper,${install_prefix}/libpng,${install_prefix}/zlib
                   -Dbacio_ROOT=${install_prefix}/bacio
                   -Dg2_ROOT=${install_prefix}/g2
                   -Dg2tmpl_ROOT=${install_prefix}/g2tmpl
                   -Dip_ROOT=${install_prefix}/ip
                   -Dsp_ROOT=${install_prefix}/sp
                   -Dw3emc_ROOT=${install_prefix}/w3emc
                   -DBUILD_WITH_BUFR=OFF
        LOG_DOWNLOAD ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
    )

endforeach()

ExternalProject_Add_StepDependencies(g2     build jasper libpng)
ExternalProject_Add_StepDependencies(ip     build sp)
ExternalProject_Add_StepDependencies(w3emc  build bacio)

##
## crtm
##
ExternalProject_Add(crtm
    DOWNLOAD_COMMAND git clone --branch v2.4.0_emc.3
                               --depth=1
                               --config "filter.lfs.process=git-lfs\ filter-process\ --skip"
                               --config "advice.detachedHead=false"
                               "https://github.com/JCSDA/crtm"
    PATCH_COMMAND bash -l -c "sed -i -e 's/-fbacktrace/-fbacktrace -ffree-line-length-none/g' libsrc/CMakeLists.txt"
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/crtm
               -DCMAKE_INSTALL_LIBDIR=lib
               -DNetCDF_ROOT=${install_prefix}/netcdf
    LOG_DOWNLOAD ON
    LOG_PATCH ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(crtm build netcdf_fortran)

##
## ecbuild
##
ExternalProject_Add(ecbuild
    URL https://github.com/ecmwf/ecbuild/archive/refs/tags/3.7.2.tar.gz
    URL_HASH MD5=7a7b4138e0c7e68abcd64e56002cbfcf
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/ecbuild
               -DCMAKE_INSTALL_LIBDIR=lib
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## esma_cmake
##
ExternalProject_Add(esma_cmake
    URL https://github.com/GEOS-ESM/ESMA_cmake/archive/refs/tags/v3.45.0.tar.gz
    URL_HASH MD5=042ed33c7f2621cd021cfcf813b2e24b
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR> ${install_prefix}/esma_cmake
    LOG_DOWNLOAD ON
    LOG_INSTALL ON
)

##
## gftl_shared
##
ExternalProject_Add(gftl_shared
    GIT_REPOSITORY https://github.com/Goddard-Fortran-Ecosystem/gFTL-shared
    GIT_TAG v1.8.0
    GIT_SUBMODULES_RECURSE ON
    UPDATE_COMMAND ""
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/gftl_shared -DGIT_SUBMODULE=OFF
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)


##
## mapl
##

# Must specify a value for MPI_STACK
#  with cmake ...  -DMPI_STACK=<mpistack>.  The acceptable values are:
#  intelmpi, mvapich, mpt, mpich, openmpi
message(STATUS "Set MAPL's MPI_STACK to ${MPITYPE}")

ExternalProject_Add(mapl
    URL https://github.com/GEOS-ESM/MAPL/archive/refs/tags/v2.46.0.tar.gz
    URL_HASH MD5=7be5f4dc91597db772086691d80bfbfc
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/mapl
               -DCMAKE_CC_COMPILER=${MPI_C_COMPILER}
               -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}
               -DCMAKE_PREFIX_PATH=${install_prefix}/ecbuild
               -DCMAKE_MODULE_PATH=${install_prefix}/esma_cmake,${install_prefix}/ecbuild
               -DNetCDF_ROOT=${install_prefix}/netcdf
               -DNetCDF_Fortran_EXTRA_LIBRARIES=-L${install_prefix}/netcdf/lib,-lnetcdf,-L${install_prefix}/hdf5/lib,-lhdf5_hl,-lhdf5,-L${install_prefix}/zstd/lib,-lzstd,-L${install_prefix}/zlib/lib,-lz,-ldl,-lm
               -DHDF5_ROOT=${install_prefix}/hdf5
               -DGFTL_ROOT=${install_prefix}/gftl_shared
               -DGFTL_SHARED_ROOT=${install_prefix}/gftl_shared
               -DCMAKE_BUILD_TYPE=Release
               -DBUILD_WITH_FLAP=OFF
               -DBUILD_WITH_PFLOGGER=OFF
               -DBUILD_WITH_FARGPARSE=OFF
               -DESMA_USE_GFE_NAMESPACE=ON
               -DBUILD_SHARED_MAPL=OFF
               -DUSE_EXTDATA2G=OFF
               -DUSE_F2PY=OFF
               -DESMFMKFILE=${install_prefix}/esmf/lib/esmf.mk
               -DMPI_STACK=${MPITYPE}
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(mapl build esmf ecbuild esma_cmake gftl_shared)

##
## scotch
##
ExternalProject_Add(scotch
    URL https://gitlab.inria.fr/scotch/scotch/-/archive/v7.0.4/scotch-v7.0.4.tar.gz
    URL_HASH MD5=da80cae85216f666fc31c45558fee832
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/scotch
               -DCMAKE_BUILD_TYPE=Release
               -DCMAKE_C_STANDARD=99
               -DBUILD_LIBSCOTCHMETIS=ON
               -DINSTALL_METIS_HEADERS=ON
               -DBUILD_LIBESMUMPS=OFF
               -DBUILD_SHARED_LIBS=OFF
               -DBUILD_PTSCOTCH=ON
               -DTHREADS=OFF
               -DMPI_THREAD_MULTIPLE=OFF
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
)
