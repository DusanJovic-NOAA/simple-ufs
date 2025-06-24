#!/bin/bash
set -eu

MYDIR=$(dirname "$(realpath "$0")")
readonly MYDIR

(
    cd "${MYDIR}"/src
    ./get.sh
)

(
    cd "${MYDIR}"/libs
    ./fetch.sh
)
