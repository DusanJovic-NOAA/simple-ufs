#!/bin/bash
set -eux

if [[ $(uname -s) == Linux ]]; then
ulimit -s unlimited
fi

source configuration.sh

MYDIR=$(pwd)

export DATA=${MYDIR}/chgres_run
rm -rf ${DATA}
mkdir ${DATA}
cd ${DATA}

export APRUN='mpiexec -n 6'
export OMP_NUM_THREADS_CH=1
export CDATE=${START_YEAR}${START_MONTH}${START_DAY}${START_HOUR}
export HOMEufs=${sufs}/src/preproc
export EXECufs=${sufs}/bin
export FIXam=${MYDIR}/fix_data/fix_am
export FIXfv3=${GRID_OROG_DATA}/C${res}/C424
export CRES=424

export COMIN=${INPUT_DATA}
#export ATM_FILES_INPUT=gfs.t00z.atmanl.nemsio
#export SFC_FILES_INPUT=gfs.t00z.sfcanl.nemsio

if [[ $gtype == "uniform" ]]; then

    export REGIONAL=0

    if [[ $INPUT_TYPE == "nemsio" ]]; then

      ${sufs}/src/preproc/ush/chgres_cube.sh

    elif [[ $INPUT_TYPE == "grib2" ]]; then

      cp ${MYDIR}/global_conf/GFSphys_var_map.txt .
      cp ${MYDIR}/global_conf/chgres_cube_grib2.nml.in fort.41
      sed -i -e "s:__RES__:${res}:g
                 s:__FIXam__:${FIXam}:g
                 s:__FIXfv3__:${FIXfv3}:g
                 s:__INPUT_DATA__:${INPUT_DATA}:g
                 s:__START_MONTH__:${START_MONTH}:g
                 s:__START_DAY__:${START_DAY}:g
                 s:__START_HOUR__:${START_HOUR}:g" fort.41

      ${APRUN} ${EXECufs}/chgres_cube

    else

      echo "Unknown INPUT_TYPE ${INPUT_TYPE}"
      exit 1

    fi

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

elif [[ $gtype == regional* ]]; then

    export REGIONAL=1
    reg_res=424
    export OROG_FILES_TARGET_GRID=C${reg_res}_oro_data.tile7.halo4.nc
    export GRIB2_FILE_INPUT=gfs.t00z.pgrb2.0p50.f000
    export VARMAP_FILE=GFSphys_var_map.txt
    export CONVERT_NST=.false.
    export HALO_BNDY=4

    cp ${MYDIR}/global_conf/GFSphys_var_map.txt .

    ${sufs}/src/preproc/ush/chgres_cube.sh
    mv ${DATA}/out.atm.tile1.nc ${DATA}/gfs_data.tile7.nc
    mv ${DATA}/out.sfc.tile1.nc ${DATA}/sfc_data.tile7.nc
    mv ${DATA}/gfs.bndy.nc      ${DATA}/gfs_bndy.tile7.000.nc

    for FHR in $(seq -s ' ' -f %03g $BC_INT $BC_INT $NHOURS_FCST); do
        export REGIONAL=2
        export ATM_FILES_INPUT=gfs.t00z.atmf${FHR}.nemsio
        export CONVERT_SFC=.false.
        ${sufs}/src/preproc/ush/chgres_cube.sh
        mv ${DATA}/gfs.bndy.nc ${DATA}/gfs_bndy.tile7.${FHR}.nc
    done

fi

rm -f ${DATA}/fort.41
rm -f ${DATA}/PET*

echo "Done!"
