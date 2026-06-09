#!/bin/bash

OS=$(uname -s)

download_and_check_md5sum() {
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
            MD5HASH=$(md5 "$OUT_FILE" 2> /dev/null | awk '{print $4}')
        else
            MD5HASH=$(md5sum "$OUT_FILE" 2> /dev/null | awk '{print $1}')
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
                MD5HASH=$(md5 "$OUT_FILE" 2> /dev/null | awk '{print $4}')
            else
                MD5HASH=$(md5sum "$OUT_FILE" 2> /dev/null | awk '{print $1}')
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

mkdir -p downloads
cd downloads || exit

download_and_check_md5sum 780fc1896922b1bc52a4e90980cdda48  https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz               zstd.tar.gz
download_and_check_md5sum 9c7d356c5acaa563555490676ca14d23  https://github.com/madler/zlib/archive/refs/tags/v1.2.13.tar.gz                           zlib.tar.gz
download_and_check_md5sum dead9f5f1966d9ae56e1e32761e4e675  https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz                    lz4.tar.gz
download_and_check_md5sum aa4df693b90223fe6848b34cf1208624  https://github.com/jasper-software/jasper/archive/refs/tags/version-4.2.4.tar.gz          jasper.tar.gz
download_and_check_md5sum 92972b05f1895240139f749ff24afce8  https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.58.tar.gz                       libpng.tar.gz

download_and_check_md5sum 73b513b9c40a8ca2913fcb38570ecdbd  https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5_1.14.6.tar.gz                     hdf5.tar.gz
download_and_check_md5sum 84acd096ab4f3300c20db862eecdf7c7  https://github.com/Unidata/netcdf-c/archive/v4.9.2.tar.gz                                 netcdf.tar.gz
download_and_check_md5sum 8c200fcf7d9d2761037dfd2dabe2216b  https://github.com/Unidata/netcdf-fortran/archive/v4.6.1.tar.gz                           netcdf_fortran.tar.gz

download_and_check_md5sum a3c39f002a7a81882b65b7eb8c9a7d91  https://github.com/CESM-Development/CMake_Fortran_utils/archive/refs/tags/CMake_Fortran_utils_150308.tar.gz cmake_fortran_utils.tar.gz
download_and_check_md5sum bb4552a07eadb6c5a54677f96282489d  https://parallel-netcdf.github.io/Release/pnetcdf-1.12.3.tar.gz                           pnetcdf.tar.gz
download_and_check_md5sum 7f3504dfb5aab846f4a9018dda7bb8ad  https://github.com/PARALLELIO/genf90/archive/refs/tags/genf90_200608.tar.gz               genf90.tar.gz
download_and_check_md5sum b16e88125fbb7e5bd06e8f392f91ae26  https://github.com/NCAR/ParallelIO/archive/refs/tags/pio2_6_2.tar.gz                      pio.tar.gz

download_and_check_md5sum ec14342f320e36749c16a2f97e3e817e  https://github.com/NOAA-GFDL/FMS/archive/refs/tags/2025.03.tar.gz                         fms.tar.gz
download_and_check_md5sum 6c2ce6beef832abb3b10a70c3920ac63  https://github.com/esmf-org/esmf/archive/refs/tags/v8.9.1.tar.gz                          esmf.tar.gz

download_and_check_md5sum 2f069617e16b42f5eddcfee85768f204  https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.12.1.tar.gz               lapack.tar.gz


download_and_check_md5sum ff3634c531758a8c0a7edc7a88a4a4c2  https://github.com/NOAA-EMC/NCEPLIBS-bacio/archive/refs/tags/v2.6.0.tar.gz                bacio.tar.gz
download_and_check_md5sum 9931fb0740e66d3bfc09fb6cb842532b  https://github.com/NOAA-EMC/NCEPLIBS-g2/archive/refs/tags/v3.5.1.tar.gz                   g2.tar.gz
download_and_check_md5sum 3f7a795f17ed08df9a39c020c127cd77  https://github.com/NOAA-EMC/NCEPLIBS-g2tmpl/archive/refs/tags/v1.17.0.tar.gz              g2tmpl.tar.gz
download_and_check_md5sum de2cc3097a96d4f06a467a1ceff2fe26  https://github.com/NOAA-EMC/NCEPLIBS-ip/archive/refs/tags/v5.4.1.tar.gz                   ip.tar.gz
download_and_check_md5sum fc50806fb552b114a9f18d57ad3747a7  https://github.com/NOAA-EMC/NCEPLIBS-sp/archive/refs/tags/v2.5.0.tar.gz                   sp.tar.gz
download_and_check_md5sum b67fc5206ba59eecf78ebf2f5de40584  https://github.com/NOAA-EMC/NCEPLIBS-w3emc/archive/refs/tags/v2.13.0.tar.gz               w3emc.tar.gz

download_and_check_md5sum b4bbe8e0704d4aea096bdf33b9e908af  https://github.com/JCSDA/CRTMv3/archive/refs/tags/v3.1.3.tar.gz                           crtm.tar.gz

download_and_check_md5sum 5be251ee1d93f9e60a3cdcf0f740efa9  https://github.com/libexpat/libexpat/releases/download/R_2_8_1/expat-2.8.1.tar.gz         expat.tar.gz
download_and_check_md5sum 58259d94f766c13b5b0cf1aed92ebbe3  https://downloads.unidata.ucar.edu/udunits/2.2.28/udunits-2.2.28.tar.gz                   udunits.tar.gz

download_and_check_md5sum 7a7b4138e0c7e68abcd64e56002cbfcf  https://github.com/ecmwf/ecbuild/archive/refs/tags/3.7.2.tar.gz                           ecbuild.tar.gz
download_and_check_md5sum 3921ba13701606cc0e55dc046508f66d  https://github.com/GEOS-ESM/ESMA_cmake/archive/refs/tags/v3.55.0.tar.gz                   esma_cmake.tar.gz
download_and_check_md5sum c504f3890c407cf9625066492232dc7d  https://github.com/Goddard-Fortran-Ecosystem/gFTL/archive/refs/tags/v1.16.0.tar.gz        gftl.tar.gz
download_and_check_md5sum a456ae1f6ea8abf525143a1c92f542e2  https://github.com/Goddard-Fortran-Ecosystem/gFTL-shared/archive/refs/tags/v1.11.0.tar.gz gftl_shared.tar.gz
download_and_check_md5sum 2277e5fc3128cda361403c5f202bf9cd  https://github.com/GEOS-ESM/MAPL/archive/refs/tags/v2.53.4.tar.gz                         mapl.tar.gz

download_and_check_md5sum d94a92c7206139d2b9dafab64d9c75bf  https://gitlab.inria.fr/scotch/scotch/-/archive/v7.0.7/scotch-v7.0.7.tar.gz               scotch.tar.gz
