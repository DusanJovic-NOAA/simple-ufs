
sufs=$( cd $(pwd)/.. ; pwd -P )

res=${res:-96}
ocn=${ocn:-100}
levp=${levp:-65}   # 28, 42 or 65

gtype=uniform
# gtype=regional_gfdl
# gtype=regional_esg

START_YEAR=${START_YEAR:-$(date --date="1 day ago" --utc +%Y)}
START_MONTH=${START_MONTH:-$(date --date="1 day ago" --utc +%m)}
START_DAY=${START_DAY:-$(date --date="1 day ago" --utc +%d)}
START_HOUR=${START_HOUR:-00}

NHOURS_FCST=24
BC_INT=3

NFHOUT=3
NFHMAX_HF=12
NFHOUT_HF=1

FIX_DATA=$(pwd)/fix_data
INPUT_DATA=$(pwd)/input_data
GRID_OROG_DATA=$(pwd)/grid_orog

INPUT_TYPE=grib2

if [[ $gtype == uniform ]]; then
  LAYOUT_1=1
  LAYOUT_2=1
  WRITE_GROUPS=1
  WRITE_TASKS_PER_GROUP=2
  NTASKS=$(( 6*LAYOUT_1*LAYOUT_2 + WRITE_GROUPS*WRITE_TASKS_PER_GROUP ))
elif [[ $gtype == regional* ]]; then
  target_lon=15 # Europe
  target_lat=45 # Europe
  # target_lon=135 # Australia
  # target_lat=-25 # Australia
  idim=210 # for esg
  jdim=192 # for esg
  delx=0.1 # for esg
  dely=0.1 # for esg
  LAYOUT_1=6
  LAYOUT_2=6
  WRITE_GROUPS=1
  WRITE_TASKS_PER_GROUP=4
  NTASKS=$(( LAYOUT_1*LAYOUT_2 + WRITE_GROUPS*WRITE_TASKS_PER_GROUP ))
fi

MPI_IMPLEMENTATION=${MPI_IMPLEMENTATION:-mpich}
mpiexec --version | grep OpenRTE 2> /dev/null && MPI_IMPLEMENTATION=openmpi
mpiexec --version | grep "Open MPI" 2> /dev/null && MPI_IMPLEMENTATION=openmpi
mpiexec --version | grep Intel 2> /dev/null && MPI_IMPLEMENTATION=intelmpi

if [[ $MPI_IMPLEMENTATION == openmpi ]]; then
  # Get rid of Read -1, expected <someNumber>, errno =1 error
  # See https://github.com/open-mpi/ompi/issues/4948
  export OMPI_MCA_btl_vader_single_copy_mechanism=none
  MPIEXEC='mpiexec --oversubscribe'
else
  MPIEXEC='mpiexec'
fi
# MPIEXEC=srun

eparse() { ( set -eu; set +x; eval "set -eu; cat<<_EOF"$'\n'"$(< "$1")"$'\n'"_EOF"; ) }
