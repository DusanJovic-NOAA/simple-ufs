
export sufs=$( cd $(pwd)/.. ; pwd -P )

export res=${res:-96}
export levp=${levp:-65}   # 28, 42 or 65

export gtype=uniform
# export gtype=regional_gfdl

export START_YEAR=${START_YEAR:-$(date --date="1 day ago" --utc +%Y)}
export START_MONTH=${START_MONTH:-$(date --date="1 day ago" --utc +%m)}
export START_DAY=${START_DAY:-$(date --date="1 day ago" --utc +%d)}
export START_HOUR=${START_HOUR:-00}

export NHOURS_FCST=24
export BC_INT=3

export NFHOUT=3
export NFHMAX_HF=12
export NFHOUT_HF=1

export FIX_DATA=$(pwd)/fix_data
export INPUT_DATA=$(pwd)/input_data
export GRID_OROG_DATA=$(pwd)/grid_orog

export INPUT_TYPE=grib2

if [[ $gtype == uniform ]]; then
  export LAYOUT_1=1
  export LAYOUT_2=1
  export WRITE_GROUPS=1
  export WRITE_TASKS_PER_GROUP=2
  export NTASKS=$(( 6*LAYOUT_1*LAYOUT_2 + WRITE_GROUPS*WRITE_TASKS_PER_GROUP ))
elif [[ $gtype == regional* ]]; then
  export target_lon=15
  export target_lat=45
  export LAYOUT_1=6
  export LAYOUT_2=6
  export WRITE_GROUPS=1
  export WRITE_TASKS_PER_GROUP=4
  export NTASKS=$(( LAYOUT_1*LAYOUT_2 + WRITE_GROUPS*WRITE_TASKS_PER_GROUP ))
fi

export MPIEXEC=mpiexec
# export MPIEXEC=srun

eparse() { ( set -eu; set +x; eval "set -eu; cat<<_EOF"$'\n'"$(< "$1")"$'\n'"_EOF"; ) }
