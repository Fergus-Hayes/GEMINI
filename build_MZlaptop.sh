#!/bin/bash
#
# "-d" option makes this a Debug build
# "-t" option makes this a Trace build (dump certain variables to disk)
#
# This is for Matt's Mac OS laptop which has all libraries installed via macports


MPIPREFIX=
LAPACKPREFIX=
SCALAPACKPREFIX=
MUMPSPREFIX=

OPTS=

. script_utils/check.sh

. script_utils/build.sh
