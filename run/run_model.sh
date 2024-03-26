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

halo=3

if [[ $gtype == uniform ]]; then

  cp -r ${GRID_OROG_DATA}/C${res}/* .
  mv C${res}_mosaic.nc                   grid_spec.nc
  mv C${res}.mx${ocn}_oro_data.tile1.nc  oro_data.tile1.nc
  mv C${res}.mx${ocn}_oro_data.tile2.nc  oro_data.tile2.nc
  mv C${res}.mx${ocn}_oro_data.tile3.nc  oro_data.tile3.nc
  mv C${res}.mx${ocn}_oro_data.tile4.nc  oro_data.tile4.nc
  mv C${res}.mx${ocn}_oro_data.tile5.nc  oro_data.tile5.nc
  mv C${res}.mx${ocn}_oro_data.tile6.nc  oro_data.tile6.nc

elif [[ $gtype == regional* ]]; then

  HALO=$(( halo + 1 ))

  NCDUMP=${sufs}/libs/ufslibs/install/netcdf/bin/ncdump
  reg_res=$( $NCDUMP -h ${GRID_OROG_DATA}/C*/C*_grid.tile7.nc | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]" )
  reg_res=${reg_res//$'\n'/}
  cp -r ${GRID_OROG_DATA}/C${reg_res}/* .
  rm -f  C${reg_res}_grid.tile7.halo0.nc
  rm -f  C${reg_res}_oro_data.tile7.halo${halo}.nc
  ln -sf C${reg_res}_mosaic.nc                      grid_spec.nc
  ln -sf C${reg_res}_grid.tile7.halo${halo}.nc      C${reg_res}_grid.tile7.nc
  ln -sf C${reg_res}_grid.tile7.halo${HALO}.nc      grid.tile7.halo${HALO}.nc
  ln -sf C${reg_res}_oro_data.tile7.halo0.nc        oro_data.nc
  ln -sf C${reg_res}_oro_data.tile7.halo${HALO}.nc  oro_data.tile7.halo${HALO}.nc

fi

#
# Copy input data (created by chgres_cube) to model run directory
#
export DATA=${MYDIR}/preproc_run

if [[ $gtype == uniform ]]; then
    cp ${DATA}/gfs_ctrl.nc       .
    cp ${DATA}/gfs_data.tile?.nc      .
    cp ${DATA}/sfc_data.tile?.nc      .
elif [[ $gtype == regional* ]]; then
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
  48)
    JCAP=92
    LONB=192
    LATB=94
    DT_ATMOS=1800
    ;;
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

cp ${FIX_DATA}/am/20220805/global_climaeropac_global.txt             aerosol.dat
cp ${FIX_DATA}/am/20220805/CFSR.SEAICE.1982.2012.monthly.clim.grb    .
cp ${FIX_DATA}/am/20220805/global_co2historicaldata_2013.txt         co2historicaldata_2013.txt
cp ${FIX_DATA}/am/20220805/RTGSST.1982.2012.monthly.clim.grb         .
cp ${FIX_DATA}/am/20220805/global_albedo4.1x1.grb                    .
cp ${FIX_DATA}/am/20220805/global_co2historicaldata_glob.txt         co2historicaldata_glob.txt
cp ${FIX_DATA}/am/20220805/co2monthlycyc.txt                         .
cp ${FIX_DATA}/am/20220805/global_glacier.2x2.grb                    .
cp ${FIX_DATA}/am/20220805/global_h2o_pltc.f77                       global_h2oprdlos.f77
cp ${FIX_DATA}/am/20220805/global_maxice.2x2.grb                     .
cp ${FIX_DATA}/am/20220805/ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77 global_o3prdlos.f77
cp ${FIX_DATA}/am/20220805/global_shdmax.0.144x0.144.grb             .
cp ${FIX_DATA}/am/20220805/global_shdmin.0.144x0.144.grb             .
cp ${FIX_DATA}/am/20220805/global_slope.1x1.grb                      .
cp ${FIX_DATA}/am/20220805/global_snoclim.1.875.grb                  .
cp ${FIX_DATA}/am/20220805/global_solarconstant_noaa_an.txt          solarconstant_noaa_an.txt
cp ${FIX_DATA}/am/20220805/global_tg3clim.2.6x1.5.grb                .
cp ${FIX_DATA}/am/20220805/global_vegfrac.0.144.decpercent.grb       .
cp ${FIX_DATA}/am/20220805/global_sfc_emissivity_idx.txt             sfc_emissivity_idx.txt

cp ${FIX_DATA}/am/20220805/${FNABSC}                                 .
cp ${FIX_DATA}/am/20220805/global_slmask.t1534.3072.1536.grb         seaice_newland.grb
cp ${FIX_DATA}/am/20220805/${FNALBC}                                 .
cp ${FIX_DATA}/am/20220805/${FNSMCC}                                 .
cp ${FIX_DATA}/am/20220805/${FNSOTC}                                 .
cp ${FIX_DATA}/am/20220805/${FNVETC}                                 .

if [[ $gtype == uniform ]]; then
   cp ${MYDIR}/global_conf/* .
elif [[ $gtype == regional* ]]; then
   cp ${MYDIR}/regional_conf/* .
fi

eparse model_configure.in > model_configure
eparse input.nml.in > input.nml
eparse diag_table.in > diag_table

export OMP_NUM_THREADS=1

#
# Finally we have all necessary input data.
# Let's run the model, that's why we are here.
#
${MPIEXEC} -n ${NTASKS} ${sufs}/bin/ufs_model 1> stdout 2> stderr

echo "Done!"
