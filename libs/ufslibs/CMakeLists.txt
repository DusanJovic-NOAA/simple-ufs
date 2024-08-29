cmake_minimum_required(VERSION 3.12)

if(POLICY CMP0135)
  # DOWNLOAD_EXTRACT_TIMESTAMP
  cmake_policy(SET CMP0135 NEW)
endif()

project(ufs-libraries LANGUAGES C CXX Fortran)

include(ExternalProject)

set(MPI_DETERMINE_LIBRARY_VERSION true)
find_package(MPI REQUIRED C CXX Fortran)
message(STATUS "MPI find_package Found MPI_C_COMPILER = ${MPI_C_COMPILER}")
message(STATUS "MPI find_package Found MPI_CXX_COMPILER = ${MPI_CXX_COMPILER}")
message(STATUS "MPI find_package Found MPI_Fortran_COMPILER = ${MPI_Fortran_COMPILER}")

# Overwrite found mpi compiler wrappers
message(STATUS "CMAKE_VERSION = ${CMAKE_VERSION}")
# FindMPI.cmake in CMake < 3.29.0 does not find IntelLLVM mpi wrappers. Set them explicitly
if (CMAKE_VERSION VERSION_LESS "3.29.0" AND ${CMAKE_Fortran_COMPILER_ID} MATCHES "IntelLLVM")
set(MPI_C_COMPILER mpiicx)
set(MPI_CXX_COMPILER mpiicpx)
set(MPI_Fortran_COMPILER mpiifx)
message(STATUS "Overwritten for IntelLLVM MPI_C_COMPILER = ${MPI_C_COMPILER}")
message(STATUS "Overwritten for IntelLLVM MPI_CXX_COMPILER = ${MPI_CXX_COMPILER}")
message(STATUS "Overwritten for IntelLLVM MPI_Fortran_COMPILER = ${MPI_Fortran_COMPILER}")
endif()

set(install_prefix ${CMAKE_INSTALL_PREFIX})

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(downloads_prefix "${CMAKE_CURRENT_SOURCE_DIR}/downloads")

##
## zstd
##
ExternalProject_Add(zstd
    URL ${downloads_prefix}/zstd.tar.gz
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
    URL ${downloads_prefix}/zlib.tar.gz
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
    URL ${downloads_prefix}/jasper.tar.gz
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
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## libpng
##
ExternalProject_Add(libpng
    URL ${downloads_prefix}/libpng.tar.gz
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
    URL ${downloads_prefix}/hdf5.tar.gz
    URL_HASH MD5=f1eaf87cc338475deb4aa48fb17cb8f8
    PATCH_COMMAND patch -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/patches/hdf5-1.14.4.2_add_zstd.patch
          COMMAND bash -l -c "sed -i -e 's/find_package (ZLIB.*/find_package (ZLIB MODULE)/g' CMakeFilters.cmake"
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
               -DZLIB_ROOT=${install_prefix}/zlib
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
if(NOT APPLE)
  set(_disable_libxml2 "--disable-libxml2")
endif()
ExternalProject_Add(netcdf
    URL ${downloads_prefix}/netcdf.tar.gz
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
                                  ${_disable_libxml2}
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
    URL ${downloads_prefix}/netcdf_fortran.tar.gz
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
                                  --disable-doxygen
                                  --enable-zstandard_plugin
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(netcdf_fortran build netcdf)

##
## genf90
##
ExternalProject_Add(genf90
    URL ${downloads_prefix}/genf90.tar.gz
    URL_HASH MD5=7f3504dfb5aab846f4a9018dda7bb8ad
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/genf90.pl ${install_prefix}/genf90/bin/genf90.pl
    LOG_DOWNLOAD ON
    LOG_INSTALL ON
)

##
## cmake_fortran_utils
##
ExternalProject_Add(cmake_fortran_utils
    URL ${downloads_prefix}/cmake_fortran_utils.tar.gz
    URL_HASH MD5=a3c39f002a7a81882b65b7eb8c9a7d91
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR> ${install_prefix}/cmake_fortran_utils
    LOG_DOWNLOAD ON
    LOG_INSTALL ON
)

##
## PIO
##
ExternalProject_Add(pio
    URL ${downloads_prefix}/pio.tar.gz
    URL_HASH MD5=171ee9a2b31a73108314a35b4db1dfaa
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/pio
               -DCMAKE_C_COMPILER=${MPI_C_COMPILER}
               -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}
               -DPIO_ENABLE_TIMING=OFF
               -DPIO_ENABLE_DOC=OFF
               -DPIO_ENABLE_EXAMPLES=OFF
               -DUSER_CMAKE_MODULE_PATH=${install_prefix}/cmake_fortran_utils
               -DGENF90_PATH=${install_prefix}/genf90/bin
               -DNetCDF_PATH=${install_prefix}/netcdf
               -DHDF5_PATH=${install_prefix}/hdf5
               -DLIBZ_PATH=${install_prefix}/zlib
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(pio build netcdf_fortran genf90 cmake_fortran_utils)

##
## FMS
##
if (${CMAKE_Fortran_COMPILER_ID} MATCHES "IntelLLVM")
ExternalProject_Add(fms
    URL ${downloads_prefix}/fms.tar.gz
    URL_HASH MD5=2725e558eaa53fa1016fe785444759ae
    BUILD_IN_SOURCE OFF
    # CMAKE_COMMAND env I_MPI_F90=ifort cmake # Temporary until ifx fixes ICE
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/fms
               -DCMAKE_PREFIX_PATH=${install_prefix}/netcdf
               -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}
               -DGFS_PHYS=ON
               -DCONSTANTS=GFS
               -D64BIT=ON
               -DOPENMP=ON
               -DUSE_DEPRECATED_IO=ON
    # BUILD_COMMAND env I_MPI_F90=ifort make -j 8
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
else()
ExternalProject_Add(fms
    URL ${downloads_prefix}/fms.tar.gz
    URL_HASH MD5=2725e558eaa53fa1016fe785444759ae
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/fms
               -DCMAKE_PREFIX_PATH=${install_prefix}/netcdf
               -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}
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
endif()
ExternalProject_Add_StepDependencies(fms build netcdf_fortran)

##
## ESMF
##
list(APPEND esmf_env ESMF_DIR=${CMAKE_CURRENT_BINARY_DIR}/esmf-prefix/src/esmf)

if(${CMAKE_C_COMPILER_ID} STREQUAL "Intel")
  list(APPEND esmf_env ESMF_COMPILER=intel)
elseif(${CMAKE_C_COMPILER_ID} MATCHES "IntelLLVM")
  list(APPEND esmf_env ESMF_COMPILER=intel ESMF_C=mpiicx ESMF_CXX=mpiicpx ESMF_F90=mpiifx I_MPI_F90=ifx ESMF_CXXLINKLIBS=-lstdc++)
elseif(${CMAKE_C_COMPILER_ID} MATCHES "^(GNU|Clang|AppleClang)$")
  list(APPEND esmf_env ESMF_COMPILER=gfortran)
else()
  message(FATAL_ERROR "Unsupported compiler ${CMAKE_C_COMPILER_ID}")
endif()

if(NOT ESMF_COMM)
  if(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*CRAY MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(ESMF_COMM "mpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(ESMF_COMM "mpich")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "4")
    set(ESMF_COMM "mpich")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Open MPI.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(ESMF_COMM "openmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*HPE MPT.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(ESMF_COMM "mpt")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Intel.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(ESMF_COMM "intelmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MVAPICH2.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(ESMF_COMM "mvapich2")
  else()
    message(STATUS "MPI_C_LIBRARY_VERSION_STRING = '${MPI_C_LIBRARY_VERSION_STRING}'")
    message(STATUS "MPI_C_VERSION_MAJOR = '${MPI_C_VERSION_MAJOR}'")
    message(FATAL_ERROR "Cannot detect MPI type for ESMF, check that it is supported and set it via -DMPITYPE=... ; valid options are: mpi, mpich3, openmpi, mpt, intelmpi, mvapich2")
  endif()
endif()
message(STATUS "Set ESMF_COMM to ${ESMF_COMM}")

list(APPEND esmf_env ESMF_COMM=${ESMF_COMM})
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
    URL ${downloads_prefix}/esmf.tar.gz
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
ExternalProject_Add_Step(esmf post_install
    COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/cmake ${install_prefix}/esmf/cmake
    DEPENDEES install
    WORKING_DIRECTORY <INSTALL_DIR>
    LOG ON
)
ExternalProject_Add_StepDependencies(esmf build netcdf_fortran pio)

##
## bacio
##
ExternalProject_Add(bacio
    URL ${downloads_prefix}/bacio.tar.gz
    URL_HASH MD5=95bab417fbaf7c1f6f99316052189bea
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/bacio
               -DCMAKE_INSTALL_LIBDIR=lib
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## g2
##
ExternalProject_Add(g2
    URL ${downloads_prefix}/g2.tar.gz
    URL_HASH MD5=9931fb0740e66d3bfc09fb6cb842532b
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/g2
               -DCMAKE_INSTALL_LIBDIR=lib
               -DCMAKE_PREFIX_PATH=${install_prefix}/jasper,${install_prefix}/libpng,${install_prefix}/zlib
               -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}
               -Dbacio_ROOT=${install_prefix}/bacio
               -DBUILD_TESTING=OFF
               -DBUILD_WITH_W3EMC=OFF
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(g2 build jasper libpng bacio)

##
## g2tmpl
##
ExternalProject_Add(g2tmpl
    URL ${downloads_prefix}/g2tmpl.tar.gz
    URL_HASH MD5=dd40b6ff5d08f76e71475c24a81ea2a3
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/g2tmpl
               -DCMAKE_INSTALL_LIBDIR=lib
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## sp
##
ExternalProject_Add(sp
    URL ${downloads_prefix}/sp.tar.gz
    URL_HASH MD5=fc50806fb552b114a9f18d57ad3747a7
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/sp
               -DCMAKE_INSTALL_LIBDIR=lib
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## ip
##
ExternalProject_Add(ip
    URL ${downloads_prefix}/ip.tar.gz
    URL_HASH MD5=e19101124af68ee6a8f9c8051aa3aa6a
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/ip
               -DCMAKE_INSTALL_LIBDIR=lib
               -Dsp_ROOT=${install_prefix}/sp
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(ip build sp)

##
## w3emc
##
ExternalProject_Add(w3emc
    URL ${downloads_prefix}/w3emc.tar.gz
    URL_HASH MD5=ab162725c04899b8295bd74ed184debf
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/w3emc
               -DCMAKE_INSTALL_LIBDIR=lib
               -Dbacio_ROOT=${install_prefix}/bacio
               -DBUILD_WITH_BUFR=OFF
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(w3emc build bacio)

##
## crtm
##
ExternalProject_Add(crtm
    URL ${downloads_prefix}/crtm.tar.gz
    URL_HASH MD5=95a040cdfb0426448f1aab38b0c7601b
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
    URL ${downloads_prefix}/ecbuild.tar.gz
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
    URL ${downloads_prefix}/esma_cmake.tar.gz
    URL_HASH MD5=042ed33c7f2621cd021cfcf813b2e24b
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR> ${install_prefix}/esma_cmake
    LOG_DOWNLOAD ON
    LOG_INSTALL ON
)

##
## gftl
##
ExternalProject_Add(gftl
    URL ${downloads_prefix}/gftl.tar.gz
    URL_HASH MD5=e869943e27d5e39db2ffacd960ae3e77
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/gftl
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## gftl_shared
##
ExternalProject_Add(gftl_shared
    URL ${downloads_prefix}/gftl_shared.tar.gz
    URL_HASH MD5=7d733037a2a2b62c4221ab924c30915c
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/gftl_shared
               -DCMAKE_PREFIX_PATH=${install_prefix}/gftl
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(gftl_shared build gftl)


##
## mapl
##

# Must specify a value for MPI_STACK
#  with cmake ...  -DMPI_STACK=<mpistack>.  The acceptable values are:
#  intelmpi, mvapich, mpt, mpich, openmpi
if(NOT MPITYPE)
  if(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*")
    set(MPITYPE "mpich")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Open MPI.*")
    set(MPITYPE "openmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*HPE MPT.*")
    set(MPITYPE "mpt")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Intel.*")
    set(MPITYPE "intelmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MVAPICH2.*")
    set(MPITYPE "mvapich2")
  else()
    message(STATUS "MPI_C_LIBRARY_VERSION_STRING = '${MPI_C_LIBRARY_VERSION_STRING}'")
    message(STATUS "MPI_C_VERSION_MAJOR = '${MPI_C_VERSION_MAJOR}'")
    message(FATAL_ERROR "Cannot detect MPI type for MAPL, check that it is supported and set it via -DMPITYPE=... ; valid options are: mpich, openmpi, mpt, intelmpi, mvapich2")
  endif()
endif()
message(STATUS "Set MAPL MPI_STACK to ${MPITYPE}")

ExternalProject_Add(mapl
    URL ${downloads_prefix}/mapl.tar.gz
    URL_HASH MD5=8ddf81796cb51a5d48c6989fdb639b9d
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}/mapl
               -DCMAKE_C_COMPILER=${MPI_C_COMPILER}
               -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER}
               -DCMAKE_PREFIX_PATH=${install_prefix}/ecbuild
               -DCMAKE_MODULE_PATH=${install_prefix}/esma_cmake,${install_prefix}/ecbuild
               -DNetCDF_ROOT=${install_prefix}/netcdf
               -DNetCDF_Fortran_EXTRA_LIBRARIES=-L${install_prefix}/netcdf/lib,-lnetcdf,-L${install_prefix}/hdf5/lib,-lhdf5_hl,-lhdf5,-L${install_prefix}/zstd/lib,-lzstd,-L${install_prefix}/zlib/lib,-lz,-ldl,-lm
               -DHDF5_ROOT=${install_prefix}/hdf5
               -DGFTL_ROOT=${install_prefix}/gftl
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
ExternalProject_Add_StepDependencies(mapl build esmf ecbuild esma_cmake gftl gftl_shared)

##
## scotch
##
ExternalProject_Add(scotch
    URL ${downloads_prefix}/scotch.tar.gz
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
    LOG_INSTALL ON
)
