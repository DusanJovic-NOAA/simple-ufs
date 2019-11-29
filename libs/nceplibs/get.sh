#!/bin/bash
set -eu

#
# clone from NOAA-EMC/NCEPLIBS-
#
for libname in ip landsfcutil sfcio w3emc w3nco; do
(
  rm -rf NCEPLIBS-${libname}

  git clone https://github.com/NOAA-EMC/NCEPLIBS-${libname}
  cd NCEPLIBS-${libname}

  git checkout spack-build
  git submodule sync
  git submodule update --init
  git status
  git diff
)
done

#
# clone from NOAA-EMC/EMC_
#
for libname in crtm; do
(
  rm -rf EMC_${libname}

  git clone https://github.com/NOAA-EMC/EMC_${libname}
  cd EMC_${libname}

  git checkout spack-build
  git submodule sync
  git submodule update --init
  git status
  git diff
)
done

#
# clone from DusanJovic-NOAA
#
for libname in bacio gfsio g2 g2tmpl nemsio nemsiogfs sigio sp; do
(
  rm -rf NCEPLIBS-${libname}

  git clone --recursive https://github.com/DusanJovic-NOAA/NCEPLIBS-${libname}
  cd NCEPLIBS-${libname}

  git checkout spack-build
  git submodule sync
  git submodule update --init
  git status
  git diff
)
done
