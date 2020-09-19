#!/bin/bash
set -eux

./run_grid_orog.sh

./run_preproc.sh

./run_model.sh

./run_post.sh
