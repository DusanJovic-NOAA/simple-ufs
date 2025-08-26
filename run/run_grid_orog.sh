#!/bin/bash
set -eux

if [[ $(uname -s) == Linux ]]; then
ulimit -s unlimited
fi

source configuration.sh

MYDIR=$(pwd)

rm -rf ${GRID_OROG_DATA}
mkdir -p ${GRID_OROG_DATA}

export gtype
export res
export target_lon target_lat pazi idim jdim delx dely

if [[ $gtype == uniform ]]; then # use pregenerated grid/orog files

  rm -rf ${GRID_OROG_DATA}/C${res}
  ln -sf ${FIX_DATA}/orog/20231027/C${res} ${GRID_OROG_DATA}/C${res}

else # run fv3gfs_driver_grid.sh

  [[ -e ${sufs}/src/preproc/ush/fv3gfs_driver_grid.sh ]] || exit 1

  rm -f ${sufs}/src/preproc/fix/am
  rm -f ${sufs}/src/preproc/fix/orog
  rm -f ${sufs}/src/preproc/fix/sfc_climo
  ln -sf ${FIX_DATA}/am/20220805         ${sufs}/src/preproc/fix/am
  ln -sf ${FIX_DATA}/sfc_climo/20230925  ${sufs}/src/preproc/fix/sfc_climo
  if [[ $gtype == regional* ]]; then
  ln -sf ${FIX_DATA}/orog/20240917       ${sufs}/src/preproc/fix/orog
  else
  ln -sf ${FIX_DATA}/orog/20250702       ${sufs}/src/preproc/fix/orog
  fi

  export machine=linux
  export TEMP_DIR=${MYDIR}/tmp_grid_orog_$$
  export out_dir=${GRID_OROG_DATA}
  export home_dir=${sufs}/src/preproc
  export exec_dir=${sufs}/bin
  export halo=3
  export APRUN=''
  export APRUN_SFC="${MPIEXEC} -n 6"
  export OMP_NUM_THREADS=1
  export NCDUMP=${sufs}/libs/install/netcdf/bin/ncdump

  ${sufs}/src/preproc/ush/fv3gfs_driver_grid.sh

  if [[ $gtype == regional* ]]; then
    HALO=$(( halo + 1 ))

    grid_dir=$TEMP_DIR/regional/grid
    reg_res=$( $NCDUMP -h ${grid_dir}/C*_grid.tile7.nc | grep -o ":RES_equiv = [0-9]\+" | grep -o "[0-9]" )
    reg_res=${reg_res//$'\n'/}
    cd ${out_dir}/C${reg_res}

    ln -sf C${reg_res}_grid.tile7.halo${HALO}.nc C${reg_res}_grid.tile7.nc

    cd sfc
    for file in *.halo"${HALO}".nc; do
      if [[ -f $file ]]; then
        file2=${file%.halo${HALO}.nc}
        ln -sf ${file} ${file2}.nc
      fi
    done
  fi

  rm -rf ${TEMP_DIR}

fi

echo "Done!"
