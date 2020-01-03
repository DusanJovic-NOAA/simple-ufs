#!/bin/bash
set -eu

#
# clone from NOAA-EMC
#

ALL_LIBS="
NCEPLIBS-bacio
NCEPLIBS-g2
NCEPLIBS-g2tmpl
NCEPLIBS-gfsio
NCEPLIBS-ip
NCEPLIBS-landsfcutil
NCEPLIBS-nemsio
NCEPLIBS-nemsiogfs
NCEPLIBS-sfcio
NCEPLIBS-sigio
NCEPLIBS-sp
NCEPLIBS-w3emc
NCEPLIBS-w3nco
EMC_crtm
"

for libname in ${ALL_LIBS}; do
(
  rm -rf ${libname}

  git clone --recursive https://github.com/NOAA-EMC/${libname}
  cd ${libname}

  git checkout ufs_release_v1.0
  git submodule sync
  git submodule update --init
  git status
  git diff
)
done
