#!/bin/bash
set -eux

if [[ $(uname -s) == Linux ]]; then
ulimit -s unlimited
fi

source configuration.sh

MYDIR=$(pwd)

MODEL_RUN_DIR=${MYDIR}/model_run
rm -rf ${MODEL_RUN_DIR}
mkdir -p ${MODEL_RUN_DIR}

INPUT_MODEL=${MODEL_RUN_DIR}/INPUT
mkdir -p ${INPUT_MODEL}

mkdir -p ${MODEL_RUN_DIR}/RESTART

#
# Copy static grid, orog data to model_run/INPUT directory
#

cd ${INPUT_MODEL}

export out_dir=${GRID_OROG_DATA}/C${res}
export halo=3

if [[ $gtype == "uniform" ]]; then

  cp ${out_dir}/C${res}* .
  mv C${res}_mosaic.nc          grid_spec.nc
  mv C${res}_oro_data.tile1.nc  oro_data.tile1.nc
  mv C${res}_oro_data.tile2.nc  oro_data.tile2.nc
  mv C${res}_oro_data.tile3.nc  oro_data.tile3.nc
  mv C${res}_oro_data.tile4.nc  oro_data.tile4.nc
  mv C${res}_oro_data.tile5.nc  oro_data.tile5.nc
  mv C${res}_oro_data.tile6.nc  oro_data.tile6.nc

elif [[ $gtype == "regional" ]]; then

  HALO=$(( halo + 1 ))

  cp ${out_dir}/C${res}* .
  rm -f  C${res}_grid.tile7.halo0.nc
  rm -f  C${res}_oro_data.tile7.halo${halo}.nc
  ln -sf C${res}_mosaic.nc                      grid_spec.nc
  ln -sf C${res}_grid.tile7.halo${halo}.nc      C${res}_grid.tile7.nc
  ln -sf C${res}_grid.tile7.halo${HALO}.nc      grid.tile7.halo${HALO}.nc
  ln -sf C${res}_oro_data.tile7.halo0.nc        oro_data.nc
  ln -sf C${res}_oro_data.tile7.halo${HALO}.nc  oro_data.tile7.halo${HALO}.nc

fi

#
# Copy input data (created by chgres_cube) to model run directory
#
export DATA=${MYDIR}/chgres_run

if [[ $gtype == "uniform" ]]; then
    cp ${DATA}/gfs_ctrl.nc       .
    cp ${DATA}/gfs_data.tile?.nc      .
    cp ${DATA}/sfc_data.tile?.nc      .
elif [[ $gtype == "regional" ]]; then
    cp ${DATA}/gfs_ctrl.nc            .
    cp ${DATA}/gfs_data.tile7.nc      .
    cp ${DATA}/sfc_data.tile7.nc      .
    cp ${DATA}/gfs_bndy.tile7.???.nc  .
    ln -sf gfs_data.tile7.nc          gfs_data.nc
    ln -sf sfc_data.tile7.nc          sfc_data.nc
fi

cd ${MODEL_RUN_DIR}

NPX=$(( $res + 1 ))
NPY=$(( $res + 1 ))

case $res in
  96)
    JCAP=126
    LONB=384
    LATB=190
    DT_ATMOS=1200
    ;;
  192)
    JCAP=382
    LONB=768
    LATB=384
    DT_ATMOS=600
    ;;
  *)
    echo "Unsuppored resolution ${res}"
    exit 1
    ;;
esac

IMO=${LONB}
JMO=${LATB}

FNABSC="global_mxsnoalb.uariz.t${JCAP}.${LONB}.${LATB}.rg.grb"
FNALBC="global_snowfree_albedo.bosu.t${JCAP}.${LONB}.${LATB}.rg.grb"
FNVETC="global_vegtype.igbp.t${JCAP}.${LONB}.${LATB}.rg.grb"
FNSOTC="global_soiltype.statsgo.t${JCAP}.${LONB}.${LATB}.rg.grb"
FNSMCC="global_soilmgldas.t${JCAP}.${LONB}.${LATB}.grb"

cp ${FIX_DATA}/fix_am/global_climaeropac_global.txt             aerosol.dat
cp ${FIX_DATA}/fix_am/CFSR.SEAICE.1982.2012.monthly.clim.grb    .
cp ${FIX_DATA}/fix_am/global_co2historicaldata_2013.txt         co2historicaldata_2013.txt
cp ${FIX_DATA}/fix_am/RTGSST.1982.2012.monthly.clim.grb         .
cp ${FIX_DATA}/fix_am/global_albedo4.1x1.grb                    .
cp ${FIX_DATA}/fix_am/global_co2historicaldata_glob.txt         co2historicaldata_glob.txt
cp ${FIX_DATA}/fix_am/co2monthlycyc.txt                         .
cp ${FIX_DATA}/fix_am/global_glacier.2x2.grb                    .
cp ${FIX_DATA}/fix_am/global_maxice.2x2.grb                     .
cp ${FIX_DATA}/fix_am/global_o3prdlos.f77                       .
cp ${FIX_DATA}/fix_am/global_shdmax.0.144x0.144.grb             .
cp ${FIX_DATA}/fix_am/global_shdmin.0.144x0.144.grb             .
cp ${FIX_DATA}/fix_am/global_slope.1x1.grb                      .
cp ${FIX_DATA}/fix_am/global_snoclim.1.875.grb                  .
cp ${FIX_DATA}/fix_am/global_solarconstant_noaa_an.txt          solarconstant_noaa_an.txt
cp ${FIX_DATA}/fix_am/global_tg3clim.2.6x1.5.grb                .
cp ${FIX_DATA}/fix_am/global_vegfrac.0.144.decpercent.grb       .
cp ${FIX_DATA}/fix_am/global_sfc_emissivity_idx.txt             sfc_emissivity_idx.txt

cp ${FIX_DATA}/fix_am/${FNABSC}                                 .
cp ${FIX_DATA}/fix_am/global_slmask.t1534.3072.1536.grb         .
cp ${FIX_DATA}/fix_am/${FNALBC}                                 .
cp ${FIX_DATA}/fix_am/${FNSMCC}                                 .
cp ${FIX_DATA}/fix_am/${FNSOTC}                                 .
cp ${FIX_DATA}/fix_am/${FNVETC}                                 .

if [[ $gtype == "uniform" ]]; then
   cp ${MYDIR}/global_conf/* .
elif [[ $gtype == "regional" ]]; then
   cp ${MYDIR}/regional_conf/* .
fi

sed -i -e "s/_START_YEAR_/${START_YEAR}/g
           s/_START_MONTH_/${START_MONTH}/g
           s/_START_DAY_/${START_DAY}/g
           s/_START_HOUR_/${START_HOUR}/g
           s/_NHOURS_FCST_/${NHOURS_FCST}/g
           s/_DT_ATMOS_/${DT_ATMOS}/g
           s/_IMO_/${IMO}/g
           s/_JMO_/${JMO}/g" model_configure

sed -i -e "s/_BC_INT_/${BC_INT}/g
           s/_NPX_/${NPX}/g
           s/_NPY_/${NPY}/g
           s/_FNABSC_/"${FNABSC}"/g
           s/_FNALBC_/"${FNALBC}"/g
           s/_FNSMCC_/"${FNSMCC}"/g
           s/_FNSOTC_/"${FNSOTC}"/g
           s/_FNVETC_/"${FNVETC}"/g" input.nml

sed -i -e "s/_START_YEAR_/${START_YEAR}/g
           s/_START_MONTH_/${START_MONTH}/g
           s/_START_DAY_/${START_DAY}/g
           s/_START_HOUR_/${START_HOUR}/g
           s/_NHOURS_FCST_/${NHOURS_FCST}/g" diag_table

#
# Finally we have all necessary input data.
# Let's run the model, that's why we are here.
#
mpiexec -np 8 ${sufs}/bin/ufs_model 1> stdout 2> stderr

echo "Done!"
