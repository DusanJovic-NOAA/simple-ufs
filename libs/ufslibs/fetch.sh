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
download_and_check_md5sum 2c6017d275146f8792fa448227a7c373  https://github.com/jasper-software/jasper/archive/refs/tags/version-2.0.32.tar.gz         jasper.tar.gz
download_and_check_md5sum 564aa9f6c678dbb016b07ecfae8b7245  https://github.com/glennrp/libpng/archive/refs/tags/v1.6.37.tar.gz                        libpng.tar.gz

download_and_check_md5sum f1eaf87cc338475deb4aa48fb17cb8f8  https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5_1.14.4.2.tar.gz                   hdf5.tar.gz
download_and_check_md5sum 84acd096ab4f3300c20db862eecdf7c7  https://github.com/Unidata/netcdf-c/archive/v4.9.2.tar.gz                                 netcdf.tar.gz
download_and_check_md5sum 8c200fcf7d9d2761037dfd2dabe2216b  https://github.com/Unidata/netcdf-fortran/archive/v4.6.1.tar.gz                           netcdf_fortran.tar.gz

download_and_check_md5sum a3c39f002a7a81882b65b7eb8c9a7d91  https://github.com/CESM-Development/CMake_Fortran_utils/archive/refs/tags/CMake_Fortran_utils_150308.tar.gz cmake_fortran_utils.tar.gz
download_and_check_md5sum 7f3504dfb5aab846f4a9018dda7bb8ad  https://github.com/PARALLELIO/genf90/archive/refs/tags/genf90_200608.tar.gz               genf90.tar.gz
download_and_check_md5sum 171ee9a2b31a73108314a35b4db1dfaa  https://github.com/NCAR/ParallelIO/archive/refs/tags/pio2_5_10.tar.gz                     pio.tar.gz

download_and_check_md5sum 2725e558eaa53fa1016fe785444759ae  https://github.com/NOAA-GFDL/FMS/archive/refs/tags/2023.04.tar.gz                         fms.tar.gz
download_and_check_md5sum ddf8e428e5d9cc3b17a6ed8408aade41  https://github.com/esmf-org/esmf/archive/refs/tags/v8.6.1.tar.gz                          esmf.tar.gz


download_and_check_md5sum 95bab417fbaf7c1f6f99316052189bea  https://github.com/NOAA-EMC/NCEPLIBS-bacio/archive/refs/tags/v2.4.1.tar.gz                bacio.tar.gz
download_and_check_md5sum 9931fb0740e66d3bfc09fb6cb842532b  https://github.com/NOAA-EMC/NCEPLIBS-g2/archive/refs/tags/v3.5.1.tar.gz                   g2.tar.gz
download_and_check_md5sum dd40b6ff5d08f76e71475c24a81ea2a3  https://github.com/NOAA-EMC/NCEPLIBS-g2tmpl/archive/refs/tags/v1.13.0.tar.gz              g2tmpl.tar.gz
download_and_check_md5sum e19101124af68ee6a8f9c8051aa3aa6a  https://github.com/NOAA-EMC/NCEPLIBS-ip/archive/refs/tags/v4.3.0.tar.gz                   ip.tar.gz
download_and_check_md5sum fc50806fb552b114a9f18d57ad3747a7  https://github.com/NOAA-EMC/NCEPLIBS-sp/archive/refs/tags/v2.5.0.tar.gz                   sp.tar.gz
download_and_check_md5sum ab162725c04899b8295bd74ed184debf  https://github.com/NOAA-EMC/NCEPLIBS-w3emc/archive/refs/tags/v2.12.0.tar.gz               w3emc.tar.gz

download_and_check_md5sum 95a040cdfb0426448f1aab38b0c7601b  https://github.com/JCSDA/crtm/archive/refs/tags/v2.4.0_emc.3.tar.gz                       crtm.tar.gz

download_and_check_md5sum 7a7b4138e0c7e68abcd64e56002cbfcf  https://github.com/ecmwf/ecbuild/archive/refs/tags/3.7.2.tar.gz                           ecbuild.tar.gz
download_and_check_md5sum 042ed33c7f2621cd021cfcf813b2e24b  https://github.com/GEOS-ESM/ESMA_cmake/archive/refs/tags/v3.45.0.tar.gz                   esma_cmake.tar.gz
download_and_check_md5sum e869943e27d5e39db2ffacd960ae3e77  https://github.com/Goddard-Fortran-Ecosystem/gFTL/archive/refs/tags/v1.11.0.tar.gz        gftl.tar.gz
download_and_check_md5sum 7d733037a2a2b62c4221ab924c30915c  https://github.com/Goddard-Fortran-Ecosystem/gFTL-shared/archive/refs/tags/v1.8.0.tar.gz  gftl_shared.tar.gz
download_and_check_md5sum 8ddf81796cb51a5d48c6989fdb639b9d  https://github.com/GEOS-ESM/MAPL/archive/refs/tags/v2.46.3.tar.gz                         mapl.tar.gz
download_and_check_md5sum da80cae85216f666fc31c45558fee832  https://gitlab.inria.fr/scotch/scotch/-/archive/v7.0.4/scotch-v7.0.4.tar.gz               scotch.tar.gz
