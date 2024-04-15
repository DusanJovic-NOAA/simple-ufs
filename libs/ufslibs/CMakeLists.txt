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

if(${CMAKE_Fortran_COMPILER_ID} MATCHES "^(GNU)$")
  if(${CMAKE_Fortran_COMPILER_VERSION} VERSION_GREATER_EQUAL 10)
    set(FCFLAGS_pio "${FCFLAGS_pio} -fallow-argument-mismatch -fallow-invalid-boz")
    set(FCFLAGS_fms "${FCFLAGS_fms} -fallow-argument-mismatch -fallow-invalid-boz")
    set(FCFLAGS_esmf "${FCFLAGS_esmf} -fallow-argument-mismatch -fallow-invalid-boz")
  endif()
endif()

option(USE_ZSTD_AND_DYNAMIC_HDF5 "Use zstd and dynamic HDF5" OFF)
if(USE_ZSTD_AND_DYNAMIC_HDF5)
    message(STATUS "Use zstd and dynamic HDF5")
endif()

if(USE_ZSTD_AND_DYNAMIC_HDF5)
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
endif()

##
## zlib
##
ExternalProject_Add(zlib
    URL https://github.com/madler/zlib/archive/refs/tags/v1.2.13.tar.gz
    URL_HASH MD5=9c7d356c5acaa563555490676ca14d23
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CFLAGS=-fPIC"
                      ./configure --prefix=${install_prefix}/zlib
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
if(USE_ZSTD_AND_DYNAMIC_HDF5)
    set(hdf5_enable_shared_libs --enable-shared --disable-static)
else()
    set(hdf5_enable_shared_libs --disable-shared --enable-static)
endif()
ExternalProject_Add(hdf5
    URL https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_14_0.tar.gz
    URL_HASH MD5=7b2d91956be4be8d57e62c1ec4d1a241
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env "CFLAGS=-pthread -fPIC"
                      ./configure --prefix=${install_prefix}/hdf5
                                  --libdir=${install_prefix}/hdf5/lib
                                  ${hdf5_enable_shared_libs}
                                  --enable-parallel
                                  --enable-unsupported
                                  --enable-tests=no
                                  --with-zlib=${install_prefix}/zlib
                                  --with-default-plugindir=${install_prefix}/hdf5/lib/plugin
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(hdf5 build zlib)

if(USE_ZSTD_AND_DYNAMIC_HDF5)
    ##
    ## hdf5_plugins
    ##
    ExternalProject_Add(hdf5_plugins
        URL https://github.com/HDFGroup/hdf5_plugins/archive/refs/tags/1.14.0.tar.gz
        URL_HASH MD5=4a23f03245e72c64079b876218fed2b9
        BUILD_IN_SOURCE OFF
        CMAKE_ARGS -C <SOURCE_DIR>/config/cmake/cacheinit.cmake
                   -DCMAKE_C_COMPILER=${MPI_C_COMPILER}
                   -DCMAKE_BUILD_TYPE=Release
                   -DCMAKE_INSTALL_PREFIX=${install_prefix}/hdf5
                   -DHDF5_INCLUDE_DIR=${install_prefix}/hdf5/include/
                   -DHDF5_LINK_LIBS=${install_prefix}/hdf5/lib/
                   -DUSE_SHARED_LIBS=ON
                   -DBUILD_SHARED_LIBS=ON
                   -DENABLE_BSHUF=OFF
                   -DENABLE_BLOSC=OFF
                   -DENABLE_BZIP2=OFF
                   -DENABLE_JPEG=OFF
                   -DENABLE_LZ4=OFF
                   -DENABLE_LZF=OFF
                   -DTGZPATH=<SOURCE_DIR>/libs
                   -DH5PL_ALLOW_EXTERNAL_SUPPORT=TGZ
                   -DBUILD_EXAMPLES=OFF
        LOG_DOWNLOAD ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
    )
    ExternalProject_Add_StepDependencies(hdf5_plugins build hdf5)
endif()

##
## netcdf
##
if(USE_ZSTD_AND_DYNAMIC_HDF5)
    set(netcdf_cppflags_env        "CPPFLAGS=-I${install_prefix}/hdf5/include -I${install_prefix}/zstd/include")
    set(netcdf_ldflags_env         "LDFLAGS=-L${install_prefix}/hdf5/lib -L${install_prefix}/zstd/lib -L${install_prefix}/zlib/lib -Wl,-rpath -Wl,${install_prefix}/hdf5/lib")
    set(netcdf_libs_env            "LIBS=-lhdf5_hl -lhdf5 -lz -lzstd -lm")
    set(netcdf_ld_library_path_env "LD_LIBRARY_PATH=${install_prefix}/hdf5/lib:$ENV{LD_LIBRARY_PATH}")
else()
    set(netcdf_cppflags_env        "CPPFLAGS=-I${install_prefix}/hdf5/include")
    set(netcdf_ldflags_env         "LDFLAGS=-L${install_prefix}/hdf5/lib -L${install_prefix}/zlib/lib")
    set(netcdf_libs_env            "LIBS=-lhdf5_hl -lhdf5 -lz -lm")
    set(netcdf_ld_library_path_env "")
endif()
ExternalProject_Add(netcdf
    URL https://github.com/Unidata/netcdf-c/archive/v4.9.2.tar.gz
    URL_HASH MD5=84acd096ab4f3300c20db862eecdf7c7
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env ${netcdf_cppflags_env}
                      env ${netcdf_ldflags_env}
                      env ${netcdf_libs_env}
                      env ${netcdf_ld_library_path_env}
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
if(USE_ZSTD_AND_DYNAMIC_HDF5)
    ExternalProject_Add_StepDependencies(netcdf build zstd)
endif()

##
## netcdf_fortran
##
if(USE_ZSTD_AND_DYNAMIC_HDF5)
    set(netcdf_fortran_cppflags_env		   "CPPFLAGS=-I${install_prefix}/netcdf/include")
    set(netcdf_fortran_ldflags_env		   "LDFLAGS=-L${install_prefix}/hdf5/lib -L${install_prefix}/zstd/lib -L${install_prefix}/netcdf/lib -L${install_prefix}/zlib/lib -Wl,-rpath -Wl,${install_prefix}/hdf5/lib")
    set(netcdf_fortran_libs_env			   "LIBS=-lnetcdf -lhdf5_hl -lhdf5 -lz -lzstd -lm")
    set(netcdf_fortran_ld_library_path_env "LD_LIBRARY_PATH=${install_prefix}/hdf5/lib:$ENV{LD_LIBRARY_PATH}")
else()
    set(netcdf_fortran_cppflags_env		   "CPPFLAGS=-I${install_prefix}/netcdf/include")
    set(netcdf_fortran_ldflags_env		   "LDFLAGS=-L${install_prefix}/hdf5/lib -L${install_prefix}/netcdf/lib -L${install_prefix}/zlib/lib")
    set(netcdf_fortran_libs_env			   "LIBS=-lnetcdf -lhdf5_hl -lhdf5 -lz -lm")
    set(netcdf_fortran_ld_library_path_env "")
endif()

ExternalProject_Add(netcdf_fortran
    URL https://github.com/Unidata/netcdf-fortran/archive/v4.6.0.tar.gz
    URL_HASH MD5=9d452a9ff8c8b646fefcfe180273111d
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env "FC=${MPI_Fortran_COMPILER}"
                      env ${netcdf_fortran_cppflags_env}
                      env ${netcdf_fortran_ldflags_env}
                      env ${netcdf_fortran_libs_env}
                      env ${netcdf_fortran_ld_library_path_env}
                      ./configure --prefix=${install_prefix}/netcdf
                                  --libdir=${install_prefix}/netcdf/lib
                                  --enable-static
                                  --disable-shared
                                  --enable-logging
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
    URL https://github.com/NOAA-GFDL/FMS/archive/refs/tags/2023.02.01.tar.gz
    URL_HASH MD5=448fe2420c0df8067317a2369bc3624b
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
    set(MPITYPE "mpich3")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "4")
    set(MPITYPE "mpich3")
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
list(APPEND esmf_env "ESMF_NETCDF_LIBS=-lnetcdff -lnetcdf -L${install_prefix}/hdf5/lib -lhdf5_hl -lhdf5 -L${install_prefix}/zlib/lib -lz -ldl -lm")
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
    URL https://github.com/esmf-org/esmf/archive/refs/tags/v8.5.0.tar.gz
    URL_HASH MD5=c77313a07dca94b16751aae0d3a38865
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ""
    BUILD_COMMAND   env ${esmf_env} make -j 8
    INSTALL_COMMAND env ${esmf_env} make install
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
set(nemsio_tag 2.5.4)
set(sfcio_tag  1.4.1)
set(sigio_tag  2.3.2)
set(sp_tag     2.3.3)
set(w3emc_tag  2.10.0)

foreach(lib_name
                 bacio
                 g2
                 g2tmpl
                 ip
                 nemsio
                 sfcio
                 sigio
                 sp
                 w3emc)

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
                   -Dnemsio_ROOT=${install_prefix}/nemsio
                   -Dsfcio_ROOT=${install_prefix}/sfcio
                   -Dsigio_ROOT=${install_prefix}/sigio
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
ExternalProject_Add_StepDependencies(nemsio build bacio w3emc)
ExternalProject_Add_StepDependencies(w3emc  build bacio)

##
## crtm
##
ExternalProject_Add(crtm
    URL https://github.com/JCSDA/crtm/archive/refs/tags/v2.4.0_emc.tar.gz
    URL_HASH MD5=fc7506c73d042699450c3114ea449ea4
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/crtm
               -DCMAKE_INSTALL_LIBDIR=lib
               -DNetCDF_ROOT=${install_prefix}/netcdf
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(crtm build netcdf_fortran)

##
## ecbuild
##
ExternalProject_Add(ecbuild
    URL https://github.com/ecmwf/ecbuild/archive/refs/tags/3.6.1.tar.gz
    URL_HASH MD5=2cdf9ab9efd0b397dc8bf7ec01a949c5
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/ecbuild
               -DCMAKE_INSTALL_LIBDIR=lib
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## cmakemodules
##
ExternalProject_Add(cmakemodules
    URL https://github.com/NOAA-EMC/CMakeModules/archive/refs/tags/v1.2.0.tar.gz
    URL_HASH MD5=f4fc0b0ee277c8116ed9df30da4d3818
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR> ${install_prefix}/cmakemodules
    LOG_DOWNLOAD ON
    LOG_INSTALL ON
)

##
## esma_cmake
##
ExternalProject_Add(esma_cmake
    URL https://github.com/GEOS-ESM/ESMA_cmake/archive/refs/tags/v3.24.0.tar.gz
    URL_HASH MD5=e26d0a1f535987f1bb07b03cce06831b
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
    GIT_TAG v1.6.1
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
## yafyaml
##
ExternalProject_Add(yafyaml
    URL https://github.com/Goddard-Fortran-Ecosystem/yaFyaml/archive/refs/tags/v1.0.4.tar.gz
    URL_HASH MD5=f1cf8c45f5b9949703c253dfd7918ca5
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/yafyaml
               -DGFTL_ROOT=${install_prefix}/gftl_shared
               -DGFTL_SHARED_ROOT=${install_prefix}/gftl_shared
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(yafyaml build gftl_shared)

##
## mapl
##
ExternalProject_Add(mapl
    URL https://github.com/GEOS-ESM/MAPL/archive/refs/tags/v2.40.3.tar.gz
    URL_HASH MD5=3ae648a707646f9bf3325c49f80a646e
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/mapl
               -DCMAKE_CC_COMPILER=${MPI_C_COMPILER}
               -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}
               -DCMAKE_PREFIX_PATH=${install_prefix}/ecbuild
               -DCMAKE_MODULE_PATH=${install_prefix}/esma_cmake,${install_prefix}/cmakemodules/Modules,${install_prefix}/share/ecbuild/cmake
               -DNetCDF_ROOT=${install_prefix}/netcdf
               -DNetCDF_Fortran_EXTRA_LIBRARIES=-L${install_prefix}/netcdf/lib,-lnetcdf,-L${install_prefix}/hdf5/lib,-lhdf5_hl,-lhdf5,-L${install_prefix}/zlib/lib,-lz,-ldl,-lm
               -DHDF5_ROOT=${install_prefix}/hdf5
               -DGFTL_ROOT=${install_prefix}/gftl_shared
               -DGFTL_SHARED_ROOT=${install_prefix}/gftl_shared
               -DYAFYAML_ROOT=${install_prefix}/yafyaml
               -DCMAKE_BUILD_TYPE=Release
               -DBUILD_WITH_FLAP=OFF
               -DBUILD_WITH_PFLOGGER=OFF
               -DBUILD_WITH_FARGPARSE=OFF
               -DESMA_USE_GFE_NAMESPACE=ON
               -DBUILD_SHARED_MAPL=OFF
               -DUSE_EXTDATA2G=OFF
               -DUSE_F2PY=OFF
               -DESMFMKFILE=${install_prefix}/esmf/lib/esmf.mk
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(mapl build esmf ecbuild cmakemodules esma_cmake yafyaml)

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
