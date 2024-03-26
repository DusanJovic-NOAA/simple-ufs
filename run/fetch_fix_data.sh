#!/bin/bash
set -eux

source configuration.sh

FIX_URL="https://noaa-nws-global-pds.s3.amazonaws.com/fix"

rm -rf ${FIX_DATA}
mkdir -p ${FIX_DATA}
cd ${FIX_DATA}

(
  rm -rf am/20220805
  mkdir -p am/20220805
  cd am/20220805

  #for res in 96 192; do
  for res in ${res}; do

    # C96   t126.384.190    (t190.384.192)
    # C192  t382.768.384
    # C384  t766.1536.768
    # C768  t1534.3072.1536

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
      *)
        echo "Unsuppored resolution ${res}"
        exit 1
        ;;
    esac

    FIX_AM_FILES="
    CFSR.SEAICE.1982.2012.monthly.clim.grb
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
        curl -f -s -S -R -L -C - -O ${FIX_URL}/am/20220805/${file}
    done

  done # res
)

if [[ $gtype == uniform ]]; then
(
  rm -rf orog/20231027
  mkdir -p orog/20231027
  cd orog/20231027

  #for res in 96 192; do
  for res in ${res}; do
  (
    FIX_FV3_FILES="
    C${res}_grid.tile[1-6].nc
    C${res}_mosaic.nc
    C${res}.mx${ocn}_oro_data.tile[1-6].nc
    "
    mkdir -p C${res}
    cd C${res}
    for file in ${FIX_FV3_FILES}; do
        curl -f -s -S -R -L -C - -O ${FIX_URL}/orog/20231027/C${res}/${file}
    done

    FIX_FV3_FIX_SFC_FILES="
    C${res}.mx${ocn}.facsf.tile[1-6].nc
    C${res}.mx${ocn}.maximum_snow_albedo.tile[1-6].nc
    C${res}.mx${ocn}.slope_type.tile[1-6].nc
    C${res}.mx${ocn}.snowfree_albedo.tile[1-6].nc
    C${res}.mx${ocn}.soil_type.tile[1-6].nc
    C${res}.mx${ocn}.substrate_temperature.tile[1-6].nc
    C${res}.mx${ocn}.vegetation_greenness.tile[1-6].nc
    C${res}.mx${ocn}.vegetation_type.tile[1-6].nc
    "
    mkdir -p sfc
    cd sfc
    for file in ${FIX_FV3_FIX_SFC_FILES}; do
        curl -f -s -S -R -L -C - -O ${FIX_URL}/orog/20231027/C${res}/sfc/${file}
    done
  )
  done # res
)
elif [[ $gtype == regional* ]]; then
(
    # redefine s3 bucket to SRW
    FIX_URL="https://noaa-ufs-srw-pds.s3.amazonaws.com/fix"
    OROG_FILES="
    topography.gmted2010.30s.nc
    landcover.umd.30s.nc
    topography.antarctica.ramp.30s.nc
    "
    # gmted2010.30sec.int
    # landcover30.fixed
    # thirty.second.antarctic.new.bin
    rm -rf raw/orog
    mkdir -p raw/orog
    cd raw/orog
    for file in ${OROG_FILES}; do
        curl -f -s -S -R -L -C - -O ${FIX_URL}/fix_orog/${file}
    done
    cd ../..

    SFC_CLIMO_FILES="
    facsf.1.0.nc
    maximum_snow_albedo.0.05.nc
    slope_type.1.0.nc
    snowfree_albedo.4comp.0.05.nc
    soil_type.statsgo.0.05.nc
    substrate_temperature.2.6x1.5.nc
    vegetation_greenness.0.144.nc
    vegetation_type.modis.igbp.0.05.nc
    "
    rm -rf sfc_climo/20230925
    mkdir -p sfc_climo/20230925
    cd sfc_climo/20230925
    for file in ${SFC_CLIMO_FILES}; do
        curl -f -s -S -R -L -C - -O ${FIX_URL}/fix_sfc_climo/${file}
    done
    cd ../..
)
else
    echo "Unknown gtype $gtype"
    exit 1
fi

