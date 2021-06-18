#!/bin/bash
set -eux

source configuration.sh

FIX_URL="https://ftp.emc.ncep.noaa.gov/static_files/public/UFS/MRW/fix"

rm -rf ${FIX_DATA}
mkdir -p ${FIX_DATA}
cd ${FIX_DATA}

(
#  rm -rf ${GRID_OROG_DATA}
#  mkdir -p ${GRID_OROG_DATA}
#  cd ${GRID_OROG_DATA}

  rm -rf fix_fv3_gmted2010
  mkdir fix_fv3_gmted2010
  cd fix_fv3_gmted2010

  #for res in 96 192; do
  for res in ${res}; do
  (
    FIX_FV3_FILES="
    C${res}_grid.tile[1-6].nc
    C${res}_mosaic.nc
    C${res}_oro_data.tile[1-6].nc
    "
    mkdir -p C${res}
    cd C${res}
    for file in ${FIX_FV3_FILES}; do
        curl -f -s -S -R -L -O ${FIX_URL}/fix_fv3_gmted2010/C${res}/${file}
    done

    FIX_FV3_FIX_SFC_FILES="
    C${res}.facsf.tile[1-6].nc
    C${res}.maximum_snow_albedo.tile[1-6].nc
    C${res}.slope_type.tile[1-6].nc
    C${res}.snowfree_albedo.tile[1-6].nc
    C${res}.soil_type.tile[1-6].nc
    C${res}.substrate_temperature.tile[1-6].nc
    C${res}.substrate_temperature.tile[1-6].nc
    C${res}.vegetation_greenness.tile[1-6].nc
    C${res}.vegetation_type.tile[1-6].nc
    "
    mkdir -p fix_sfc
    cd fix_sfc
    for file in ${FIX_FV3_FIX_SFC_FILES}; do
        curl -f -s -S -R -L -O ${FIX_URL}/fix_fv3_gmted2010/C${res}/fix_sfc/${file}
    done
  )
  done # res
)

(
  rm -rf fix_am
  mkdir -p fix_am

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
        curl -f -s -S -R -L ${FIX_URL}/fix_am/${file} -o fix_am/${file}
    done

    # cd fix_am
    # ln -s global_mxsnoalb.uariz.t126.384.190.rg.grb        global_mxsnoalb.uariz.t190.384.192.rg.grb
    # ln -s global_snowfree_albedo.bosu.t126.384.190.rg.grb  global_snowfree_albedo.bosu.t190.384.192.rg.grb
    # ln -s global_soilmgldas.t126.384.190.grb               global_soilmgldas.t190.384.192.grb
    # ln -s global_soiltype.statsgo.t126.384.190.rg.grb      global_soiltype.statsgo.t190.384.192.rg.grb
    # ln -s global_vegtype.igbp.t126.384.190.rg.grb          global_vegtype.igbp.t190.384.192.rg.grb

  done # res
)

if [[ $gtype == regional* ]]; then
(
    OROG_FILES="
    gmted2010.30sec.int
    landcover30.fixed
    thirty.second.antarctic.new.bin
    "
    rm -rf fix_orog
    mkdir fix_orog
    for file in ${OROG_FILES}; do
        curl -f -s -S -R -L ${FIX_URL}/fix_orog/${file} -o fix_orog/${file}
    done

    SFC_CLIMO_FILES="
    facsf.1.0.nc
    maximum_snow_albedo.0.05.nc
    slope_type.1.0.nc
    snowfree_albedo.4comp.0.05.nc
    soil_type.statsgo.0.05.nc
    substrate_temperature.2.6x1.5.nc
    vegetation_greenness.0.144.nc
    vegetation_type.igbp.0.05.nc
    "
    rm -rf fix_sfc_climo
    mkdir -p fix_sfc_climo
    for file in ${SFC_CLIMO_FILES}; do
        curl -f -s -S -R -L ${FIX_URL}/fix_sfc_climo/${file} -o fix_sfc_climo/${file}
    done
)
fi

