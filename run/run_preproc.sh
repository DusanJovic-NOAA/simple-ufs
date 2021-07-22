#!/bin/bash
set -eux

if [[ $(uname -s) == Linux ]]; then
ulimit -s unlimited
fi

source configuration.sh

MYDIR=$(pwd)

export DATA=${MYDIR}/preproc_run
rm -rf ${DATA}
mkdir ${DATA}
cd ${DATA}

export APRUN="${MPIEXEC} -n 6"
export OMP_NUM_THREADS_CH=1
export CDATE=${START_YEAR}${START_MONTH}${START_DAY}${START_HOUR}
export HOMEufs=${sufs}/src/preproc
export EXECufs=${sufs}/bin
export FIXam=${MYDIR}/fix_data/fix_am
export CRES=${res}

export COMIN=${INPUT_DATA}

if [[ $gtype == 'uniform' ]]; then

    export FIXfv3=${GRID_OROG_DATA}/C${res}

    export REGIONAL=0

    if [[ $INPUT_TYPE == 'nemsio' ]]; then

      #export ATM_FILES_INPUT=gfs.t00z.atmanl.nemsio
      #export SFC_FILES_INPUT=gfs.t00z.sfcanl.nemsio
      :

    elif [[ $INPUT_TYPE == 'grib2' ]]; then

      export GRIB2_FILE_INPUT=gfs.t00z.pgrb2.0p50.f000
      export VARMAP_FILE=GFSphys_var_map.txt
      export CONVERT_NST=.false.

      cp ${MYDIR}/global_conf/GFSphys_var_map.txt .

    elif [[ $INPUT_TYPE == 'gaussian_netcdf' ]]; then

      export ATM_FILES_INPUT=gfs.t00z.atmf000.nc
      export SFC_FILES_INPUT=gfs.t00z.sfcanl.nc
      export VARMAP_FILE=GFSphys_var_map.txt
      export CONVERT_NST=.true.

      cp ${MYDIR}/global_conf/GFSphys_var_map.txt .

    else

      echo "Unknown INPUT_TYPE ${INPUT_TYPE}"
      exit 1

    fi

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

elif [[ $gtype == regional* ]]; then

    reg_res=424
    export FIXfv3=${GRID_OROG_DATA}/C${reg_res}
    export CRES=${reg_res}
    export OROG_FILES_TARGET_GRID=C${reg_res}_oro_data.tile7.halo4.nc
    export GRIB2_FILE_INPUT=gfs.t00z.pgrb2.0p50.f000
    export VARMAP_FILE=GFSphys_var_map.txt
    export CONVERT_NST=.false.
    export REGIONAL=1
    export HALO_BNDY=4

    cp ${MYDIR}/regional_conf/GFSphys_var_map.txt .

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

echo 'Done!'
