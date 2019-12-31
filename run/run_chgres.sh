#!/bin/bash
set -eux

ulimit -s unlimited

source configuration.sh

MYDIR=$(pwd)

export DATA=${MYDIR}/tmp_chgres_$$
rm -rf ${DATA}

export OMP_NUM_THREADS_CH=1
export CDATE=${START_YEAR}${START_MONTH}${START_DAY}${START_HOUR}
export HOMEgfs=${sufs}/src/preproc
export FIXfv3=${GRID_OROG_DATA}
export CDUMP=gfs
export CASE=C${res}
export INIDIR=${INPUT_DATA}
export LANDICE_OPT=2
export OUTDIR=${MYDIR}/chgres
rm -rf ${OUTDIR}

if [[ $gtype == "uniform" ]]; then

    export REGIONAL=0
    ${sufs}/src/preproc/ush/global_chgres_driver.sh

elif [[ $gtype == "regional" ]]; then

    export REGIONAL=1
    export HALO=4
    export nst_anl='.false.'
    ${sufs}/src/preproc/ush/global_chgres_driver.sh

    for FHR in $(seq -s ' ' -f %03g $BC_INT $BC_INT $NHOURS_FCST); do
        export REGIONAL=2
        export bchour=${FHR}
        ${sufs}/src/preproc/ush/global_chgres_driver.sh
    done

fi

rm -rf ${DATA}

echo "Done!"
