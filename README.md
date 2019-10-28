# Welcome to the Simple UFS Weather App

Let's start with a disclaimer.

## Disclaimer

This is unofficial, unsupported, untested and undocumented UFS Weather App.
For official, supported, tested and documented UFS Weather App look elsewhere.
For example [here](https://github.com/ufs-community/ufs-mrweather-app).

By cloning, forking or downloading anything from this repository I assume you know what you are doing.

## What is in this repository

The purpose of this repository is to store my personal scripts I use to build UFS 
Weather model in a simple and portable way. Emphasis is on providing faily simple
building of all dependencies and model itself on a workstation type of computer
(desktop/laptop) using GNU compilers.

That's all. 

## Quick start

Run:

```shell
./get.sh
```

to download preprocessor, model, post processor and all dependencies.

Run:

```shell
./build.sh <gnu|intel>
```

to build (almost) everything.

This build script expects compilers (C, C++ and Fortran) and MPI library to be
installed and available. Some basic development tools are also required,
like standard unix tools, git, gmake, cmake, python2.7, perl. Either install
required packages using you distribution package manger (yum/dnf, apt, apk, etc.),
or load appropriate modules (if you are on a system that uses
[environment modules](https://modules.readthedocs.io)).

There's also an option to build MPI library [[MPICH](https://www.mpich.org/)(v3.3.1)
and [OpenMPI](https://www.open-mpi.org/)(v4.0.2)] locally, run
`libs/mpilibs/build.sh` script, and update your `PATH` to point to locally
built library (for example `libs/mpilibs/local/mpich3/bin`).
