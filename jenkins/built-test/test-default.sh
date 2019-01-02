#! tcsh -f

# source /opt/sphenix/core/bin/sphenix_setup.csh -n; 

# setenv workRootPath `pwd`;
# setenv PATH 		$WORKSPACE/install/bin:${PATH}
# setenv LD_LIBRARY_PATH 	$WORKSPACE/install/lib:${LD_LIBRARY_PATH}
# setenv CALIBRATIONROOT  $WORKSPACE/calibrations/

setenv OFFLINE_MAIN $WORKSPACE/install
setenv ONLINE_MAIN $WORKSPACE/install
setenv CALIBRATIONROOT  $WORKSPACE/calibrations

source /opt/sphenix/core/bin/sphenix_setup.csh;


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

/usr/bin/time -v root -b -q root -b -q 'Fun4All_G4_sPHENIX.C(20)' | & tee -a Fun4All_G4_sPHENIX.log;

set build_ret = $?;

ls -lhcrt

echo "Build step - build - return $build_ret";

ls -lhcrt

if ($build_ret != 0) then
	echo "======================================================="
	echo "Failed build with return = ${build_ret}. ";
	echo "======================================================="
	exit $build_ret;
endif

echo "Build step - test - done";




