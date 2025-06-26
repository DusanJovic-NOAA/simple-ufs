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

download_and_check_md5sum 63251602329a106220e0a5ad26ba656f  https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz               zstd.tar.gz
download_and_check_md5sum 9c7d356c5acaa563555490676ca14d23  https://github.com/madler/zlib/archive/refs/tags/v1.2.13.tar.gz                           zlib.tar.gz
download_and_check_md5sum dead9f5f1966d9ae56e1e32761e4e675  https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz                    lz4.tar.gz
download_and_check_md5sum 2c6017d275146f8792fa448227a7c373  https://github.com/jasper-software/jasper/archive/refs/tags/version-2.0.32.tar.gz         jasper.tar.gz
download_and_check_md5sum 564aa9f6c678dbb016b07ecfae8b7245  https://github.com/glennrp/libpng/archive/refs/tags/v1.6.37.tar.gz                        libpng.tar.gz

download_and_check_md5sum 73b513b9c40a8ca2913fcb38570ecdbd  https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5_1.14.6.tar.gz                     hdf5.tar.gz
download_and_check_md5sum 84acd096ab4f3300c20db862eecdf7c7  https://github.com/Unidata/netcdf-c/archive/v4.9.2.tar.gz                                 netcdf.tar.gz
download_and_check_md5sum 8c200fcf7d9d2761037dfd2dabe2216b  https://github.com/Unidata/netcdf-fortran/archive/v4.6.1.tar.gz                           netcdf_fortran.tar.gz

download_and_check_md5sum a3c39f002a7a81882b65b7eb8c9a7d91  https://github.com/CESM-Development/CMake_Fortran_utils/archive/refs/tags/CMake_Fortran_utils_150308.tar.gz cmake_fortran_utils.tar.gz
download_and_check_md5sum bb4552a07eadb6c5a54677f96282489d  https://parallel-netcdf.github.io/Release/pnetcdf-1.12.3.tar.gz                           pnetcdf.tar.gz
download_and_check_md5sum 7f3504dfb5aab846f4a9018dda7bb8ad  https://github.com/PARALLELIO/genf90/archive/refs/tags/genf90_200608.tar.gz               genf90.tar.gz
download_and_check_md5sum b16e88125fbb7e5bd06e8f392f91ae26  https://github.com/NCAR/ParallelIO/archive/refs/tags/pio2_6_2.tar.gz                      pio.tar.gz

download_and_check_md5sum 82a26e62825d4439b58535d9b29da7a4  https://github.com/NOAA-GFDL/FMS/archive/refs/tags/2024.01.tar.gz                         fms.tar.gz
download_and_check_md5sum 6308b2a13d151475a4f2ecb3eb6cbebe  https://github.com/esmf-org/esmf/archive/refs/tags/v8.8.0.tar.gz                          esmf.tar.gz


download_and_check_md5sum 95bab417fbaf7c1f6f99316052189bea  https://github.com/NOAA-EMC/NCEPLIBS-bacio/archive/refs/tags/v2.4.1.tar.gz                bacio.tar.gz
download_and_check_md5sum 9931fb0740e66d3bfc09fb6cb842532b  https://github.com/NOAA-EMC/NCEPLIBS-g2/archive/refs/tags/v3.5.1.tar.gz                   g2.tar.gz
download_and_check_md5sum dd40b6ff5d08f76e71475c24a81ea2a3  https://github.com/NOAA-EMC/NCEPLIBS-g2tmpl/archive/refs/tags/v1.13.0.tar.gz              g2tmpl.tar.gz
download_and_check_md5sum e19101124af68ee6a8f9c8051aa3aa6a  https://github.com/NOAA-EMC/NCEPLIBS-ip/archive/refs/tags/v4.3.0.tar.gz                   ip.tar.gz
download_and_check_md5sum fc50806fb552b114a9f18d57ad3747a7  https://github.com/NOAA-EMC/NCEPLIBS-sp/archive/refs/tags/v2.5.0.tar.gz                   sp.tar.gz
download_and_check_md5sum ab162725c04899b8295bd74ed184debf  https://github.com/NOAA-EMC/NCEPLIBS-w3emc/archive/refs/tags/v2.12.0.tar.gz               w3emc.tar.gz

download_and_check_md5sum bca66a095f903c0aca728d4cdbe76ae5  https://github.com/JCSDA/CRTMv3/archive/refs/tags/v3.1.2.tar.gz                           crtm.tar.gz

download_and_check_md5sum 7a7b4138e0c7e68abcd64e56002cbfcf  https://github.com/ecmwf/ecbuild/archive/refs/tags/3.7.2.tar.gz                           ecbuild.tar.gz
download_and_check_md5sum 3921ba13701606cc0e55dc046508f66d  https://github.com/GEOS-ESM/ESMA_cmake/archive/refs/tags/v3.55.0.tar.gz                   esma_cmake.tar.gz
download_and_check_md5sum 2f29353658bc8a40cdd453b7870c06ab  https://github.com/Goddard-Fortran-Ecosystem/gFTL/archive/refs/tags/v1.14.0.tar.gz        gftl.tar.gz
download_and_check_md5sum 4f9413fa40962ea17b37706296c0263e  https://github.com/Goddard-Fortran-Ecosystem/gFTL-shared/archive/refs/tags/v1.9.0.tar.gz  gftl_shared.tar.gz
download_and_check_md5sum 58259d94f766c13b5b0cf1aed92ebbe3  https://downloads.unidata.ucar.edu/udunits/2.2.28/udunits-2.2.28.tar.gz                   udunits.tar.gz
download_and_check_md5sum 2277e5fc3128cda361403c5f202bf9cd  https://github.com/GEOS-ESM/MAPL/archive/refs/tags/v2.53.4.tar.gz                         mapl.tar.gz

download_and_check_md5sum d94a92c7206139d2b9dafab64d9c75bf  https://gitlab.inria.fr/scotch/scotch/-/archive/v7.0.7/scotch-v7.0.7.tar.gz               scotch.tar.gz
