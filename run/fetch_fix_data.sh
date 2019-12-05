#!/bin/bash
set -eux

source configuration.sh

rm -rf ${FIX_DATA}
mkdir -p ${FIX_DATA}
cd ${FIX_DATA}

FIX_URL="https://ftp.emc.ncep.noaa.gov/EIB/UFS/global/fix"

OROG_FILES="
gmted2010.30sec.int
landcover30.fixed
thirty.second.antarctic.new.bin
"

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

FIX_AM_FILES="
CFSR.SEAICE.1982.2012.monthly.clim.grb
RTGSST.1982.2012.monthly.clim.grb
cfs_ice1x1monclim19822001.grb
cfs_oi2sst1x1monclim19822001.grb
co2monthlycyc.txt
global_albedo4.1x1.grb
global_climaeropac_global.txt
global_co2historicaldata_2013.txt
global_co2historicaldata_glob.txt
global_co2monthlycyc1976_2009.txt
global_glacier.2x2.grb
global_hyblev.l65.txt
global_maxice.2x2.grb
global_mxsnoalb.uariz.t126.384.190.rg.grb
global_o3prdlos.f77
global_sfc_emissivity_idx.txt
global_sfc_emissivity_idx.txt
global_shdmax.0.144x0.144.grb
global_shdmin.0.144x0.144.grb
global_slmask.t1534.3072.1536.grb
global_slope.1x1.grb
global_snoclim.1.875.grb
global_snowfree_albedo.bosu.t126.384.190.rg.grb
global_soilmgldas.statsgo.t1534.3072.1536.grb
global_soilmgldas.t126.384.190.grb
global_soiltype.statsgo.t126.384.190.rg.grb
global_solarconstant_noaa_an.txt
global_tg3clim.2.6x1.5.grb
global_vegfrac.0.144.decpercent.grb
global_vegtype.igbp.t126.384.190.rg.grb
global_zorclim.1x1.grb
seaice_newland.grb
"

rm -rf fix_orog
mkdir fix_orog
for file in ${OROG_FILES}; do
    curl -f -s -S -R -L ${FIX_URL}/fix_orog/${file} -o fix_orog/${file}
done


rm -rf fix_sfc_climo
mkdir -p fix_sfc_climo
for file in ${SFC_CLIMO_FILES}; do
    curl -f -s -S -R -L ${FIX_URL}/fix_sfc_climo/${file} -o fix_sfc_climo/${file}
done


rm -rf fix_am
mkdir -p fix_am
for file in ${FIX_AM_FILES}; do
    curl -f -s -S -R -L ${FIX_URL}/fix_am/${file} -o fix_am/${file}
done

cd fix_am
ln -s global_mxsnoalb.uariz.t126.384.190.rg.grb        global_mxsnoalb.uariz.t190.384.192.rg.grb
ln -s global_snowfree_albedo.bosu.t126.384.190.rg.grb  global_snowfree_albedo.bosu.t190.384.192.rg.grb
ln -s global_soilmgldas.t126.384.190.grb               global_soilmgldas.t190.384.192.grb
ln -s global_soiltype.statsgo.t126.384.190.rg.grb      global_soiltype.statsgo.t190.384.192.rg.grb
ln -s global_vegtype.igbp.t126.384.190.rg.grb          global_vegtype.igbp.t190.384.192.rg.grb
