#!/bin/bash
set -eux

if [[ $(uname -s) == Linux ]]; then
ulimit -s unlimited
fi

source configuration.sh

MYDIR=$(pwd)

[[ -e ${sufs}/src/preproc/ush/fv3gfs_driver_grid.sh ]] || exit 1

(
  ln -sf ${FIX_DATA}/fix_am ${sufs}/src/preproc/fix/.
  ln -sf ${FIX_DATA}/fix_orog ${sufs}/src/preproc/fix/.
  ln -sf ${FIX_DATA}/fix_sfc_climo ${sufs}/src/preproc/fix/.
)

export machine=linux
export TEMP_DIR=${MYDIR}/tmp_grid_orog_$$
export out_dir=${GRID_OROG_DATA}/C${res}
export home_dir=${sufs}/src/preproc
export exec_dir=${sufs}/bin
export halo=3
export APRUN=''
export APRUN_SFC='mpiexec -n 6'
export OMP_NUM_THREADS=1
export NCDUMP=${sufs}/libs/3rdparty/local/bin/ncdump

rm -rf ${out_dir}
${sufs}/src/preproc/ush/fv3gfs_driver_grid.sh

if [[ $gtype == regional* ]]; then
  HALO=$(( halo + 1 ))
  reg_res=424
  cd ${out_dir}/C${reg_res}

  ln -sf C${reg_res}_grid.tile7.halo${HALO}.nc C${reg_res}_grid.tile7.nc

  cd fix_sfc
  for file in *.halo${HALO}.nc; do
    if [[ -f $file ]]; then
      file2=${file%.halo${HALO}.nc}
      ln -sf ${file} ${file2}.nc
    fi
  done
fi

rm -rf ${TEMP_DIR}

echo "Done!"
