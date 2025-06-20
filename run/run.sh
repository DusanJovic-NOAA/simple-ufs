#!/bin/bash
set -eux

MYDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
readonly MYDIR

cd "${MYDIR}"

./run_grid_orog.sh

./run_preproc.sh

./run_model.sh

./run_post.sh
