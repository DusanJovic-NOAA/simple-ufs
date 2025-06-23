#!/bin/bash
[[ -e /etc/bashrc ]] && source /etc/bashrc

set -eu

MYDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
readonly MYDIR

cd "${MYDIR}"

./get.sh

./build.sh gnu -all

cd run

sed -i -e 's/NHOURS_FCST=24/NHOURS_FCST=3/g' configuration.sh
sed -i -e 's/NFHMAX_HF=12/NFHMAX_HF=3/g' configuration.sh

./fetch_fix_data.sh
./fetch_input_data.sh
./run.sh

ls -l preproc_run
ls -l model_run
ls -l post_run
