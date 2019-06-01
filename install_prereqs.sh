#!/bin/bash
# installs libraries
# For CentOS HPC systems, consider centos*.sh scripts that use "modules" or "extensions"

set -e

case $OSTYPE in
linux*)

  if [[ -f /etc/redhat-release ]]; then
     echo "This script is made for personal laptops/desktops. HPCs using CentOS have system-specific library setup."
     echo "If using gfortran, version >= 6 is required. Try devtoolset-7 if gcc/gfortran is too old on your system."
     yum install epel-release
     yum install pkg-config gcc-gfortran g++ make
     yum install MUMPS-openmpi-devel lapack-devel scalapack-openmpi-devel openmpi-devel
     yum install octave
  else
    apt update
    apt install gfortran make
    apt install libmumps-dev liblapack-dev libscalapack-mpi-dev libopenmpi-dev openmpi-bin
    apt install --no-install-recommends octave
  fi
  ;;
darwin*)
  brew install cmake gcc make lapack scalapack openmpi octave
# MUMPS
  brew tap dpo/openblas;
  brew install mumps;
  ;;
cygwin*)
  echo "please install prereqs via Cygwin setup.exe"
  echo "gcc-fortran make liblapack-devel libopenmpi-devel octave"
  echo "then use ./compile_prereqs.sh to get all other prereqs"
  ;;
esac

