#!/bin/tcsh -f

echo "source /opt/sphenix/core/bin/sphenix_setup.csh -n $*"
source /opt/sphenix/core/bin/sphenix_setup.csh -n $*; 

env;

if (! -d ./test ) then
	mkdir test
endif

cd test

echo '{int ret = gSystem->Load("libg4detectors"); cout <<"Load libg4detectors = "<<ret<<endl;assert(ret == 0);exit(0);}' > test.C

root -b -q test.C

set build_ret = $?;

if ($build_ret != 0) then
	echo "======================================================="
	echo "Failed build with return = ${build_ret}.";
	echo "======================================================="
	exit $build_ret;
endif

echo "Build step - singularity test - done"
