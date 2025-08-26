#!/bin/bash
set -eu
# set -x

source configuration.sh

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


readonly FIX_URL="https://noaa-nws-global-pds.s3.amazonaws.com/fix"

mkdir -p "${FIX_DATA}/am/20220805"

#for res in 96 192; do
for res in ${res}; do

  # C96   t126.384.190    (t190.384.192)
  # C192  t382.768.384
  # C384  t766.1536.768
  # C768  t1534.3072.1536
  # C1152 t1534.3072.1536

  case $res in
    48)
      JCAP=92
      LONB=192
      LATB=94
      ;;
    96)
      JCAP=126
      LONB=384
      LATB=190
      ;;
    192)
      JCAP=382
      LONB=768
      LATB=384
      ;;
    384)
      JCAP=766
      LONB=1536
      LATB=768
      ;;
    768)
      JCAP=1534
      LONB=3072
      LATB=1536
      ;;
    1152)
      JCAP=1534
      LONB=3072
      LATB=1536
      ;;
    *)
      echo "Unsuppored resolution ${res}"
      exit 1
      ;;
  esac

  FIX_AM_FILES="
  CFSR.SEAICE.1982.2012.monthly.clim.grb
  IMS-NIC.blended.ice.monthly.clim.grb
  RTGSST.1982.2012.monthly.clim.grb
  co2monthlycyc.txt
  global_albedo4.1x1.grb
  global_climaeropac_global.txt
  global_co2historicaldata_2013.txt
  global_co2historicaldata_glob.txt
  global_glacier.2x2.grb
  global_h2o_pltc.f77
  global_hyblev.l28.txt
  global_hyblev.l42.txt
  global_hyblev.l65.txt
  global_hyblev.l128.txt
  global_maxice.2x2.grb
  global_sfc_emissivity_idx.txt
  global_shdmax.0.144x0.144.grb
  global_shdmin.0.144x0.144.grb
  global_slope.1x1.grb
  global_snoclim.1.875.grb
  global_solarconstant_noaa_an.txt
  global_tg3clim.2.6x1.5.grb
  global_vegfrac.0.144.decpercent.grb

  global_slmask.t1534.3072.1536.grb

  global_o3prdlos.f77
  ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77

  global_mxsnoalb.uariz.t${JCAP}.${LONB}.${LATB}.rg.grb
  global_snowfree_albedo.bosu.t${JCAP}.${LONB}.${LATB}.rg.grb
  global_soilmgldas.t${JCAP}.${LONB}.${LATB}.grb
  global_soiltype.statsgo.t${JCAP}.${LONB}.${LATB}.rg.grb
  global_vegtype.igbp.t${JCAP}.${LONB}.${LATB}.rg.grb
  "
  for file in ${FIX_AM_FILES}; do
      lfile="am/20220805/${file}"
      checksum=$( grep ${lfile} fix_data.md5sum | awk '{print $1}' )
      download_and_check_md5sum ${checksum} ${FIX_URL}/${lfile} fix_data/${lfile}
  done

done # res


if [[ $gtype == uniform ]]; then

  #for res in 96 192; do
  for res in ${res}; do

    FIX_FV3_FILES=(
    "C${res}_grid.tile"{1..6}".nc"
    "C${res}_mosaic.nc"
    "C${res}.mx${ocn}_oro_data.tile"{1..6}".nc"
    )
    mkdir -p ${FIX_DATA}/orog/20231027/C${res}
    for file in "${FIX_FV3_FILES[@]}"; do
        lfile="orog/20231027/C${res}/${file}"
        checksum=$( grep ${lfile} fix_data.md5sum | awk '{print $1}' )
        download_and_check_md5sum ${checksum} ${FIX_URL}/${lfile} fix_data/${lfile}
    done

    FIX_FV3_FIX_SFC_FILES=(
    "C${res}.mx${ocn}.facsf.tile"{1..6}".nc"
    "C${res}.mx${ocn}.maximum_snow_albedo.tile"{1..6}".nc"
    "C${res}.mx${ocn}.slope_type.tile"{1..6}".nc"
    "C${res}.mx${ocn}.snowfree_albedo.tile"{1..6}".nc"
    "C${res}.mx${ocn}.soil_color.tile"{1..6}".nc"
    "C${res}.mx${ocn}.soil_type.tile"{1..6}".nc"
    "C${res}.mx${ocn}.substrate_temperature.tile"{1..6}".nc"
    "C${res}.mx${ocn}.vegetation_greenness.tile"{1..6}".nc"
    "C${res}.mx${ocn}.vegetation_type.tile"{1..6}".nc"
    )
    mkdir -p ${FIX_DATA}/orog/20231027/C${res}/sfc
    for file in "${FIX_FV3_FIX_SFC_FILES[@]}"; do
        lfile="orog/20231027/C${res}/sfc/${file}"
        checksum=$( grep ${lfile} fix_data.md5sum | awk '{print $1}' )
        download_and_check_md5sum ${checksum} ${FIX_URL}/${lfile} fix_data/${lfile}
    done

  done # res

elif [[ $gtype == regional* ]]; then

    OROG_FILES="
    topography.gmted2010.30s.nc
    landcover.umd.30s.nc
    topography.antarctica.ramp.30s.nc
    "
    mkdir -p ${FIX_DATA}/orog/20240917
    for file in ${OROG_FILES}; do
        lfile="orog/20240917/${file}"
        checksum=$( grep ${lfile} fix_data.md5sum | awk '{print $1}' )
        download_and_check_md5sum ${checksum} ${FIX_URL}/${lfile} fix_data/${lfile}
    done

    SFC_CLIMO_FILES="
    facsf.1.0.nc
    maximum_snow_albedo.0.05.nc
    slope_type.1.0.nc
    snowfree_albedo.4comp.0.05.nc
    soil_type.statsgo.0.05.nc
    soil_color.clm.0.05.nc
    substrate_temperature.gfs.0.5.nc
    vegetation_greenness.0.144.nc
    vegetation_type.modis.igbp.0.05.nc
    "
    mkdir -p ${FIX_DATA}/sfc_climo/20230925
    for file in ${SFC_CLIMO_FILES}; do
        lfile="sfc_climo/20230925/${file}"
        checksum=$( grep ${lfile} fix_data.md5sum | awk '{print $1}' )
        download_and_check_md5sum ${checksum} ${FIX_URL}/${lfile} fix_data/${lfile}
    done

else
    echo "Unknown gtype $gtype"
    exit 1
fi

echo "Done!"
