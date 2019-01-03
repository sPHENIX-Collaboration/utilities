#! tcsh -f

if ($#argv != 2) then
	
	echo "Usage $0 number_event run_valgrind"
	exit 1;
	
endif

set number_event = $1;
set run_valgrind = $2;



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


set valgrind_prefix = "";

if ($run_valgrind > 0) then
	
	set valgrind_sup = '';

	if (-e $ROOTSYS/root.supp) then
	    set valgrind_sup = "--suppressions=$ROOTSYS/root.supp";
	endif	
	
	set valgrind_prefix = "valgrind -v --num-callers=30 --leak-check=full --error-limit=no --log-file=Fun4All_G4_sPHENIX.valgrind $valgrind_sup --leak-resolution=high"
	
	which valgrind
	echo "valgrind_prefix = ${valgrind_prefix}"
	
endif

echo "======================================================="
echo "Start test";
echo "======================================================="


/usr/bin/time -v ${valgrind_prefix} root.exe -b -q "Fun4All_G4_sPHENIX.C(${number_event})" | & tee -a Fun4All_G4_sPHENIX.log;

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




