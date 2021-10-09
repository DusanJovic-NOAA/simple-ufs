cmake_minimum_required(VERSION 3.12)

project(ufs-libraries LANGUAGES C CXX Fortran)

include(ExternalProject)

set(MPI_DETERMINE_LIBRARY_VERSION true)
find_package(MPI REQUIRED C CXX Fortran)

set(install_prefix ${CMAKE_INSTALL_PREFIX})
set(config_env "CPPFLAGS=-I${install_prefix}/include" "LDFLAGS=-L${install_prefix}/lib")

if(${CMAKE_Fortran_COMPILER_ID} MATCHES "^(GNU)$")
  if(${CMAKE_Fortran_COMPILER_VERSION} VERSION_GREATER_EQUAL 10)
    set(FCFLAGS_pio "${FCFLAGS_pio} -fallow-argument-mismatch -fallow-invalid-boz")
    set(FCFLAGS_fms "${FCFLAGS_fms} -fallow-argument-mismatch -fallow-invalid-boz")
    set(FCFLAGS_esmf "${FCFLAGS_esmf} -fallow-argument-mismatch -fallow-invalid-boz")
  endif()
endif()

##
## zlib
##
ExternalProject_Add(zlib
    URL https://github.com/madler/zlib/archive/refs/tags/v1.2.11.tar.gz
    URL_HASH MD5=0095d2d2d1f3442ce1318336637b695f
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env ${config_env}
                      ./configure --prefix=${install_prefix}
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
    URL https://github.com/jasper-software/jasper/archive/refs/tags/version-2.0.25.tar.gz
    URL_HASH MD5=afbdd817fcdd0dcfbd6bec79825b944a
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS
               -DCMAKE_INSTALL_PREFIX=${install_prefix}
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
    CONFIGURE_COMMAND env ${config_env}
                      ./configure --prefix=${install_prefix}
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
    URL https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_10_6.tar.gz
    URL_HASH MD5=abbf353b2d8a1d5a062bdbba1c365171
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env ${config_env}
                      env "CC=${MPI_C_COMPILER}"
                      env "CFLAGS=-pthread"
                      ./configure --prefix=${install_prefix}
                                  --disable-shared
                                  --enable-static
                                  --enable-static-exec
                                  --enable-parallel
                                  --enable-unsupported
                                  --enable-tests=no
                                  --with-zlib=${install_prefix}

    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(hdf5 build zlib)

##
## netcdf
##
ExternalProject_Add(netcdf
    URL https://github.com/Unidata/netcdf-c/archive/v4.7.4.tar.gz
    URL_HASH MD5=33979e8f0cf4ee31323fc0934282111b
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env ${config_env}
                      env "CC=${MPI_C_COMPILER}"
                      env "LIBS=-lhdf5_hl -lhdf5 -lz -ldl -lm"
                      ./configure --prefix=${install_prefix}
                                  --enable-cdf5
                                  --disable-dap
                                  --enable-netcdf-4
                                  --disable-doxygen
                                  --disable-shared
                                  --enable-static
                                  --disable-large-file-tests
                                  --enable-parallel-tests
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
    URL https://github.com/Unidata/netcdf-fortran/archive/v4.5.3.tar.gz
    URL_HASH MD5=47bf6eed50bd50b23b7e391dc1f8b5c4
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env ${config_env}
                      env "CC=${MPI_C_COMPILER}"
                      env "FC=${MPI_Fortran_COMPILER}"
                      env "LIBS=-lnetcdf -lhdf5_hl -lhdf5 -lz -ldl -lm"
                      ./configure --prefix=${install_prefix}
                                  --enable-static
                                  --disable-shared
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
    URL https://github.com/NCAR/ParallelIO/releases/download/pio2_5_3/pio-2.5.3.tar.gz
    URL_HASH MD5=46ccbf390c54ce1339439c4e4fc360db
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env ${config_env}
                      env "CC=${MPI_C_COMPILER}"
                      env "FC=${MPI_Fortran_COMPILER}"
                      env "FCFLAGS=${FCFLAGS_pio}"
                      env "LIBS=-lnetcdf -lhdf5_hl -lhdf5 -lz -ldl -lm"
                      ./configure --prefix=${install_prefix}
                                  --enable-fortran
                                  --disable-pnetcdf
                                  --enable-static
                                  --disable-shared
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
    URL https://github.com/NOAA-GFDL/FMS/archive/refs/tags/2021.03.tar.gz
    URL_HASH MD5=268fca73f451b19026ca6f5072af5683
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_PREFIX_PATH=${install_prefix}
               -DCMAKE_INSTALL_PREFIX=${install_prefix}
               -DCMAKE_C_FLAGS=${CFLAGS_fms}
               -DCMAKE_Fortran_FLAGS=${FCFLAGS_fms}
               -DGFS_PHYS=ON
               -D64BIT=ON
               -DOPENMP=ON
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(fms build netcdf_fortran)

##
## ESMF
##
set(esmf_env ${config_env})
list(APPEND esmf_env ESMF_DIR=${CMAKE_CURRENT_BINARY_DIR}/esmf-prefix/src/esmf)

if(${CMAKE_C_COMPILER_ID} STREQUAL "Intel")
  list(APPEND esmf_env ESMF_COMPILER=intel)
elseif(${CMAKE_C_COMPILER_ID} MATCHES "^(GNU|Clang|AppleClang)$")
  list(APPEND esmf_env ESMF_COMPILER=gfortran)
else()
  message(FATAL "Unsupported compiler ${CMAKE_C_COMPILER_ID}")
endif()

if(NOT MPITYPE)
  if(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*CRAY MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpich3")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Open MPI.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "openmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*HPE MPT.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpt")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Intel.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "intelmpi")
  else()
    message(FATAL_ERROR "Cannot detect MPI type for ESMF, check that it is supported and set it via -DMPITYPE=... ; valid options are: intelmpi, openmpi, mpich3, mpt, openmpi")
  endif()
endif()
message(STATUS "Set ESMF_COMM to ${MPITYPE}")

list(APPEND esmf_env ESMF_COMM=${MPITYPE})
list(APPEND esmf_env ESMF_BOPT=O)
list(APPEND esmf_env ESMF_OPTLEVEL=2)
list(APPEND esmf_env ESMF_F90COMPILEOPTS=${FCFLAGS_esmf})
list(APPEND esmf_env ESMF_CXXCOMPILEOPTS=${CXXFLAGS_esmf})
list(APPEND esmf_env ESMF_MPIRUN=mpiexec)
list(APPEND esmf_env ESMF_NETCDF_INCLUDE=${install_prefix}/include)
list(APPEND esmf_env ESMF_NETCDF_LIBPATH=${install_prefix}/lib)
list(APPEND esmf_env ESMF_NETCDF=split)
list(APPEND esmf_env "ESMF_NETCDF_LIBS=-lnetcdff -lnetcdf -lhdf5_hl -lhdf5 -lz -ldl -lm")
list(APPEND esmf_env ESMF_PIO=internal)
list(APPEND esmf_env ESMF_SHARED_LIB_BUILD=OFF)
list(APPEND esmf_env ESMF_INSTALL_PREFIX=${install_prefix})
list(APPEND esmf_env ESMF_INSTALL_HEADERDIR=include)
list(APPEND esmf_env ESMF_INSTALL_MODDIR=mod)
list(APPEND esmf_env ESMF_INSTALL_LIBDIR=lib)
list(APPEND esmf_env ESMF_INSTALL_BINDIR=bin)

ExternalProject_Add(esmf
    URL https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0_beta_snapshot_14.tar.gz
    URL_HASH MD5=537f148644203b82c05d57f14a0a2dfc
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ""
    BUILD_COMMAND   env ${esmf_env} make -j 8
    INSTALL_COMMAND env ${esmf_env} make install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(esmf build netcdf_fortran)

##
## NCEPLIBS
##
set(EMC_crtm_tag        v2.3.0)
set(NCEPLIBS-bacio_tag  v2.4.1)
set(NCEPLIBS-g2_tag     v3.4.2)
set(NCEPLIBS-g2tmpl_tag v1.10.0)
set(NCEPLIBS-gfsio_tag  v1.4.1)
set(NCEPLIBS-ip_tag     v3.3.3)
set(NCEPLIBS-nemsio_tag v2.5.2)
set(NCEPLIBS-sfcio_tag  v1.4.1)
set(NCEPLIBS-sigio_tag  v2.3.2)
set(NCEPLIBS-sp_tag     v2.3.3)
set(NCEPLIBS-w3emc_tag  v2.7.3)
set(NCEPLIBS-w3nco_tag  v2.4.1)
set(UPP_tag             upp_v10.0.8)

foreach(lib_name
                 EMC_crtm
                 NCEPLIBS-bacio
                 NCEPLIBS-g2
                 NCEPLIBS-g2tmpl
                 NCEPLIBS-gfsio
                 NCEPLIBS-ip
                 NCEPLIBS-nemsio
                 NCEPLIBS-sfcio
                 NCEPLIBS-sigio
                 NCEPLIBS-sp
                 NCEPLIBS-w3emc
                 NCEPLIBS-w3nco
                 UPP)

    ExternalProject_Add(${lib_name}
        GIT_REPOSITORY https://github.com/NOAA-EMC/${lib_name}
        GIT_TAG ${${lib_name}_tag}
        GIT_SUBMODULES_RECURSE ON
        BUILD_IN_SOURCE OFF
        CMAKE_ARGS -DCMAKE_PREFIX_PATH=${install_prefix} -DCMAKE_INSTALL_PREFIX=${install_prefix}
        LOG_DOWNLOAD ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
    )

endforeach()

ExternalProject_Add_StepDependencies(NCEPLIBS-g2     build jasper libpng)
ExternalProject_Add_StepDependencies(NCEPLIBS-ip     build NCEPLIBS-sp)
ExternalProject_Add_StepDependencies(NCEPLIBS-nemsio build NCEPLIBS-bacio NCEPLIBS-w3nco)
ExternalProject_Add_StepDependencies(NCEPLIBS-w3emc  build NCEPLIBS-nemsio NCEPLIBS-sigio netcdf_fortran)
ExternalProject_Add_StepDependencies(UPP             build NCEPLIBS-bacio EMC_crtm NCEPLIBS-gfsio NCEPLIBS-g2tmpl NCEPLIBS-g2 NCEPLIBS-ip NCEPLIBS-nemsio NCEPLIBS-sfcio NCEPLIBS-sigio netcdf_fortran)

##
## wgrib2
##
if(${CMAKE_C_COMPILER_ID} STREQUAL "Intel")
    set(CC_wgrib2 "icc")
    set(FC_wgrib2 "ifort")
    set(COMP_SYS_wgrib2 "intel_linux")
elseif(${CMAKE_C_COMPILER_ID} STREQUAL "GNU")
    set(CC_wgrib2 "gcc")
    set(FC_wgrib2 "gfortran")
    set(COMP_SYS_wgrib2 "gnu_linux")
else()
    message(FATAL_ERROR "Unknown compiler ${CMAKE_C_COMPILER_ID}")
endif()
ExternalProject_Add(wgrib2
    URL https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz.v3.1.0
    URL_HASH MD5=974265296ae0789d2f84af8908524f50
    DOWNLOAD_NAME wgrib2.tar.gz
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND
        COMMAND sed -i "s/^USE_NETCDF3=.*/USE_NETCDF3=0/" makefile
        COMMAND sed -i "s/^USE_IPOLATES=.*/USE_IPOLATES=0/" makefile
        COMMAND sed -i "s/^USE_SPECTRAL=.*/USE_SPECTRAL=0/" makefile
        COMMAND sed -i "s/^USE_AEC=.*/USE_AEC=0/" makefile
    BUILD_COMMAND
        COMMAND env CC=${CC_wgrib2} FC=${FC_wgrib2} COMP_SYS=${COMP_SYS_wgrib2} make
        COMMAND env CC=${CC_wgrib2} FC=${FC_wgrib2} COMP_SYS=${COMP_SYS_wgrib2} make lib
    INSTALL_COMMAND
        COMMAND ${CMAKE_COMMAND} -E copy wgrib2/wgrib2 ${install_prefix}/bin
        COMMAND ${CMAKE_COMMAND} -E copy lib/libwgrib2.a ${install_prefix}/lib
        COMMAND ${CMAKE_COMMAND} -E copy lib/wgrib2api.mod lib/wgrib2lowapi.mod ${install_prefix}/include
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## ecbuild
##
ExternalProject_Add(ecbuild
    URL https://github.com/ecmwf/ecbuild/archive/refs/tags/3.6.1.tar.gz
    URL_HASH MD5=2cdf9ab9efd0b397dc8bf7ec01a949c5
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}
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
    URL https://github.com/GEOS-ESM/ESMA_cmake/archive/refs/tags/v3.4.3.tar.gz
    URL_HASH MD5=6a5266894bb72a3f9bc5d8dec1bd03b6
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
    GIT_TAG v1.3.0
    GIT_SUBMODULES_RECURSE ON
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## yafyaml
##
ExternalProject_Add(yafyaml
    URL https://github.com/Goddard-Fortran-Ecosystem/yaFyaml/archive/refs/tags/v0.5.1.tar.gz
    URL_HASH MD5=1003ea71ad5ab5dd76827ee941a84b97
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}
               -DCMAKE_PREFIX_PATH=${install_prefix}
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
    URL https://github.com/GEOS-ESM/MAPL/archive/refs/tags/v2.7.3.tar.gz
    URL_HASH MD5=2f3d5ff5f3a46df2c4b38669c4cffa4c
    BUILD_IN_SOURCE OFF
    LIST_SEPARATOR ,
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}
               -DCMAKE_MODULE_PATH=${install_prefix}/esma_cmake,${install_prefix}/cmakemodules/Modules,${install_prefix}/share/ecbuild/cmake
               -DCMAKE_PREFIX_PATH=${install_prefix}
               -DCMAKE_BUILD_TYPE=Release
               -DBUILD_WITH_FLAP=OFF
               -DBUILD_WITH_PFLOGGER=OFF
               -DESMA_USE_GFE_NAMESPACE=ON
               -DBUILD_SHARED_MAPL=OFF
               -DESMFMKFILE=${install_prefix}/lib/esmf.mk
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(mapl build esmf ecbuild cmakemodules esma_cmake yafyaml)