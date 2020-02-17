#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then	
	echo "Usage $0  Fun4All_G4_sPHENIX number_event"
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


macro_name=$1;
number_event=$2;


# source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

# setenv workRootPath `pwd`;
# setenv PATH 		$WORKSPACE/install/bin:${PATH}
# setenv LD_LIBRARY_PATH 	$WORKSPACE/install/lib:${LD_LIBRARY_PATH}
# setenv CALIBRATIONROOT  $WORKSPACE/calibrations/

setenv OFFLINE_MAIN $WORKSPACE/install
echo source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;
source /cvmfs/sphenix.sdcc.bnl.gov/${system_config}/opt/sphenix/core/bin/sphenix_setup.sh $build_type;

echo "======================================================="
echo "env check";
echo "======================================================="

env;

cd macros/macros/g4simulations/

pwd;
ls -lhc

echo "======================================================="
echo "Start test";
echo "======================================================="

# Test case to produce memory error
# echo '{int ret = gSystem->Load("libg4bbc.so"); cout <<"Load libg4detectors = "<<ret<<endl;assert(ret == 0);BbcVertexFastSimReco* bbcvertex = new BbcVertexFastSimReco();BbcVertexFastSimReco* bbcvertex = new BbcVertexFastSimReco();int a[2] = {0}; a[3] = 1;exit(0);}' > test.C

/usr/bin/time -v root.exe -b -q "${macro_name}.C(${number_event})" | tee -a ${macro_name}.log;

build_ret=$?;

ls -lhcrt

echo "Build step - build - return $build_ret";

if (( $build_ret != 0 )) then
	echo "======================================================="
	echo "Failed run with return = ${build_ret}. ";
	echo "======================================================="
	
	# if ($run_valgrind == 0) then
		exit $build_ret;
	# endif
fi

echo "Build step - test - done";




