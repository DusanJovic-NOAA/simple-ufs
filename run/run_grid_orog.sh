#!/bin/bash
set -eux

ulimit -s unlimited

source configuration.sh

MYDIR=$(pwd)

[[ -e ${sufs}/src/preproc/ush/fv3gfs_driver_grid.sh ]] || exit 1

(
  ln -sf ${FIX_DATA}/fix_am ${sufs}/src/preproc/fix/.
  ln -sf ${FIX_DATA}/fix_orog ${sufs}/src/preproc/fix/.
  ln -sf ${FIX_DATA}/fix_sfc_climo ${sufs}/src/preproc/fix/.
)

export machine=linux
export TMPDIR=${MYDIR}/tmp_grid_orog_$$
export out_dir=${GRID_OROG_DATA}/C${res}
export home_dir=${sufs}/src/preproc
export halo=3
export APRUN=''
export APRUN_SFC='mpiexec -np 6'

rm -rf ${out_dir}
${sufs}/src/preproc/ush/fv3gfs_driver_grid.sh

if [[ $gtype == "regional" ]]; then
  HALO=$(( halo + 1 ))
  cd ${out_dir}
  ln -sf C${res}_grid.tile7.halo${HALO}.nc C${res}_grid.tile7.nc

  cd ${out_dir}/fix_sfc
  for file in *.halo${HALO}.nc; do
    if [[ -f $file ]]; then
      file2=${file%.halo${HALO}.nc}
      ln -sf ${file} ${file2}.nc
    fi
  done
fi

rm -rf ${TMPDIR}

echo "Done!"
