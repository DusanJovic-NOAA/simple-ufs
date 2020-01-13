
export sufs=$( cd $(pwd)/.. ; pwd -P )

export res=96
#export gtype=regional
export gtype=uniform

export START_YEAR=2020
export START_MONTH=01
export START_DAY=13
export START_HOUR=00

export NHOURS_FCST=24
export BC_INT=3

export NFHOUT=3
export NFHMAX_HF=12
export NFHOUT_HF=1

export FIX_DATA=$(pwd)/fix_data
export INPUT_DATA=$(pwd)/input_data
export GRID_OROG_DATA=$(pwd)/grid_orog

export INPUT_TYPE=grib2
