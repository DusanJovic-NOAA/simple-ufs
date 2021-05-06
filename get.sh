#!/bin/bash
set -eu

MYDIR=$(cd "$(dirname "$(readlink -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

cd ${MYDIR}/src

./get.sh
