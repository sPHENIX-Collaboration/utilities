#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then	
	echo "Usage $0  sPHENIX number_event run_valgrind"
	exit 1;
fi
if [ -z "${system_config}" ]; then
	echo "Fatal error: Miss env system_config"
	exit 1;
fi
if [ -z "$build_type" ]; then	
	echo "Fatal error: Miss env build_type"
	exit 1;
fi

detector_name=$1;
number_event=$2;
run_valgrind=$3;

macro_name="Fun4All_G4_${detector_name}";

export OFFLINE_MAIN=$WORKSPACE/install
# export CALIBRATIONROOT=$WORKSPACE/calibrations # handle via OFFLINE_MAIN
# note this is not using -n parameter to overwrite OFFLINE_MAIN
echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;

export ROOT_INCLUDE_PATH=${WORKSPACE}/macros/common:${ROOT_INCLUDE_PATH}

echo "======================================================="
echo "env check";
echo "======================================================="

env;

echo "======================================================="
echo "cd macros/detectors/${detector_name}";
echo "======================================================="
cd macros/detectors/${detector_name}

pwd;
ls -lhc


valgrind_prefix="";

if (( $run_valgrind > 0 )); then
	
	valgrind_sup='';

	if [ -f $ROOTSYS/root.supp ]; then
	    valgrind_sup="--suppressions=$ROOTSYS/root.supp";
		echo 'use valgrind suppression file:'
		ls -lhv $ROOTSYS/root.supp
	fi	
	
	# set valgrind_prefix = "valgrind -v  --num-callers=30 --leak-check=full --error-limit=no --log-file=${macro_name}.valgrind $valgrind_sup --xml=yes --xml-file=${macro_name}.valgrind.xml --leak-resolution=high"
	# set valgrind_prefix = "valgrind -v  --num-callers=30 --leak-check=full --error-limit=no --log-file=${macro_name}.valgrind $valgrind_sup  --leak-resolution=high"
	# set valgrind_prefix = "valgrind -v --gen-suppressions=all  --num-callers=30 --leak-check=full --error-limit=no --log-file=${macro_name}.valgrind $valgrind_sup  --leak-resolution=high"
	valgrind_prefix="valgrind -v --num-callers=30 --gen-suppressions=all --leak-check=full --error-limit=no --log-file=${macro_name}.valgrind $valgrind_sup --xml=yes --xml-file=${macro_name}.valgrind.xml --leak-resolution=high"
	
	which valgrind
	echo "valgrind_prefix = ${valgrind_prefix}"
	
fi

echo "======================================================="
echo "Start test";
echo "======================================================="

# Test case to produce memory error
# echo '{int ret = gSystem->Load("libg4bbc.so"); cout <<"Load libg4detectors = "<<ret<<endl;assert(ret == 0);BbcVertexFastSimReco* bbcvertex = new BbcVertexFastSimReco();BbcVertexFastSimReco* bbcvertex = new BbcVertexFastSimReco();int a[2] = {0}; a[3] = 1;exit(0);}' > test.C

( /usr/bin/time -v  timeout --preserve-status --kill-after=1s --signal=9 1d  ${valgrind_prefix} root.exe -b -q "${macro_name}.C(${number_event})" ; echo $? > return.tmp ) 2>&1 | tee ${macro_name}.log;

build_ret=`cat return.tmp`;

ls -lhcrt

echo "Build step - build - return $build_ret";

if (( $build_ret != 0 )); then
	echo "======================================================="
	echo "Failed run with return = ${build_ret}. ";
	echo "======================================================="
	
	if (( $run_valgrind == 0 )); then
		exit $build_ret;
	fi
fi



# readback test, only in non-valgrind mode
# if ($run_valgrind == 0) then
#
#	# set DSTfile = `/bin/ls -1 G4*.root`;
#	set DSTfile = `/bin/ls -1 G4*.root | head -n 1` ;
#	
#	echo "======================================================="
#	echo "Readback DST file ${DSTfile}. ";
#	echo "======================================================="
#	
#	set quote = '"';
#	/usr/bin/time -v  root.exe -b -q "Fun4All_ReadBack.C(0, ${quote}${DSTfile}${quote})" | & tee -a Fun4All_ReadBack.log;
#	set build_ret = $?;
#	
#	ls -lhcrt
#
#	echo "Readback step - build - return $build_ret";
#	
#	if ($build_ret != 0) then
#		
#		echo "======================================================="
#		echo "Readback run with return = ${build_ret}. ";
#		echo "======================================================="
#		exit $build_ret;
#		
#	endif
#endif

echo "Build step - test - done";



