#!/bin/bash

# Define a function that attempts to locate a
# plugin with a given canonical name.
# Assumptions:
#   1. plugins is a top-level directory, possibly in "build"
# Inputs:
#   $1 is the canonical name
#   $2 is 1 if we are running under cmake
#   $3 is 1 if we are running using Visual Studio, blank otherwise
#   $4 is the build type; only used if $3 is 1
# Outputs:
#   return code is 0 is success, 1 if failed
#   Variable HDF5_PLUGIN_LIB is set to the library file name
#   Variable HDF5_PLUGIN_DIR is set to the absolute path to the
#                    directory containing the plugin library file
# Local variables are prefixed with FP_
#
# Note: we assume that the use of the CMAKE_BUILD_TYPE
# is obviated by setting the LIBRARY_OUTPUT_DIRECTORY
# variables: see hdf5plugins/CMakeLists.txt

# Define location of execution
TOPSRCDIR='N:/Development/Dev_Base/netcdf-c-4.9.2'
TOPBUILDDIR='N:/Development/Dev_Base/netcdf-c-4.9.2/msvc'

# Need info from test_common
if test "x$srcdir" = x ; then srcdir=`pwd`; fi
. ${TOPBUILDDIR}/test_common.sh

findpluginext() {
  # Infer the expected plugin shared library extension
  # Note: will fail if used before plugins is built
  # Also assumes that misc filter is always built
  # Approach is to use find to see what is in plugins directory.
  TSO=`find ${TOPBUILDDIR}/plugins -name '*misc.so'`
  TDY=`find ${TOPBUILDDIR}/plugins -name '*misc.dylib'`
  TCYG=`find ${TOPBUILDDIR}/plugins -name 'cyg*misc.dll'`
  TMING=`find ${TOPBUILDDIR}/plugins -name lib*misc.dll`
  TDLL=`find ${TOPBUILDDIR}/plugins -name '*misc.dll'`
  if test "x$TSO" != x ; then
    FP_PLUGIN_EXT="so"
    FP_PLUGIN_PRE="lib__nc"  
  elif test "x$TDY" != x ; then
    FP_PLUGIN_EXT="dylib"
    FP_PLUGIN_PRE="lib__nc"  
  elif test "x$TCYG" != x ; then
    FP_PLUGIN_EXT="dll"
    FP_PLUGIN_PRE="cyg__nc"
  elif test "x$TMING" != x ; then
    FP_PLUGIN_EXT="dll"
    FP_PLUGIN_PRE="lib__nc"
  elif test "x$TDLL" != x ; then
    FP_PLUGIN_EXT="dll"
    FP_PLUGIN_PRE="__nc"  
  else # unknown
    unset FP_PLUGIN_EXT
    unset FP_PLUGIN_PRE
  fi
}
  
findplugindir() {
FP_PLUGIN_DIR=
# Figure out the path to where the lib is stored
# This can probably be simplified

CURWD=`pwd`
cd ${TOPBUILDDIR}/plugins
FP_PLUGINS=`pwd`
cd ${CURWD}

# Case 1: Cmake with Visual Studio
if test "x$FP_ISCMAKE" != x -a "x${FP_ISMSVC}" != x ; then
    # Case 1a: ignore the build type directory
    if test -e "${FP_PLUGINS}/${FP_PLUGIN_LIB}" ; then
      FP_PLUGIN_DIR="${FP_PLUGINS}"
    fi
else # Case 2: automake
  # Case 2a: look in .libs
  if test -e "${FP_PLUGINS}/.libs" ; then
    FP_PLUGIN_DIR="${FP_PLUGINS}/.libs"
  else # Case 2: look in FP_PLUGINS directly
    if test -e "${FP_PLUGINS}" ; then
      FP_PLUGIN_DIR="${FP_PLUGINS}"
    fi
  fi
fi

# Verify
if test "x$FP_PLUGIN_DIR" = x ; then
  echo "***Fail: Could not locate a usable HDF5_PLUGIN_DIR"
  return 1
fi

# Make local path
FP_PLUGIN_DIR=`${NCPATHCVT} -F $FP_PLUGIN_DIR`
HDF5_PLUGIN_DIR="$FP_PLUGIN_DIR"
}

findplugin() {    

FP_NAME="$1"

FP_PLUGIN_LIB=

# Figure out the plugin file name
FP_PLUGIN_LIB="${FP_PLUGIN_PRE}${FP_NAME}.${FP_PLUGIN_EXT}"

# Verify
if ! test -f "$FP_PLUGIN_DIR/$FP_PLUGIN_LIB" ; then
  echo "***Fail: Could not locate a usable HDF5_PLUGIN_LIB"
  return 1
fi

# Set the final output variables
HDF5_PLUGIN_LIB="$FP_PLUGIN_LIB"
HDF5_PLUGIN_DIR="$FP_PLUGIN_DIR"

return 0
}

# init
unset HDF5_PLUGIN_DIR
findpluginext
findplugindir
