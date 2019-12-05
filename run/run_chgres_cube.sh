#!/bin/bash
set -eux

ulimit -s unlimited

source configuration.sh

MYDIR=$(pwd)

export DATA=${MYDIR}/chgres
rm -rf ${DATA}

export APRUN='mpiexec -np 6'
export OMP_NUM_THREADS_CH=1
export CDATE=${START_YEAR}${START_MONTH}${START_DAY}${START_HOUR}
export HOMEufs=${sufs}/src/preproc
export EXECufs=${sufs}/bin
export FIXfv3=${MYDIR}/grid_orog/C${res}

export COMIN=${INPUT_DATA}
export ATM_FILES_INPUT=gfs.t00z.atmanl.nemsio
export SFC_FILES_INPUT=gfs.t00z.sfcanl.nemsio

if [[ $gtype == "uniform" ]]; then

    export REGIONAL=0

    ${sufs}/src/preproc/ush/chgres_cube.sh

    mv ${DATA}/out.atm.tile1.nc  ${DATA}/gfs_data.tile1.nc
    mv ${DATA}/out.atm.tile2.nc  ${DATA}/gfs_data.tile2.nc
    mv ${DATA}/out.atm.tile3.nc  ${DATA}/gfs_data.tile3.nc
    mv ${DATA}/out.atm.tile4.nc  ${DATA}/gfs_data.tile4.nc
    mv ${DATA}/out.atm.tile5.nc  ${DATA}/gfs_data.tile5.nc
    mv ${DATA}/out.atm.tile6.nc  ${DATA}/gfs_data.tile6.nc

    mv ${DATA}/out.sfc.tile1.nc  ${DATA}/sfc_data.tile1.nc
    mv ${DATA}/out.sfc.tile2.nc  ${DATA}/sfc_data.tile2.nc
    mv ${DATA}/out.sfc.tile3.nc  ${DATA}/sfc_data.tile3.nc
    mv ${DATA}/out.sfc.tile4.nc  ${DATA}/sfc_data.tile4.nc
    mv ${DATA}/out.sfc.tile5.nc  ${DATA}/sfc_data.tile5.nc
    mv ${DATA}/out.sfc.tile6.nc  ${DATA}/sfc_data.tile6.nc

elif [[ $gtype == "regional" ]]; then

    export REGIONAL=1
    export OROG_FILES_TARGET_GRID=C${res}_oro_data.tile7.halo4.nc
    export HALO_BNDY=4

    ${sufs}/src/preproc/ush/chgres_cube.sh
    mv ${DATA}/out.atm.tile1.nc ${DATA}/gfs_data.tile7.nc
    mv ${DATA}/out.sfc.tile1.nc ${DATA}/sfc_data.tile7.nc
    mv ${DATA}/gfs.bndy.nc      ${DATA}/gfs_bndy.tile7.000.nc

    for FHR in $(seq -s ' ' -f %03g $BC_INT $BC_INT $NHOURS_FCST); do
        export REGIONAL=2
        export ATM_FILES_INPUT=gfs.t00z.atmf${FHR}.nemsio
        export CONVERT_SFC=.false.
        export CONVERT_NST=.false.
        ${sufs}/src/preproc/ush/chgres_cube.sh
        mv ${DATA}/gfs.bndy.nc ${DATA}/gfs_bndy.tile7.${FHR}.nc
    done

fi

rm -f ${DATA}/fort.41
rm -f ${DATA}/PET*
